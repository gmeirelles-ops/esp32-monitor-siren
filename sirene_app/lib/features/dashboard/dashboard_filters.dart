enum DashboardPeriod { today, week, all }

DateTime? sinceForDashboardPeriod(DashboardPeriod period) {
  final now = DateTime.now();
  return switch (period) {
    DashboardPeriod.today => DateTime(now.year, now.month, now.day),
    DashboardPeriod.week => now.subtract(const Duration(days: 6)),
    DashboardPeriod.all => null,
  };
}

class DashboardFilters {
  const DashboardFilters({
    this.period = DashboardPeriod.week,
    this.numeroOp,
    this.idProduto,
    this.deviceId,
  });

  final DashboardPeriod period;
  final String? numeroOp;
  final String? idProduto;
  final String? deviceId;

  DashboardFilters copyWith({
    DashboardPeriod? period,
    String? numeroOp,
    String? idProduto,
    String? deviceId,
    bool clearNumeroOp = false,
    bool clearIdProduto = false,
    bool clearDeviceId = false,
  }) {
    return DashboardFilters(
      period: period ?? this.period,
      numeroOp: clearNumeroOp ? null : (numeroOp ?? this.numeroOp),
      idProduto: clearIdProduto ? null : (idProduto ?? this.idProduto),
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
    );
  }

  bool get hasActiveFilters =>
      (numeroOp != null && numeroOp!.isNotEmpty) ||
      (idProduto != null && idProduto!.isNotEmpty) ||
      (deviceId != null && deviceId!.isNotEmpty);
}

/// Dias inclusivos para gráfico de throughput conforme o período.
int throughputDaysForPeriod(DashboardPeriod period) {
  return switch (period) {
    DashboardPeriod.today => 1,
    DashboardPeriod.week => 7,
    DashboardPeriod.all => 30,
  };
}

/// Início efetivo do período (meia-noite local quando aplicável).
DateTime effectiveSinceForPeriod(DashboardPeriod period) {
  final explicit = sinceForDashboardPeriod(period);
  if (explicit != null) {
    return DateTime(explicit.year, explicit.month, explicit.day);
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
}
