import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import '../models/manager_filters.dart';

class StationStats {
  const StationStats({required this.total, required this.aprovados});

  final int total;
  final int aprovados;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;
}

class OpStats {
  const OpStats({
    required this.total,
    required this.aprovados,
    this.stationId,
    this.lastAt,
  });

  final int total;
  final int aprovados;
  final String? stationId;
  final DateTime? lastAt;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;
}

class ProductionAggregate {
  const ProductionAggregate({
    required this.total,
    required this.aprovados,
    required this.reprovados,
    required this.yieldPct,
    required this.byStation,
    required this.byOp,
    required this.stations,
    this.byOperator = const {},
    this.byDay = const {},
    this.byStationStats = const {},
    this.byOpDetail = const {},
  });

  final int total;
  final int aprovados;
  final int reprovados;
  final double yieldPct;
  final Map<String, int> byStation;
  final Map<String, Map<String, int>> byOp;
  final List<StationHealth> stations;
  final Map<String, int> byOperator;
  final Map<String, int> byDay;
  final Map<String, StationStats> byStationStats;
  final Map<String, OpStats> byOpDetail;

  factory ProductionAggregate.fromMap(Map<String, dynamic> data) {
    final byOpRaw = data['by_op'] as Map? ?? {};
    final byOp = <String, Map<String, int>>{};
    for (final entry in byOpRaw.entries) {
      final m = entry.value as Map;
      byOp[entry.key.toString()] = {
        'total': (m['total'] as num?)?.toInt() ?? 0,
        'aprovados': (m['aprovados'] as num?)?.toInt() ?? 0,
      };
    }

    final byOpDetailRaw = data['by_op_detail'] as Map? ?? {};
    final byOpDetail = <String, OpStats>{};
    for (final entry in byOpDetailRaw.entries) {
      final m = Map<String, dynamic>.from(entry.value as Map);
      byOpDetail[entry.key.toString()] = OpStats(
        total: (m['total'] as num?)?.toInt() ?? 0,
        aprovados: (m['aprovados'] as num?)?.toInt() ?? 0,
        stationId: m['station_id'] as String?,
        lastAt: m['last_at'] is String ? DateTime.tryParse(m['last_at'] as String) : null,
      );
    }

    final stationStatsRaw = data['by_station_stats'] as Map? ?? {};
    final byStationStats = <String, StationStats>{};
    for (final entry in stationStatsRaw.entries) {
      final m = entry.value as Map;
      byStationStats[entry.key.toString()] = StationStats(
        total: (m['total'] as num?)?.toInt() ?? 0,
        aprovados: (m['aprovados'] as num?)?.toInt() ?? 0,
      );
    }

    final stationsRaw = data['stations'] as List? ?? [];
    return ProductionAggregate(
      total: (data['total'] as num?)?.toInt() ?? 0,
      aprovados: (data['aprovados'] as num?)?.toInt() ?? 0,
      reprovados: (data['reprovados'] as num?)?.toInt() ?? 0,
      yieldPct: (data['yield_pct'] as num?)?.toDouble() ?? 0,
      byStation: Map<String, int>.from(data['by_station'] as Map? ?? {}),
      byOp: byOp,
      stations: [
        for (final s in stationsRaw)
          StationHealth.fromMap(Map<String, dynamic>.from(s as Map)),
      ],
      byOperator: Map<String, int>.from(data['by_operator'] as Map? ?? {}),
      byDay: Map<String, int>.from(data['by_day'] as Map? ?? {}),
      byStationStats: byStationStats,
      byOpDetail: byOpDetail,
    );
  }
}

class StationHealth {
  const StationHealth({
    required this.stationId,
    this.lastSyncAt,
    required this.pendingQueue,
    required this.failedQueue,
    required this.stale,
  });

  final String stationId;
  final DateTime? lastSyncAt;
  final int pendingQueue;
  final int failedQueue;
  final bool stale;

