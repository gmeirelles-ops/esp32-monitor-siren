/// Veredito de teste normalizado (case-insensitive).
bool isApprovedVeredito(String veredito) {
  return veredito.trim().toUpperCase() == 'APROVADO';
}

bool isValidVeredito(String veredito) {
  final normalized = veredito.trim().toUpperCase();
  return normalized == 'APROVADO' || normalized == 'REPROVADO';
}

/// Conta para o registro de seriais (aprovado na linha ou emitido manual).
bool countsForSerialRegistry(String veredito) {
  final normalized = veredito.trim().toUpperCase();
  return normalized == 'APROVADO' || normalized == 'MANUAL';
}
