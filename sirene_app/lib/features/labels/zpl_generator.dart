/// Gera ZPL para etiquetas 10x30mm, 3 colunas, com código de barras ITF.
String generateZplLabelRow(List<String> serials) {
  if (serials.isEmpty || serials.length > 3) {
    throw ArgumentError('ZPL requer 1 a 3 seriais por linha');
  }

  final buffer = StringBuffer()
    ..writeln('^XA')
    ..writeln('^PW315')
    ..writeln('^LL120');

  const xPositions = [10, 115, 220];
  for (var i = 0; i < serials.length; i++) {
    final x = xPositions[i];
    final serial = serials[i];
    buffer
      ..writeln('^FO$x,10^BY1,2,40')
      ..writeln('^BI,N,40,Y,N^FD$serial^FS')
      ..writeln('^FO$x,55^A0N,18,18^FD$serial^FS');
  }

  buffer.writeln('^XZ');
  return buffer.toString();
}
