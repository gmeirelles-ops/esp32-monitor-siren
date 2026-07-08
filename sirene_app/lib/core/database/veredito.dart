/// Veredito de teste normalizado (case-insensitive).
bool isApprovedVeredito(String veredito) {
  return veredito.trim().toUpperCase() == 'APROVADO';
}

bool isValidVeredito(String veredito) {
  final normalized = veredito.trim().toUpperCase();
  return normalized == 'APROVADO' || normalized == 'REPROVADO';
}
