enum AnalyticsPeriod { today, week, all }

DateTime? sinceForPeriod(AnalyticsPeriod period) {
  final now = DateTime.now();
  return switch (period) {
    AnalyticsPeriod.today => DateTime(now.year, now.month, now.day),
    AnalyticsPeriod.week => DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
    AnalyticsPeriod.all => DateTime.now().subtract(const Duration(days: 29)),
  };
}

int daysForPeriod(AnalyticsPeriod period) => switch (period) {
      AnalyticsPeriod.today => 1,
      AnalyticsPeriod.week => 7,
      AnalyticsPeriod.all => 30,
    };

class AnalyticsFilters {
  const AnalyticsFilters({
    this.period = AnalyticsPeriod.week,
    this.numeroOp,
    this.idProduto,
    this.stationId,
  });

  final AnalyticsPeriod period;
  final String? numeroOp;
  final String? idProduto;
  final String? stationId;

  AnalyticsFilters copyWith({
    AnalyticsPeriod? period,
    String? numeroOp,
    String? idProduto,
    String? stationId,
    bool clearNumeroOp = false,
    bool clearIdProduto = false,
    bool clearStationId = false,
  }) {
    return AnalyticsFilters(
      period: period ?? this.period,
      numeroOp: clearNumeroOp ? null : (numeroOp ?? this.numeroOp),
      idProduto: clearIdProduto ? null : (idProduto ?? this.idProduto),
      stationId: clearStationId ? null : (stationId ?? this.stationId),
    );
  }

  bool get hasActiveFilters =>
      (numeroOp != null && numeroOp!.isNotEmpty) ||
      (idProduto != null && idProduto!.isNotEmpty) ||
      (stationId != null && stationId!.isNotEmpty);
}

class ProductionKpis {
  const ProductionKpis({
    required this.total,
    required this.aprovados,
    required this.reprovados,
    this.trendPct,
    this.trendLabel,
  });

  final int total;
  final int aprovados;
  final int reprovados;
  final double? trendPct;
  final String? trendLabel;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;
}

class DailyThroughput {
  const DailyThroughput({
    required this.day,
    required this.total,
    required this.aprovados,
  });

  final DateTime day;
  final int total;
  final int aprovados;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;
}

enum BatchStatus { emAndamento, concluido, revisar }

class BatchProductionRow {
  const BatchProductionRow({
    required this.numeroOp,
    required this.total,
    required this.aprovados,
    required this.reprovados,
    required this.status,
  });

  final String numeroOp;
  final int total;
  final int aprovados;
  final int reprovados;
  final BatchStatus status;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;
}

class AnalyticsFilterOptions {
  const AnalyticsFilterOptions({
    required this.ops,
    required this.products,
    required this.stations,
  });

  final List<String> ops;
  final List<String> products;
  final List<String> stations;
}

class AnalyticsDashboardData {
  const AnalyticsDashboardData({
    required this.kpis,
    required this.yieldTrendPct,
    required this.reprovadosTrendPct,
    required this.throughput,
    required this.batchRows,
    required this.filterOptions,
    required this.dataStale,
  });

  final ProductionKpis kpis;
  final double? yieldTrendPct;
  final double? reprovadosTrendPct;
  final List<DailyThroughput> throughput;
  final List<BatchProductionRow> batchRows;
  final AnalyticsFilterOptions filterOptions;
  final bool dataStale;
}

class AnalyticsTestRecord {
  const AnalyticsTestRecord({
    required this.numeroOp,
    required this.idProduto,
    required this.stationId,
    required this.deviceId,
    required this.veredito,
    required this.timestamp,
  });

  final String numeroOp;
  final String idProduto;
  final String stationId;
  final String deviceId;
  final String veredito;
  final DateTime timestamp;

  bool get isAprovado => veredito.toUpperCase() == 'APROVADO';
}
