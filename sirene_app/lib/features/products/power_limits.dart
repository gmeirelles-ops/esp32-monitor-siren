class PowerLimits {
  const PowerLimits({required this.min, required this.max});

  final double min;
  final double max;
}

double _round2(double value) => double.parse(value.toStringAsFixed(2));

/// Arredonda potência para 2 casas — alinhado ao firmware (`%.2f`).
double roundPowerLimit(double value) => _round2(value);

PowerLimits calcularLimites(double ref, double toleranciaPct) {
  final factor = toleranciaPct / 100;
  return PowerLimits(
    min: _round2(ref * (1 - factor)),
    max: _round2(ref * (1 + factor)),
  );
}

bool isValidProductId(String id) {
  final trimmed = id.trim();
  return RegExp(r'^\d{3}$').hasMatch(trimmed);
}

String normalizeProductId(String id) => id.trim().padLeft(3, '0').substring(0, 3);
