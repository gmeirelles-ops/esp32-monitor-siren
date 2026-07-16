import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/desktop_form_layout.dart';
import '../cloud/sync/sync_providers.dart';
import '../../shared/display_labels.dart';
import '../../shared/dropdown_value.dart';
import '../bancadas/bancadas_provider.dart';
import '../mqtt/models/mqtt_messages.dart';
import '../mqtt/mqtt_providers.dart';
import 'device_calibration.dart';
import 'power_limits.dart';
import 'product_calibration_section.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.existing});

  final Product? existing;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idProduto;
  late final TextEditingController _nome;
  late final TextEditingController _manual;
  late final TextEditingController _tolerancia;
  late final TextEditingController _tempoTeste;
  late final TextEditingController _potenciaRef;
  late final TextEditingController _potenciaMin;
  late final TextEditingController _potenciaMax;
  late final TextEditingController _sequencialInicial;

  String? _selectedDeviceId;
  bool _measuring = false;
  bool _saving = false;
  final List<double> _samples = [];
  int _elapsedMs = 0;
  double? _peakSample;
  DateTime? _calibratedAt;

  bool get _isEditing => widget.existing != null;

  double? get _sampleAverage {
    if (_samples.isEmpty) return null;
    var sum = 0.0;
    for (final sample in _samples) {
      sum += sample;
    }
    return sum / _samples.length;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _idProduto = TextEditingController(text: e?.idProduto ?? '');
    _nome = TextEditingController(text: e?.nome ?? '');
    _manual = TextEditingController(text: e?.manual ?? '');
    _tolerancia = TextEditingController(
      text: (e?.toleranciaPct ?? 10).toStringAsFixed(0),
    );
    _tempoTeste = TextEditingController(
      text: (e?.tempoTesteSec ?? 5).toString(),
    );
    _potenciaRef = TextEditingController(
      text: e != null ? e.potenciaRef.toStringAsFixed(2) : '',
    );
    _potenciaMin = TextEditingController(
      text: e != null ? e.potenciaMin.toStringAsFixed(2) : '',
    );
    _potenciaMax = TextEditingController(
      text: e != null ? e.potenciaMax.toStringAsFixed(2) : '',
    );
    _sequencialInicial = TextEditingController(
      text: e?.sequencialInicial != null ? '${e!.sequencialInicial}' : '',
    );
  }

  @override
  void dispose() {
    _idProduto.dispose();
    _nome.dispose();
    _manual.dispose();
    _tolerancia.dispose();
    _tempoTeste.dispose();
    _potenciaRef.dispose();
    _potenciaMin.dispose();
    _potenciaMax.dispose();
    _sequencialInicial.dispose();
    super.dispose();
  }

  void _applyLimitsFromRef(double ref, {double? potenciaPico}) {
    final tol = double.tryParse(_tolerancia.text) ?? 10;
    final limits = calcularLimitesFromCalibration(
      potenciaMedia: ref,
      toleranciaPct: tol,
      potenciaPico: potenciaPico ?? _peakSample,
    );
    _potenciaRef.text = ref.toStringAsFixed(2);
    _potenciaMin.text = limits.min.toStringAsFixed(2);
    _potenciaMax.text = limits.max.toStringAsFixed(2);
  }

  void _recalcFromRefField() {
    final ref = double.tryParse(_potenciaRef.text.replaceAll(',', '.'));
    if (ref == null) return;
    final tol = double.tryParse(_tolerancia.text) ?? 10;
    final limits = calcularLimites(ref, tol);
    _potenciaMin.text = limits.min.toStringAsFixed(2);
    _potenciaMax.text = limits.max.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _startMeasurement() async {
    final deviceId = _selectedDeviceId;
    if (deviceId == null) {
      _showSnack('Selecione um dispositivo');
      return;
    }

    final device = ref.read(devicesProvider)[deviceId];
    if (device == null) {
      _showSnack('Dispositivo não encontrado');
      return;
    }
    if (!DeviceCalibration.canCalibrate(
      deviceOnline: device.isOnline,
      estado: device.estado.mqttEstado,
    )) {
      _showSnack(
        DeviceCalibration.estadoHint(device.estado.mqttEstado, device.isOnline),
      );
      return;
    }

    final tempoTeste = int.tryParse(_tempoTeste.text) ?? 5;

    setState(() {
      _measuring = true;
      _samples.clear();
      _elapsedMs = 0;
      _peakSample = null;
    });

    await ref
        .read(devicesProvider.notifier)
        .sendStartCalibration(deviceId, tempoTesteSec: tempoTeste);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text(
          'Excluir produto ${existing.idProduto} — ${existing.nome}?\n\n'
          'Esta ação remove do posto e da nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: DipontoColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      await db.deleteProduct(existing.idProduto);
      await ref
          .read(firestoreSyncServiceProvider)
          .enqueueProductDelete(existing.idProduto);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Erro ao excluir: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = normalizeProductId(_idProduto.text);
    final db = ref.read(databaseProvider);

    if (!_isEditing) {
      final exists = await db.getProduct(id);
      if (exists != null) {
        _showSnack('ID $id já cadastrado — edite o produto existente');
        return;
      }
    }

    final refVal = double.parse(_potenciaRef.text.replaceAll(',', '.'));
    final min = double.parse(_potenciaMin.text.replaceAll(',', '.'));
    final max = double.parse(_potenciaMax.text.replaceAll(',', '.'));

    if (min >= max) {
      _showSnack('Potência mín deve ser menor que a máxima');
      return;
    }

    final seqRaw = _sequencialInicial.text.trim();
    int? sequencialInicial;
    if (seqRaw.isNotEmpty) {
      sequencialInicial = int.tryParse(seqRaw);
      if (sequencialInicial == null ||
          sequencialInicial < 1 ||
          sequencialInicial > 9999) {
        _showSnack('Sequencial inicial deve ser entre 1 e 9999');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await db.upsertProduct(
        idProduto: id,
        nome: _nome.text.trim(),
        manual: _manual.text.trim(),
        potenciaRef: refVal,
        potenciaMin: min,
        potenciaMax: max,
        toleranciaPct: double.parse(_tolerancia.text),
        tempoTesteSec: int.parse(_tempoTeste.text),
        calibradoEm: _calibratedAt ?? widget.existing?.calibradoEm,
        calibradoDeviceId:
            _selectedDeviceId ?? widget.existing?.calibradoDeviceId,
        sequencialInicial: sequencialInicial,
      );
      final saved = await db.getProduct(id);
      if (saved != null) {
        await ref.read(firestoreSyncServiceProvider).enqueueProduct(saved);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDevice(
    List<DeviceInfo> deviceList,
    Map<String, int> bancadas,
  ) async {
    if (_measuring) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Bancada para calibração'),
        children: [
          for (final d in deviceList)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d.deviceId),
              child: Text(
                '${formatBancadaLabelFromMap(d.deviceId, bancadas)} (${d.estado.mqttEstado})',
              ),
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDeviceId = picked);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    final deviceList = devices.values.toList();
    final deviceIds = deviceList.map((d) => d.deviceId).toList();
    _selectedDeviceId =
        validDropdownValue(_selectedDeviceId, deviceIds) ??
        (deviceIds.isNotEmpty ? deviceIds.first : null);

    ref.listen(calibrationSamplesProvider, (_, next) {
      next.whenData((event) {
        if (event.deviceId != _selectedDeviceId || !_measuring) return;
        setState(() {
          _peakSample = _peakSample == null
              ? event.sample.potenciaW
              : math.max(_peakSample!, event.sample.potenciaW);
          _elapsedMs = event.sample.elapsedMs;
          _samples.add(event.sample.potenciaW);
        });
      });
    });

    ref.listen(calibrationCompleteProvider, (_, next) {
      next.whenData((event) async {
        if (event.deviceId != _selectedDeviceId || !_measuring) return;
        final idProduto =
            widget.existing?.idProduto ?? normalizeProductId(_idProduto.text);
        if (idProduto.isNotEmpty) {
          await ref
              .read(databaseProvider)
              .insertCalibration(
                idProduto: idProduto,
                potenciaRef: event.result.potenciaMedia,
                deviceId: event.deviceId,
              );
        }
        if (!mounted) return;
        setState(() {
          _measuring = false;
          _calibratedAt = DateTime.now();
        });
        _applyLimitsFromRef(
          event.result.potenciaMedia,
          potenciaPico: event.result.potenciaMax ?? _peakSample,
        );
        _showSnack(
          'Calibração concluída (média): ${event.result.potenciaMedia.toStringAsFixed(2)} W',
        );
      });
    });

    ref.listen(rejectionStreamProvider, (_, next) {
      next.whenData((r) {
        if (_measuring) {
          setState(() => _measuring = false);
          _showSnack('Calibração rejeitada: ${r.motivo}');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar produto' : 'Novo produto'),
      ),
      body: ListView(
        children: [
          DesktopFormLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _idProduto,
                        enabled: !_isEditing,
                        decoration: const InputDecoration(
                          labelText: 'ID Produto (3 dígitos)',
                        ),
                        validator: (v) => v != null && isValidProductId(v)
                            ? null
                            : 'Informe 3 dígitos',
                      ),
                      TextFormField(
                        controller: _nome,
                        decoration: const InputDecoration(
                          labelText: 'Nome do produto',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obrigatório'
                            : null,
                      ),
                      TextFormField(
                        controller: _manual,
                        decoration: const InputDecoration(
                          labelText: 'Manual do produto',
                          helperText:
                              'Opcional. Quando informado, o texto é enviado para a gravação laser.',
                        ),
                      ),
                      TextFormField(
                        controller: _tolerancia,
                        decoration: const InputDecoration(
                          labelText: 'Tolerância (%)',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _recalcFromRefField(),
                      ),
                      TextFormField(
                        controller: _tempoTeste,
                        decoration: const InputDecoration(
                          labelText: 'Tempo de teste (s)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _sequencialInicial,
                        decoration: const InputDecoration(
                          labelText: 'Próximo sequencial de série',
                          hintText: 'Ex.: 450 (deixe vazio para começar em 1)',
                          helperText:
                              '4 dígitos do serial ITF. Use quando a numeração não reinicia em 0001.',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (deviceList.isEmpty)
                  const Text(
                    'Nenhum dispositivo online — conecte uma bancada primeiro.',
                  )
                else
                  ProductCalibrationSection(
                    selectedDeviceName: _selectedDeviceId != null
                        ? formatBancadaLabelFromMap(
                            _selectedDeviceId!,
                            bancadas,
                          )
                        : null,
                    selectedDeviceId: _selectedDeviceId,
                    deviceOnline: devices[_selectedDeviceId]?.isOnline ?? false,
                    deviceEstado: devices[_selectedDeviceId]?.estado.mqttEstado,
                    calibrating: _measuring,
                    onRecalibrate: _startMeasurement,
                    onDevicePicker: () => _pickDevice(deviceList, bancadas),
                    buttonLabel: _isEditing
                        ? 'Recalibrar peça padrão'
                        : 'Medir peça padrão',
                  ),
                if (_measuring || _samples.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: DipontoColors.primary.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _measuring ? 'Medindo...' : 'Última medição',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_peakSample != null)
                            Text(
                              'Pico no ciclo: ${_peakSample!.toStringAsFixed(2)} W',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: DipontoColors.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                            ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value:
                                (_elapsedMs /
                                        ((int.tryParse(_tempoTeste.text) ?? 5) *
                                            1000))
                                    .clamp(0.0, 1.0),
                            color: DipontoColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sampleAverage != null
                                ? 'Média: ${_sampleAverage!.toStringAsFixed(2)} W'
                                : 'Aguardando leituras...',
                            style: const TextStyle(
                              fontSize: 24,
                              color: DipontoColors.primaryLight,
                            ),
                          ),
                          if (_samples.length >= 2) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: CustomPaint(
                                size: const Size(double.infinity, 60),
                                painter: _SparklinePainter(_samples),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Limites de potência',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _potenciaRef,
                  decoration: const InputDecoration(
                    labelText: 'Potência referência (W)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _recalcFromRefField(),
                ),
                TextFormField(
                  controller: _potenciaMin,
                  decoration: const InputDecoration(
                    labelText: 'Potência mín (W)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextFormField(
                  controller: _potenciaMax,
                  decoration: const InputDecoration(
                    labelText: 'Potência máx (W)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Histórico de calibração',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _CalibrationHistoryList(
                    idProduto: widget.existing!.idProduto,
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? 'Salvar alterações'
                                : 'Cadastrar produto',
                          ),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      style: TextButton.styleFrom(
                        foregroundColor: DipontoColors.error,
                      ),
                      label: const Text('Excluir produto'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationHistoryList extends ConsumerWidget {
  const _CalibrationHistoryList({required this.idProduto});

  final String idProduto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final bancadas = ref.watch(bancadasMapProvider).valueOrNull ?? {};
    return StreamBuilder<List<CalibrationHistoryData>>(
      stream: db.watchCalibrationHistory(idProduto),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final history = snapshot.data!;
        if (history.isEmpty) {
          return Text(
            'Sem calibrações registradas.',
            style: TextStyle(
              color: DipontoColors.onSurface.withValues(alpha: 0.6),
            ),
          );
        }
        return Column(
          children: [
            for (final c in history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.sensors,
                  color: DipontoColors.primary,
                ),
                title: Text('${c.potenciaRef.toStringAsFixed(2)} W'),
                subtitle: Text(
                  '${c.createdAt.toLocal()}'
                  '${c.deviceId != null ? ' — ${formatBancadaLabelFromMap(c.deviceId!, bancadas)}' : ''}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.samples);

  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final minVal = samples.reduce(math.min);
    final maxVal = samples.reduce(math.max);
    final range = (maxVal - minVal).abs() < 0.01 ? 1.0 : maxVal - minVal;

    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = size.width * i / (samples.length - 1);
      final y = size.height - ((samples[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = DipontoColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.samples.length != samples.length;
}