  factory StationHealth.fromMap(Map<String, dynamic> data) {
    final last = data['last_sync_at'];
    DateTime? parsed;
    if (last is String) {
      parsed = DateTime.tryParse(last);
    } else if (last is Timestamp) {
      parsed = last.toDate();
    }
    return StationHealth(
      stationId: data['station_id'] as String? ?? '—',
      lastSyncAt: parsed,
      pendingQueue: (data['pending_queue'] as num?)?.toInt() ?? 0,
      failedQueue: (data['failed_queue'] as num?)?.toInt() ?? 0,
      stale: data['stale'] == true,
    );
  }
}

class AggregationService {
  AggregationService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<List<String>> listStationIds() async {
    final snap = await _firestore.collection('stations').get();
    final ids = snap.docs.map((d) => d.id).toList()..sort();
    return ids;
  }

  Future<ProductionAggregate> fetchAggregate(ManagerFilters filters) async {
    try {
      final callable = _functions.httpsCallable('aggregateProduction');
      final result = await callable.call<Map<String, dynamic>>({
        'period': filters.period,
        if (filters.stationId != null && filters.stationId!.isNotEmpty)
          'stationId': filters.stationId,
        if (filters.opFilter != null && filters.opFilter!.trim().isNotEmpty)
          'opFilter': filters.opFilter!.trim(),
        if (filters.operatorFilter != null && filters.operatorFilter!.trim().isNotEmpty)
          'operatorFilter': filters.operatorFilter!.trim(),
      });
      return ProductionAggregate.fromMap(result.data);
    } catch (_) {
      return _fetchFallback(filters);
    }
  }

  Future<ProductionAggregate> _fetchFallback(ManagerFilters filters) async {
    final since = _sinceForPeriod(filters.period);
    final opNeedle = filters.opFilter?.trim().toLowerCase();
    final operNeedle = filters.operatorFilter?.trim().toLowerCase();

    final serialSnap = await _firestore
        .collectionGroup('seriais')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    var total = 0;
    var aprovados = 0;
    final byStation = <String, int>{};
    final byOp = <String, Map<String, int>>{};
    final byOperator = <String, int>{};
    final byDay = <String, int>{};
    final byStationStats = <String, StationStats>{};
    final byOpDetail = <String, OpStats>{};

    void bumpStation(String station, {required bool approved}) {
      final prev = byStationStats[station] ?? const StationStats(total: 0, aprovados: 0);
      byStationStats[station] = StationStats(
        total: prev.total + 1,
        aprovados: prev.aprovados + (approved ? 1 : 0),
      );
      if (approved) {
        byStation[station] = (byStation[station] ?? 0) + 1;
      }
    }

    void bumpOp(String op, String station, {required bool approved, DateTime? at}) {
      byOp[op] = byOp[op] ?? {'total': 0, 'aprovados': 0};
      byOp[op]!['total'] = byOp[op]!['total']! + 1;
      if (approved) byOp[op]!['aprovados'] = byOp[op]!['aprovados']! + 1;

      final prev = byOpDetail[op];
      byOpDetail[op] = OpStats(
        total: (prev?.total ?? 0) + 1,
        aprovados: (prev?.aprovados ?? 0) + (approved ? 1 : 0),
        stationId: prev?.stationId ?? station,
        lastAt: _maxDate(prev?.lastAt, at),
      );
    }

    bool matchesOp(String op, Map<String, dynamic> data) {
      if (opNeedle == null || opNeedle.isEmpty) return true;
      final fromData = (data['numero_op'] as String? ?? '').toLowerCase();
      return op.toLowerCase().contains(opNeedle) || fromData.contains(opNeedle);
    }

    bool matchesOper(String oper) {
      if (operNeedle == null || operNeedle.isEmpty) return true;
      return oper.toLowerCase().contains(operNeedle);
    }

    for (final doc in serialSnap.docs) {
      final data = doc.data();
      final station = data['station_id'] as String? ?? '—';
      if (filters.stationId != null && station != filters.stationId) continue;
      final op = data['numero_op'] as String? ?? doc.reference.parent.parent?.id ?? '—';
      if (!matchesOp(op, data)) continue;
      final oper = data['operador'] as String? ?? data['operator_codigo']?.toString() ?? '—';
      if (!matchesOper(oper)) continue;

      final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final day = DateFormat('yyyy-MM-dd').format(ts.toLocal());

      total++;
      aprovados++;
      byDay[day] = (byDay[day] ?? 0) + 1;
      bumpStation(station, approved: true);
      bumpOp(op, station, approved: true, at: ts);
      byOperator[oper] = (byOperator[oper] ?? 0) + 1;
    }

    final reproSnap = await _firestore
        .collectionGroup('reprovadas')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    for (final doc in reproSnap.docs) {
      final data = doc.data();
      final station = data['station_id'] as String? ?? '—';
      if (filters.stationId != null && station != filters.stationId) continue;
      final op = data['numero_op'] as String? ?? doc.reference.parent.parent?.id ?? '—';
      if (!matchesOp(op, data)) continue;
      final oper = data['operador'] as String? ?? data['operator_codigo']?.toString() ?? '—';
      if (!matchesOper(oper)) continue;

      final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final day = DateFormat('yyyy-MM-dd').format(ts.toLocal());

      total++;
      byDay[day] = (byDay[day] ?? 0) + 1;
      bumpStation(station, approved: false);
      bumpOp(op, station, approved: false, at: ts);
    }

    final stationsSnap = await _firestore.collection('stations').get();
    final stations = stationsSnap.docs.map((d) {
      final data = d.data();
      final last = (data['last_sync_at'] as Timestamp?)?.toDate();
      final stale = last == null || DateTime.now().difference(last).inHours > 2;
      return StationHealth(
        stationId: d.id,
        lastSyncAt: last,
        pendingQueue: (data['pending_queue'] as num?)?.toInt() ?? 0,
        failedQueue: (data['failed_queue'] as num?)?.toInt() ?? 0,
        stale: stale,
      );
    }).toList();

    return ProductionAggregate(
      total: total,
      aprovados: aprovados,
      reprovados: total - aprovados,
      yieldPct: total == 0 ? 0 : (aprovados / total) * 100,
      byStation: byStation,
      byOp: byOp,
      stations: stations,
      byOperator: byOperator,
      byDay: byDay,
      byStationStats: byStationStats,
      byOpDetail: byOpDetail,
    );
  }

