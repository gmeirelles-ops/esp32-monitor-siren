import '../../core/database/database.dart';

/// Dados de uma etiqueta para geração ZPL (NiceLabel: produto + serial).
class LabelZplItem {
  const LabelZplItem({required this.serial, required this.productName});

  final String serial;
  final String productName;
}

/// Uma etiqueta: 30×10 mm @ 203 dpi (^PW239 ≈ 29,9 mm).
const zplLabelWidth = 239;
const zplLabelLength = 80;
const zplColumnPitch = 239;
const zplRowPrintWidth = zplLabelWidth * 3;

/// Resolve nome do produto pelo prefixo de 3 dígitos do serial.
Future<List<LabelZplItem>> resolveLabelZplItems(
  AppDatabase db,
  List<String> serials,
) async {
  if (serials.isEmpty) return [];

  final products = await db.getProducts();
  final nameById = {
    for (final p in products) p.idProduto.padLeft(3, '0').substring(0, 3): p.nome,
  };

  return serials
      .map(
        (serial) => LabelZplItem(
          serial: serial,
          productName: serial.length >= 3
              ? (nameById[serial.substring(0, 3)] ?? serial.substring(0, 3))
              : serial,
        ),
      )
      .toList();
}

/// ZPL de referência NiceLabel para uma etiqueta (offset X opcional para colunas).
String generateZplSingleLabel({
  required String productName,
  required String serial,
  int xOffset = 0,
}) {
  final name = productName.trim().isEmpty ? 'PRODUTO' : productName.trim();
  final x = xOffset;
  return '''
^FO${6 + x},3^GB145,40,40,B,0^FS
^FO${6 + x},12^A0N,25,25^FR^FD $name ^FS
^FO${152 + x},8^A0N,22,22^FDMADE IN^FS
^FO${152 + x},25^A0N,22,22^FDBRAZIL^FS
^FO${75 + x},55^A0N,20,20^FD$serial^FS'''
      .trim();
}

/// Linha com 1 a 3 etiquetas (rolo 3-across), layout NiceLabel.
String generateZplLabelRow(List<LabelZplItem> items) {
  if (items.isEmpty || items.length > 3) {
    throw ArgumentError('ZPL requer 1 a 3 etiquetas por linha');
  }

  final buffer = StringBuffer()
    ..writeln('^XA')
    ..writeln('^PW$zplRowPrintWidth')
    ..writeln('^LL$zplLabelLength');

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item.serial.isEmpty) continue;
    buffer.writeln(
      generateZplSingleLabel(
        productName: item.productName,
        serial: item.serial,
        xOffset: i * zplColumnPitch,
      ),
    );
  }

  buffer.writeln('^XZ');
  return buffer.toString();
}

/// Reimpressão: linha completa, serial na coluna 1 (cols 2–3 vazias).
String generateZplReprintRow({
  required String serial,
  required String productName,
}) {
  if (serial.isEmpty) {
    throw ArgumentError('Serial não pode ser vazio');
  }
  return generateZplLabelRow([
    LabelZplItem(serial: serial, productName: productName),
  ]);
}

/// Concatena blocos ZPL (até 3 etiquetas por bloco) para exportação em lote.
String generateZplForItems(List<LabelZplItem> items, {int batchSize = 3}) {
  if (items.isEmpty) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize).clamp(0, items.length);
    buffer.write(generateZplLabelRow(items.sublist(i, end)));
  }
  return buffer.toString();
}

/// @deprecated Prefer [generateZplForItems] com [LabelZplItem].
String generateZplForSerials(List<String> serials, {int batchSize = 3}) {
  return generateZplForItems(
    serials.map((s) => LabelZplItem(serial: s, productName: s.length >= 3 ? s.substring(0, 3) : s)).toList(),
    batchSize: batchSize,
  );
}
