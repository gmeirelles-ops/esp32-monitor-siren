import 'package:cloud_firestore/cloud_firestore.dart';

import 'analytics_models.dart';

const defaultYieldTargetPct = 70.0;

class FirestoreAnalyticsRepository {
  FirestoreAnalyticsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<AnalyticsTestRecord>> fetchTestsSince(DateTime since) async {
    final sinceIso = since.toUtc().toIso8601String();
    final records = <AnalyticsTestRecord>[];

    for (final sub in ['seriais', 'reprovadas']) {
      final snap = await _db
          .collectionGroup(sub)
          .where('timestamp', isGreaterThanOrEqualTo: sinceIso)
          .get();
      for (final doc in snap.docs) {
        final r = _parseRecord(doc.data());
        if (r != null) records.add(r);
      }
    }

    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return records;
  }

  AnalyticsTestRecord? _parseRecord(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    if (ts is! String) return null;
    final timestamp = DateTime.tryParse(ts);
    if (timestamp == null) return null;

    return AnalyticsTestRecord(
      numeroOp: '${data['numero_op'] ?? ''}',
      idProduto: '${data['id_produto'] ?? ''}',
      stationId: '${data['station_id'] ?? ''}',
      deviceId: '${data['device_id'] ?? ''}',
      veredito: '${data['veredito'] ?? ''}',
      timestamp: timestamp.toLocal(),
    );
  }

  List<AnalyticsTestRecord> applyFilters(
    List<AnalyticsTestRecord> records,
    AnalyticsFilters filters,
  ) {
    return records.where((r) {
      if (filters.numeroOp != null && r.numeroOp != filters.numeroOp) return false;
      if (filters.idProduto != null && r.idProduto != filters.idProduto) return false;
      if (filters.stationId != null && r.stationId != filters.stationId) return false;
      return true;
    }).toList();
  }

  AnalyticsFilterOptions buildFilterOptions(List<AnalyticsTestRecord> records) {
    final ops = records.map((r) => r.numeroOp).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();
    final products = records.map((r) => r.idProduto).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();
    final stations = records.map((r) => r.stationId).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();
    return AnalyticsFilterOptions(ops: ops, products: products, stations: stations);
  }

  ProductionKpis computeKpis(List<AnalyticsTestRecord> records) {
    final total = records.length;
    final aprovados = records.where((r) => r.isAprovado).length;
    final reprovados = total - aprovados;
    return ProductionKpis(total: total, aprovados: aprovados, reprovados: reprovados);
  }

  double? percentChange(int current, int previous) {
    if (previous == 0) return current > 0 ? 100 : null;
    return ((current - previous) / previous) * 100;
  }

  List<DailyThroughput> throughputByDay(List<AnalyticsTestRecord> records, int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final buckets = <DateTime, DailyThroughput>{};

    for (var i = 0; i < days; i++) {
      final day = DateTime(start.year, start.month, start.day).add(Duration(days: i));
      buckets[day] = DailyThroughput(day: day, total: 0, aprovados: 0);
    }

    for (final r in records) {
      final day = DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
      final bucket = buckets[day];
      if (bucket == null) continue;
      buckets[day] = DailyThroughput(
        day: day,
        total: bucket.total + 1,
        aprovados: bucket.aprovados + (r.isAprovado ? 1 : 0),
      );
    }

    return buckets.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  }

  List<BatchProductionRow> batchRows(
    List<AnalyticsTestRecord> records, {
    double yieldTarget = defaultYieldTargetPct,
  }) {
    final byOp = <String, List<AnalyticsTestRecord>>{};
    for (final r in records) {
      if (r.numeroOp.isEmpty) continue;
      byOp.putIfAbsent(r.numeroOp, () => []).add(r);
    }

    final rows = <BatchProductionRow>[];
    for (final entry in byOp.entries) {
      final kpis = computeKpis(entry.value);
      final last = entry.value.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
      final recent = DateTime.now().difference(last) < const Duration(hours: 2);
      final status = _batchStatus(kpis, recent: recent, yieldTarget: yieldTarget);
      rows.add(
        BatchProductionRow(
          numeroOp: entry.key,
          total: kpis.total,
          aprovados: kpis.aprovados,
          reprovados: kpis.reprovados,
          status: status,
        ),
      );
    }

    rows.sort((a, b) => b.total.compareTo(a.total));
    return rows;
  }

  BatchStatus _batchStatus(
    ProductionKpis kpis, {
    required bool recent,
    required double yieldTarget,
  }) {
    if (kpis.total == 0) return BatchStatus.emAndamento;
    if (kpis.yieldPct < yieldTarget) return BatchStatus.revisar;
    if (recent) return BatchStatus.emAndamento;
    return BatchStatus.concluido;
  }

  Future<AnalyticsDashboardData> loadDashboard(AnalyticsFilters filters) async {
    final since = sinceForPeriod(filters.period)!;
    final allSince = sinceForPeriod(AnalyticsPeriod.all)!;
    final allRecords = await fetchTestsSince(allSince);
    final filtered = applyFilters(allRecords, filters);

    final periodStart = since;
    final periodRecords =
        filtered.where((r) => !r.timestamp.isBefore(periodStart)).toList();

    final kpis = computeKpis(periodRecords);
    final days = daysForPeriod(filters.period);
    final throughput = throughputByDay(periodRecords, days);
    final batchRowsList =
        filters.numeroOp == null ? batchRows(periodRecords) : <BatchProductionRow>[];

    double? yieldTrend;
    double? reprovTrend;
    if (filters.period == AnalyticsPeriod.today) {
      final yesterday = periodStart.subtract(const Duration(days: 1));
      final yesterdayEnd = periodStart;
      final yesterdayRecords = filtered
          .where((r) => !r.timestamp.isBefore(yesterday) && r.timestamp.isBefore(yesterdayEnd))
          .toList();
      final yKpis = computeKpis(yesterdayRecords);
      yieldTrend = percentChange(kpis.aprovados, yKpis.aprovados);
      reprovTrend = percentChange(kpis.reprovados, yKpis.reprovados);
    }

    final latest = filtered.isEmpty
        ? null
        : filtered.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
    final dataStale = latest == null ||
        DateTime.now().difference(latest) > const Duration(hours: 24);

    return AnalyticsDashboardData(
      kpis: kpis,
      yieldTrendPct: yieldTrend,
      reprovadosTrendPct: reprovTrend,
      throughput: throughput,
      batchRows: batchRowsList,
      filterOptions: buildFilterOptions(allRecords),
      dataStale: dataStale,
    );
  }
}