  Future<List<Map<String, dynamic>>> searchSerials(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];
    final snap = await _firestore
        .collectionGroup('seriais')
        .where('serial', isGreaterThanOrEqualTo: q)
        .where('serial', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(40)
        .get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['numero_op'] ??= d.reference.parent.parent?.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchByOp(String op) async {
    final q = op.trim();
    if (q.isEmpty) return [];
    final results = <Map<String, dynamic>>[];

    final serialSnap = await _firestore
        .collection('test_results')
        .doc(q)
        .collection('seriais')
        .orderBy('timestamp', descending: true)
        .limit(40)
        .get();
    for (final d in serialSnap.docs) {
      final data = Map<String, dynamic>.from(d.data());
      data['numero_op'] = q;
      data['_tipo'] = 'aprovado';
      results.add(data);
    }

    final reproSnap = await _firestore
        .collection('test_results')
        .doc(q)
        .collection('reprovadas')
        .orderBy('timestamp', descending: true)
        .limit(40)
        .get();
    for (final d in reproSnap.docs) {
      final data = Map<String, dynamic>.from(d.data());
      data['numero_op'] = q;
      data['_tipo'] = 'reprovado';
      results.add(data);
    }

    results.sort((a, b) {
      final ta = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return results.take(50).toList();
  }

  DateTime _sinceForPeriod(String period) {
    final now = DateTime.now();
    return switch (period) {
      'today' => DateTime(now.year, now.month, now.day),
      'week' => now.subtract(const Duration(days: 7)),
      _ => now.subtract(const Duration(days: 30)),
    };
  }

  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
