import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import 'laser_mark_callout.dart';
import '../operators/operators_provider.dart';
import '../products/products_provider.dart';
import '../serial/itf_check_digit.dart';
import '../serial/manual_serial_service.dart';
import '../mqtt/mqtt_providers.dart';

/// Diálogo para gerar serial e enfileirar gravação laser (serial + modelo).
Future<void> showManualSerialDialog(
  BuildContext context,
  WidgetRef ref, {
  String? initialNumeroOp,
  String? initialIdProduto,
}) async {
  final products = ref.read(productsProvider);
  if (products.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastre um produto antes de gerar serial')),
    );
    return;
  }

  Product? selected;
  if (initialIdProduto != null) {
    for (final p in products) {
      if (p.idProduto == initialIdProduto) {
        selected = p;
        break;
      }
    }
  }
  selected ??= products.first;

  final opController = TextEditingController(text: initialNumeroOp ?? 'MANUAL');
  final serialBodyController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  var previewSeq = 0;
  var loadingPreview = false;
  var issuing = false;
  String? serialError;
  int? autoCheckDigit;

  String? fullSerialFromBody() {
    final body = serialBodyController.text.trim();
    if (body.length != 9) return null;
    return composeItfSerial(body);
  }

  void updateCheckDigit(void Function(void Function()) setState) {
    final body = serialBodyController.text.trim();
    setState(() {
      autoCheckDigit = body.length == 9 ? calculateItfCheckDigit(body) : null;
    });
  }

  int parsedQuantity() {
    final n = int.tryParse(quantityController.text.trim());
    if (n == null || n < 1) return 1;
    return n;
  }

  int? sequencialFromBody() {
    final body = serialBodyController.text.trim();
    if (body.length != 9) return null;
    try {
      return parseSequencialFromSerial(composeItfSerial(body));
    } catch (_) {
      return null;
    }
  }

  String? quantityRangeHint(int previewSeq) {
    final qty = parsedQuantity();
    final start = sequencialFromBody() ?? previewSeq;
    if (qty <= 1) return null;
    if (start + qty - 1 > 9999) return 'Sequencial ultrapassa 9999';
    return 'Seriais $qty peças — sequencial $start a ${start + qty - 1}';
  }

  void validateSerialField(Product? product, void Function(void Function()) setState) {
    final full = fullSerialFromBody();
    if (full == null) {
      setState(() => serialError = null);
      return;
    }
    if (product == null) return;
    setState(() => serialError = validateItfSerialForProduct(full, product.idProduto));
  }

  Future<void> refreshPreview(void Function(void Function()) setState) async {
    if (selected == null) return;
    setState(() => loadingPreview = true);
    try {
      final db = ref.read(databaseProvider);
      final preview = await previewManualSerial(
        db,
        idProduto: selected!.idProduto,
        sequencialInicial: selected!.sequencialInicial,
      );
      setState(() {
        previewSeq = preview.sequencial;
        serialBodyController.text = preview.serial.substring(0, 9);
        autoCheckDigit = int.parse(preview.serial[9]);
        serialError = null;
        loadingPreview = false;
      });
    } catch (_) {
      setState(() => loadingPreview = false);
    }
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        if (serialBodyController.text.isEmpty && !loadingPreview) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            refreshPreview(setState);
          });
        }

        final modelo = selected?.nome ?? '';
        final seqDisplay = sequencialFromBody() ?? previewSeq;
        final fullSerial = fullSerialFromBody();
        final quantity = parsedQuantity();
        final rangeHint = quantityRangeHint(previewSeq);
        final canIssue = selected != null &&
            fullSerial != null &&
            serialError == null &&
            rangeHint != 'Sequencial ultrapassa 9999';

        return AlertDialog(
          title: const Text('Gerar serial para gravação'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edite os 9 primeiros dígitos; o verificador ITF (último) é calculado automaticamente. '
                  'No DiatuCAD, F2 grava o serial e o modelo do produto.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: DipontoColors.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Product>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final p in products)
                      DropdownMenuItem(
                        value: p,
                        child: Text('${p.idProduto} — ${p.nome}'),
                      ),
                  ],
                  onChanged: issuing
                      ? null
                      : (p) {
                          if (p == null) return;
                          setState(() => selected = p);
                          refreshPreview(setState);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  enabled: !issuing,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    hintText: '1',
                    helperText: 'Seriais consecutivos a enfileirar',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: opController,
                  enabled: !issuing,
                  decoration: const InputDecoration(
                    labelText: 'Referência OP (opcional)',
                    hintText: 'MANUAL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DipontoColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: loadingPreview
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Sequencial $seqDisplay',
                                    style: Theme.of(ctx).textTheme.labelLarge,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Recalcular sugestão',
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: issuing ? null : () => refreshPreview(setState),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 8,
                                  child: TextField(
                                    controller: serialBodyController,
                                    enabled: !issuing,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(9),
                                    ],
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Número de série',
                                      hintText: '9 dígitos',
                                      border: const OutlineInputBorder(),
                                      errorText: serialError,
                                      isDense: true,
                                      counterText: '${serialBodyController.text.length}/9',
                                    ),
                                    onChanged: (_) {
                                      updateCheckDigit(setState);
                                      validateSerialField(selected, setState);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 52,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Verif.',
                                        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                              color: DipontoColors.onSurface.withValues(alpha: 0.6),
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: DipontoColors.primary.withValues(alpha: 0.5),
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          color: DipontoColors.surface.withValues(alpha: 0.6),
                                        ),
                                        child: Text(
                                          autoCheckDigit?.toString() ?? '—',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: DipontoColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (fullSerial != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                quantity > 1
                                    ? 'Primeiro serial: $fullSerial'
                                    : 'Serial completo: $fullSerial',
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: DipontoColors.onSurface.withValues(alpha: 0.7),
                                    ),
                              ),
                              if (rangeHint != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  rangeHint,
                                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                        color: rangeHint.contains('ultrapassa')
                                            ? DipontoColors.error
                                            : DipontoColors.onSurface.withValues(alpha: 0.65),
                                      ),
                                ),
                              ],
                            ],
                            if (modelo.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Modelo a gravar',
                                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                      color: DipontoColors.onSurface.withValues(alpha: 0.6),
                                    ),
                              ),
                              Text(
                                modelo,
                                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: issuing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: issuing || !canIssue
                  ? null
                  : () async {
                      setState(() => issuing = true);
                      try {
                        final op = await ref.read(activeOperatorProvider.future);
                        final issues = await issueManualSerialBatch(
                          ref: ref,
                          product: selected!,
                          quantity: quantity,
                          numeroOp: opController.text,
                          operador: op != null ? AppDatabase.operatorLabel(op) : null,
                          operatorId: op?.id,
                          firstSerialOverride: fullSerial!,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          final first = issues.first;
                          showLaserEnqueuedFeedback(
                            context,
                            serial: first.serial,
                            modelo: first.modelo,
                          );
                        }
                      } catch (e) {
                        setState(() => issuing = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Erro: $e')),
                          );
                        }
                      }
                    },
              icon: issuing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.precision_manufacturing),
              label: Text(quantity > 1 ? 'Gerar $quantity seriais' : 'Gerar e gravar'),
            ),
          ],
        );
      },
    ),
  );

  opController.dispose();
  serialBodyController.dispose();
  quantityController.dispose();
}
