/// Calcula o dígito verificador ITF (Interleaved 2 of 5) usando módulo 10.
/// Pesos alternados 3, 1, 3, 1... da direita para a esquerda (padrão GS1).
int calculateItfCheckDigit(String nineDigits) {
  if (nineDigits.length != 9) {
    throw ArgumentError('Esperado 9 dígitos, recebido ${nineDigits.length}');
  }
  if (!RegExp(r'^\d{9}$').hasMatch(nineDigits)) {
    throw ArgumentError('Corpo do serial deve conter apenas dígitos');
  }

  var sum = 0;
  for (var i = 0; i < 9; i++) {
    final digit = nineDigits.codeUnitAt(8 - i) - 48;
    final weight = i.isEven ? 3 : 1;
    sum += digit * weight;
  }
  return (10 - (sum % 10)) % 10;
}

String buildSerialBody({
  required String idProduto,
  required String ano,
  required int sequencial,
}) {
  final product = idProduto.padLeft(3, '0').substring(0, 3);
  final year = ano.padLeft(2, '0').substring(0, 2);
  final seq = sequencial.toString().padLeft(4, '0');
  return '$product$year$seq';
}

String generateFullSerial({
  required String idProduto,
  required String ano,
  required int sequencial,
}) {
  final body = buildSerialBody(
    idProduto: idProduto,
    ano: ano,
    sequencial: sequencial,
  );
  final check = calculateItfCheckDigit(body);
  return '$body$check';
}
