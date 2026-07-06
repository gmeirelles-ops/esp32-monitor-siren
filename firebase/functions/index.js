const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

initializeApp();

function sinceForPeriod(period) {
  const now = new Date();
  if (period === 'today') {
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
  }
  if (period === 'week') {
    return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  }
  return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
}

function dayKey(date) {
  return date.toISOString().slice(0, 10);
}

function matchesOp(op, data, opFilter) {
  if (!opFilter) return true;
  const needle = opFilter.toLowerCase();
  const fromData = (data.numero_op ?? '').toString().toLowerCase();
  return op.toLowerCase().includes(needle) || fromData.includes(needle);
}

function matchesOper(data, operatorFilter) {
  if (!operatorFilter) return true;
  const needle = operatorFilter.toLowerCase();
  const oper = (data.operador ?? data.operator_codigo ?? '—').toString().toLowerCase();
  return oper.includes(needle);
}

exports.aggregateProduction = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Login necessário');
  }
  const period = request.data?.period ?? 'week';
  const stationFilter = request.data?.stationId ?? null;
  const opFilter = request.data?.opFilter ?? null;
  const operatorFilter = request.data?.operatorFilter ?? null;
  const since = sinceForPeriod(period);

  const db = getFirestore();
  const serialSnap = await db
    .collectionGroup('seriais')
    .where('timestamp', '>=', Timestamp.fromDate(since))
    .get();

  let total = 0;
  let aprovados = 0;
  const byStation = {};
  const byOp = {};
  const byOperator = {};
  const byDay = {};
  const byStationStats = {};
  const byOpDetail = {};

  function bumpStation(station, approved) {
    const prev = byStationStats[station] ?? { total: 0, aprovados: 0 };
    byStationStats[station] = {
      total: prev.total + 1,
      aprovados: prev.aprovados + (approved ? 1 : 0),
    };
    if (approved) {
      byStation[station] = (byStation[station] ?? 0) + 1;
    }
  }

  function bumpOp(op, station, approved, at) {
    byOp[op] = byOp[op] ?? { total: 0, aprovados: 0 };
    byOp[op].total++;
    if (approved) byOp[op].aprovados++;

    const prev = byOpDetail[op];
    byOpDetail[op] = {
      total: (prev?.total ?? 0) + 1,
      aprovados: (prev?.aprovados ?? 0) + (approved ? 1 : 0),
      station_id: prev?.station_id ?? station,
      last_at: prev?.last_at && at && new Date(prev.last_at) > at ? prev.last_at : at?.toISOString() ?? prev?.last_at ?? null,
    };
  }

  for (const doc of serialSnap.docs) {
    const data = doc.data();
    const station = data.station_id ?? '—';
    if (stationFilter && station !== stationFilter) continue;
    const op = data.numero_op ?? doc.ref.parent.parent?.id ?? '—';
    if (!matchesOp(op, data, opFilter)) continue;
    if (!matchesOper(data, operatorFilter)) continue;

    const ts = data.timestamp?.toDate?.() ?? new Date();
    const day = dayKey(ts);

    total++;
    aprovados++;
    byDay[day] = (byDay[day] ?? 0) + 1;
    bumpStation(station, true);
    bumpOp(op, station, true, ts);
    const oper = data.operador ?? data.operator_codigo?.toString() ?? '—';
    byOperator[oper] = (byOperator[oper] ?? 0) + 1;
  }

  const reproSnap = await db
    .collectionGroup('reprovadas')
    .where('timestamp', '>=', Timestamp.fromDate(since))
    .get();

  for (const doc of reproSnap.docs) {
    const data = doc.data();
    const station = data.station_id ?? '—';
    if (stationFilter && station !== stationFilter) continue;
    const op = data.numero_op ?? doc.ref.parent.parent?.id ?? '—';
    if (!matchesOp(op, data, opFilter)) continue;
    if (!matchesOper(data, operatorFilter)) continue;

    const ts = data.timestamp?.toDate?.() ?? new Date();
    const day = dayKey(ts);

    total++;
    byDay[day] = (byDay[day] ?? 0) + 1;
    bumpStation(station, false);
    bumpOp(op, station, false, ts);
  }

  const stationsSnap = await db.collection('stations').get();
  const stations = stationsSnap.docs.map((d) => {
    const data = d.data();
    const last = data.last_sync_at?.toDate?.() ?? null;
    const stale = !last || Date.now() - last.getTime() > 2 * 60 * 60 * 1000;
    return {
      station_id: d.id,
      last_sync_at: last?.toISOString() ?? null,
      pending_queue: data.pending_queue ?? 0,
      failed_queue: data.failed_queue ?? 0,
      stale,
    };
  });

  return {
    total,
    aprovados,
    reprovados: total - aprovados,
    yield_pct: total === 0 ? 0 : (aprovados / total) * 100,
    by_station: byStation,
    by_op: byOp,
    by_operator: byOperator,
    by_day: byDay,
    by_station_stats: byStationStats,
    by_op_detail: byOpDetail,
    stations,
  };
});
