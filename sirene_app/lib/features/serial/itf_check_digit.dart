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
  return composeItfSerial(body);
}

/// Monta serial ITF de 10 dígitos a partir do corpo de 9 dígitos.
String composeItfSerial(String nineDigitBody) {
  if (nineDigitBody.length != 9) {
    throw ArgumentError('Corpo ITF deve ter 9 dígitos, recebido ${nineDigitBody.length}');
  }
  if (!RegExp(r'^\d{9}$').hasMatch(nineDigitBody)) {
    throw ArgumentError('Corpo ITF deve conter apenas dígitos');
  }
  return '$nineDigitBody${calculateItfCheckDigit(nineDigitBody)}';
}

/// Extrai os 3 dígitos do SKU a partir do serial ITF de 10 dígitos.
String? extractIdProdutoFromSerial(String serial) {
  final trimmed = serial.trim();
  if (trimmed.length < 3) return null;
  final prefix = trimmed.substring(0, 3);
  if (!RegExp(r'^\d{3}$').hasMatch(prefix)) return null;
  return prefix;
}

/// Valida dígito verificador ITF de um serial de 10 dígitos.
bool isValidItfSerial(String serial) {
  final s = serial.trim();
  if (!RegExp(r'^\d{10}$').hasMatch(s)) return false;
  final body = s.substring(0, 9);
  final check = int.parse(s[9]);
  return calculateItfCheckDigit(body) == check;
}

/// Sequencial (4 dígitos) embutido no serial ITF.
int parseSequencialFromSerial(String serial) {
  final s = serial.trim();
  if (s.length != 10) {
    throw ArgumentError('Serial deve ter 10 dígitos');
  }
  return int.parse(s.substring(5, 9));
}

/// Ano (2 dígitos) embutido no serial ITF.
String parseAnoFromSerial(String serial) {
  final s = serial.trim();
  if (s.length != 10) {
    throw ArgumentError('Serial deve ter 10 dígitos');
  }
  return s.substring(3, 5);
}

/// Retorna mensagem de erro ou null se o serial é válido para o produto.
String? validateItfSerialForProduct(String serial, String idProduto) {
  final s = serial.trim();
  if (!RegExp(r'^\d{10}$').hasMatch(s)) {
    return 'Serial deve ter exatamente 10 dígitos';
  }
  if (!isValidItfSerial(s)) {
    return 'Dígito verificador ITF inválido';
  }
  final expectedProduct = idProduto.padLeft(3, '0').substring(0, 3);
  if (s.substring(0, 3) != expectedProduct) {
    return 'Serial deve começar com $expectedProduct (produto selecionado)';
  }
  return null;
}
