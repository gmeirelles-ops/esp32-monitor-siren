import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';

enum DashboardPeriod { today, week, all }

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.throughput,
    required this.faults,
    required this.recentAlerts,
  });

  final ProductionSummary summary;
  final List<DailyThroughput> throughput;
  final List<FaultCount> faults;
  final List<HardwareEvent> recentAlerts;
}

/// Incrementado após novo teste ou falha de hardware gravada localmente.
final localDataRevisionProvider = StateProvider<int>((ref) => 0);

final dashboardPeriodProvider = StateProvider<DashboardPeriod>((ref) => DashboardPeriod.week);

DateTime? sinceForDashboardPeriod(DashboardPeriod period) {
  final now = DateTime.now();
  return switch (period) {
    DashboardPeriod.today => DateTime(now.year, now.month, now.day),
    DashboardPeriod.week => now.subtract(const Duration(days: 6)),
    DashboardPeriod.all => null,
  };
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  ref.watch(localDataRevisionProvider);
  final period = ref.watch(dashboardPeriodProvider);
  final db = ref.watch(databaseProvider);
  final since = sinceForDashboardPeriod(period);
  final summary = await db.productionSummary(since: since);
  final throughput = await db.throughputByDay(days: 7);
  final faults = await db.hardwareFaultCounts(since: since);
  final recentAlerts = await db.recentHardwareEvents(limit: 10);
  return DashboardData(
    summary: summary,
    throughput: throughput,
    faults: faults,
    recentAlerts: recentAlerts,
  );
});
