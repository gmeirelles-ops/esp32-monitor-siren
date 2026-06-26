import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/veredito.dart';
import '../../core/providers/core_providers.dart';
import 'dashboard_batch_status.dart';
import 'dashboard_filters.dart';

export 'dashboard_filters.dart' show DashboardFilters, DashboardPeriod, sinceForDashboardPeriod;

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.throughput,
    required this.faults,
    required this.recentAlerts,
    required this.batchSummaries,
    required this.filterOptions,
    this.yieldTrendPct,
    this.reprovadosTrendPct,
  });

  final ProductionSummary summary;
  final List<DailyThroughput> throughput;
  final List<FaultCount> faults;
  final List<HardwareEvent> recentAlerts;
  final List<BatchProductionSummary> batchSummaries;
  final DashboardFilterOptions filterOptions;
  final double? yieldTrendPct;
  final double? reprovadosTrendPct;
}

class DashboardFilterOptions {
  const DashboardFilterOptions({
    required this.ops,
    required this.products,
    required this.devices,
  });

  final List<String> ops;
  final List<String> products;
  final List<String> devices;
}

/// Incrementado após novo teste ou falha de hardware gravada localmente.
final localDataRevisionProvider = StateProvider<int>((ref) => 0);

final dashboardFiltersProvider = StateProvider<DashboardFilters>(
  (ref) => const DashboardFilters(),
);

/// Mantido para compatibilidade; preferir [dashboardFiltersProvider].
final dashboardPeriodProvider = Provider<DashboardPeriod>(
  (ref) => ref.watch(dashboardFiltersProvider).period,
);

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  ref.watch(localDataRevisionProvider);
  final filters = ref.watch(dashboardFiltersProvider);
  final db = ref.watch(databaseProvider);
  final since = effectiveSinceForPeriod(filters.period);
  final days = throughputDaysForPeriod(filters.period);
  final op = filters.numeroOp;
  final product = filters.idProduto;
  final device = filters.deviceId;

  final summary = await db.productionSummary(
    since: since,
    numeroOp: op,
    idProduto: product,
    deviceId: device,
  );
  final throughput = await db.throughputByDay(
    since: since,
    days: days,
    numeroOp: op,
    idProduto: product,
    deviceId: device,
  );
  final faults = await db.hardwareFaultCounts(since: since, deviceId: device);
  final recentAlerts = await db.recentHardwareEvents(limit: 10);
  final batchSummaries = (op == null || op.isEmpty)
      ? await db.batchSummaryInPeriod(
          since: since,
          idProduto: product,
          deviceId: device,
        )
      : <BatchProductionSummary>[];
  final filterOptions = DashboardFilterOptions(
    ops: await db.distinctOps(),
    products: await db.distinctProducts(),
    devices: await db.deviceIdsOrderedByBancada(),
  );

  double? yieldTrend;
  double? reprovTrend;
  if (filters.period == DashboardPeriod.today && since != null) {
    final yesterdayStart = since.subtract(const Duration(days: 1));
    final rows = await db.testResultsFiltered(
      since: yesterdayStart,
      numeroOp: op,
      idProduto: product,
      deviceId: device,
    );
    var todayAprovados = 0;
    var todayReprovados = 0;
    var yesterdayAprovados = 0;
    var yesterdayReprovados = 0;
    for (final r in rows) {
      final approved = isApprovedVeredito(r.veredito);
      if (!r.createdAt.isBefore(since)) {
        if (approved) {
          todayAprovados++;
        } else {
          todayReprovados++;
        }
      } else if (!r.createdAt.isBefore(yesterdayStart)) {
        if (approved) {
          yesterdayAprovados++;
        } else {
          yesterdayReprovados++;
        }
      }
    }
    yieldTrend = percentChange(todayAprovados, yesterdayAprovados);
    reprovTrend = percentChange(todayReprovados, yesterdayReprovados);
  }

  return DashboardData(
    summary: summary,
    throughput: throughput,
    faults: faults,
    recentAlerts: recentAlerts,
    batchSummaries: batchSummaries,
    filterOptions: filterOptions,
    yieldTrendPct: yieldTrend,
    reprovadosTrendPct: reprovTrend,
  );
});
