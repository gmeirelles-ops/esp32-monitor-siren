import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'batch_metrics.dart';
import 'traceability.dart';
import 'veredito.dart';

part 'database.g.dart';

class TestResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text()();
  TextColumn get numeroOp => text()();
  TextColumn get veredito => text()();
  RealColumn get potenciaMedia => real()();
  IntColumn get sequencial => integer()();
  IntColumn get aprovadosNoLote => integer()();
  TextColumn get serial => text().nullable()();
  TextColumn get operador => text().nullable()();
  IntColumn get tempoTesteSec => integer().nullable()();
  RealColumn get potenciaMin => real().nullable()();
  RealColumn get potenciaMax => real().nullable()();
  IntColumn get operatorId => integer().nullable()();
  BoolColumn get isRetest => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class LabelBufferEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serial => text()();
  TextColumn get numeroOp => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class MarkQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serial => text()();
  TextColumn get numeroOp => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class Products extends Table {
  TextColumn get idProduto => text()();
  TextColumn get nome => text()();
  RealColumn get potenciaRef => real()();
  RealColumn get potenciaMin => real()();
  RealColumn get potenciaMax => real()();
  RealColumn get toleranciaPct => real().withDefault(const Constant(10.0))();
  IntColumn get tempoTesteSec => integer().withDefault(const Constant(5))();
  DateTimeColumn get calibradoEm => dateTime().nullable()();
  TextColumn get calibradoDeviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {idProduto};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collection => text()();
  TextColumn get documentId => text()();
  TextColumn get documentPath => text().nullable()();
  TextColumn get payload => text()();
  TextColumn get operation => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

class SerialCounters extends Table {
  TextColumn get idProduto => text()();
  TextColumn get ano => text()();
  IntColumn get lastSequencial => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {idProduto, ano};
}

class HardwareEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text()();
  TextColumn get falha => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class CalibrationHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idProduto => text()();
  RealColumn get potenciaRef => real()();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class OpLocks extends Table {
  TextColumn get numeroOp => text()();
  TextColumn get status => text()();
  DateTimeColumn get lockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {numeroOp};
}

class Operators extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nome => text()();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  BoolColumn get isGestor => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class RemarkLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serial => text()();
  TextColumn get numeroOp => text()();
  TextColumn get mode => text()();
  IntColumn get operatorId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Bancadas extends Table {
  IntColumn get numero => integer().autoIncrement()();
  TextColumn get deviceId => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    TestResults,
    LabelBufferEntries,
    MarkQueueEntries,
    Products,
    SyncQueue,
    SerialCounters,
    HardwareEvents,
    CalibrationHistory,
    OpLocks,
    Operators,
    Bancadas,
    RemarkLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static Future<File> dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'sirene_app.sqlite'));
  }

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(products);
          }
          if (from < 3) {
            await m.createTable(syncQueue);
          }
          if (from < 4) {
            await m.createTable(serialCounters);
            await _backfillSerialCounters();
          }
          if (from < 5) {
            await m.addColumn(testResults, testResults.operador);
          }
          if (from < 6) {
            await m.createTable(hardwareEvents);
          }
          if (from < 7) {
            await m.createTable(calibrationHistory);
            await m.createTable(opLocks);
          }
          if (from < 8) {
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_test_results_serial ON test_results(serial)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_test_results_created_at ON test_results(created_at)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sync_queue_attempts ON sync_queue(attempts)',
            );
          }
          if (from < 9) {
            await m.createTable(operators);
          }
          if (from < 10) {
            await m.addColumn(testResults, testResults.isRetest);
          }
          if (from < 11) {
            await m.createTable(bancadas);
            await _backfillBancadas();
          }
          if (from < 12) {
            await m.addColumn(syncQueue, syncQueue.documentPath);
          }
          if (from < 13) {
            await m.createTable(markQueueEntries);
          }
          if (from < 14) {
            await m.addColumn(testResults, testResults.tempoTesteSec);
            await m.addColumn(testResults, testResults.potenciaMin);
            await m.addColumn(testResults, testResults.potenciaMax);
            await m.addColumn(testResults, testResults.operatorId);
            await m.addColumn(operators, operators.updatedAt);
            await m.createTable(remarkLogs);
          }
          if (from < 15) {
            await m.addColumn(operators, operators.isGestor);
          }
        },
      );

  Future<void> _backfillBancadas() async {
    final existing = await select(bancadas).get();
    if (existing.isNotEmpty) return;

    final rows = await customSelect(
      'SELECT device_id, MIN(created_at) AS first_at '
      'FROM test_results GROUP BY device_id ORDER BY first_at',
      readsFrom: {testResults},
    ).get();

    for (final row in rows) {
      await into(bancadas).insert(
        BancadasCompanion.insert(
          deviceId: row.read<String>('device_id'),
          createdAt: row.read<DateTime>('first_at'),
        ),
      );
    }
  }

  /// Preenche `bancadas` a partir do histórico de testes (usado na migração e testes).
  Future<void> backfillBancadasFromHistory() => _backfillBancadas();

  /// Garante registro de bancada e retorna o número sequencial (1, 2, 3…).
  Future<int> ensureBancada(String deviceId) async {
    final existing = await (select(bancadas)
          ..where((b) => b.deviceId.equals(deviceId)))
        .getSingleOrNull();
    if (existing != null) return existing.numero;

    return into(bancadas).insert(
      BancadasCompanion.insert(
        deviceId: deviceId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<Bancada?> getBancadaByDevice(String deviceId) {
    return (select(bancadas)..where((b) => b.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  Future<Map<String, int>> getBancadaNumeros() async {
    final rows = await select(bancadas).get();
    return {for (final r in rows) r.deviceId: r.numero};
  }

  Stream<Map<String, int>> watchBancadaNumeros() {
    return select(bancadas).watch().map(
          (rows) => {for (final r in rows) r.deviceId: r.numero},
        );
  }

  Future<List<Bancada>> getAllBancadasOrdered() {
    return (select(bancadas)..orderBy([(b) => OrderingTerm.asc(b.numero)])).get();
  }

  Stream<List<Bancada>> watchAllBancadasOrdered() {
    return (select(bancadas)..orderBy([(b) => OrderingTerm.asc(b.numero)])).watch();
  }

  /// IDs de dispositivo ordenados pelo número da bancada (para filtros).
  Future<List<String>> deviceIdsOrderedByBancada() async {
    final rows = await getAllBancadasOrdered();
    if (rows.isNotEmpty) {
      return rows.map((b) => b.deviceId).toList();
    }
    return distinctDevices();
  }

  /// Popula `SerialCounters` a partir do histórico de seriais aprovados.
  /// O serial tem o formato produto(3)+ano(2)+sequencial(4)+dígito(1).
  Future<void> _backfillSerialCounters() async {
    final rows = await (select(testResults)
          ..where((t) => t.serial.isNotNull()))
        .get();
    final maxByKey = <String, int>{};
    final anoByKey = <String, String>{};
    final produtoByKey = <String, String>{};
    for (final row in rows) {
      final serial = row.serial;
      if (serial == null || serial.length < 9) continue;
      final produto = serial.substring(0, 3);
      final ano = serial.substring(3, 5);
      final seq = int.tryParse(serial.substring(5, 9));
      if (seq == null) continue;
      final key = '$produto|$ano';
      if (seq > (maxByKey[key] ?? 0)) {
        maxByKey[key] = seq;
        anoByKey[key] = ano;
        produtoByKey[key] = produto;
      }
    }
    for (final entry in maxByKey.entries) {
      await into(serialCounters).insertOnConflictUpdate(
        SerialCountersCompanion.insert(
          idProduto: produtoByKey[entry.key]!,
          ano: anoByKey[entry.key]!,
          lastSequencial: entry.value,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<TestResult?> findTestResultBySerial(String serial) {
    return (select(testResults)..where((t) => t.serial.equals(serial)))
        .getSingleOrNull();
  }

  Future<List<TestResult>> searchSerials(String query, {int limit = 10}) {
    return (select(testResults)
          ..where((t) => t.serial.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<List<String>> searchSerialPrefixes(String prefix, {int limit = 50}) async {
    final trimmed = prefix.trim();
    if (trimmed.isEmpty) return [];

    final rows = await (select(testResults)
          ..where((t) => t.serial.isNotNull() & t.serial.like('$trimmed%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    final seen = <String>{};
    final result = <String>[];
    for (final row in rows) {
      final serial = row.serial;
      if (serial == null || seen.contains(serial)) continue;
      seen.add(serial);
      result.add(serial);
      if (result.length >= limit) break;
    }
    return result;
  }

  Future<SirenTraceability?> getTraceabilityBySerial(String serial) async {
    final trimmed = serial.trim();
    if (trimmed.isEmpty) return null;

    final attempts = await (select(testResults)
          ..where((t) => t.serial.equals(trimmed))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    if (attempts.isEmpty) return null;

    Product? product;
    if (trimmed.length >= 3) {
      product = await getProduct(trimmed.substring(0, 3));
    }

    final pendingLabel = await (select(labelBufferEntries)
          ..where((t) => t.serial.equals(trimmed)))
        .getSingleOrNull();

    return SirenTraceability(
      serial: trimmed,
      attempts: attempts,
      product: product,
      pendingLabel: pendingLabel,
    );
  }

  Future<int> insertTestResult({
    required String deviceId,
    required String numeroOp,
    required String veredito,
    required double potenciaMedia,
    required int sequencial,
    required int aprovadosNoLote,
    String? serial,
    String? operador,
    int? tempoTesteSec,
    double? potenciaMin,
    double? potenciaMax,
    int? operatorId,
    bool isRetest = false,
  }) {
    return into(testResults).insert(
      TestResultsCompanion.insert(
        deviceId: deviceId,
        numeroOp: numeroOp,
        veredito: veredito,
        potenciaMedia: potenciaMedia,
        sequencial: sequencial,
        aprovadosNoLote: aprovadosNoLote,
        serial: Value(serial),
        operador: Value(operador),
        tempoTesteSec: Value(tempoTesteSec),
        potenciaMin: Value(potenciaMin),
        potenciaMax: Value(potenciaMax),
        operatorId: Value(operatorId),
        isRetest: Value(isRetest),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<int> insertRemarkLog({
    required String serial,
    required String numeroOp,
    required String mode,
    int? operatorId,
  }) {
    return into(remarkLogs).insert(
      RemarkLogsCompanion.insert(
        serial: serial,
        numeroOp: numeroOp,
        mode: mode,
        operatorId: Value(operatorId),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<TestResult>> getRecentTests({int limit = 50}) {
    return (select(testResults)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<TestResult>> watchTestsByOp(String numeroOp, {int limit = 200}) {
    return (select(testResults)
          ..where((t) => t.numeroOp.equals(numeroOp))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<BatchMetrics> getBatchMetrics(String numeroOp) async {
    final rows = await (select(testResults)..where((t) => t.numeroOp.equals(numeroOp))).get();
    return computeBatchMetrics(rows);
  }

  Future<int> addLabelToBuffer({
    required String serial,
    required String numeroOp,
  }) {
    return into(labelBufferEntries).insert(
      LabelBufferEntriesCompanion.insert(
        serial: serial,
        numeroOp: numeroOp,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<LabelBufferEntry>> getLabelBuffer() {
    return (select(labelBufferEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Stream<List<LabelBufferEntry>> watchLabelBuffer() {
    return (select(labelBufferEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchLabelBufferCount() {
    final count = countAll();
    final query = selectOnly(labelBufferEntries)..addColumns([count]);
    return query.watch().map((rows) => rows.first.read(count) ?? 0);
  }

  Future<void> removeLabelsFromBuffer(List<int> ids) async {
    await (delete(labelBufferEntries)..where((t) => t.id.isIn(ids))).go();
  }

  Future<int> labelBufferCount() async {
    final count = countAll();
    final query = selectOnly(labelBufferEntries)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> addToMarkQueue({
    required String serial,
    required String numeroOp,
    bool pinned = false,
  }) {
    return into(markQueueEntries).insert(
      MarkQueueEntriesCompanion.insert(
        serial: serial,
        numeroOp: numeroOp,
        pinned: Value(pinned),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<MarkQueueEntry?> peekNextPendingMark() {
    return (select(markQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.asc(t.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> markQueueDelivered(int id) async {
    await (update(markQueueEntries)..where((t) => t.id.equals(id))).write(
      MarkQueueEntriesCompanion(
        status: const Value('delivered'),
      ),
    );
  }

  Future<void> markQueueFailed(int id, String error) async {
    final row = await (select(markQueueEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(markQueueEntries)..where((t) => t.id.equals(id))).write(
      MarkQueueEntriesCompanion(
        status: const Value('failed'),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  Future<List<MarkQueueEntry>> getPendingMarkQueue() {
    return (select(markQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Stream<List<MarkQueueEntry>> watchPendingMarkQueue() {
    return (select(markQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Stream<int> watchPendingMarkQueueCount() {
    final count = countAll();
    final query = selectOnly(markQueueEntries)
      ..addColumns([count])
      ..where(markQueueEntries.status.equals('pending'));
    return query.watch().map((rows) => rows.first.read(count) ?? 0);
  }

  Future<void> removeMarkQueueEntry(int id) async {
    await (delete(markQueueEntries)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Product>> watchProducts() {
    return (select(products)..orderBy([(t) => OrderingTerm.asc(t.idProduto)])).watch();
  }

  Future<List<Product>> getProducts() {
    return (select(products)..orderBy([(t) => OrderingTerm.asc(t.idProduto)])).get();
  }

  Future<Product?> getProduct(String idProduto) {
    return (select(products)..where((t) => t.idProduto.equals(idProduto))).getSingleOrNull();
  }

  Future<void> upsertProduct({
    required String idProduto,
    required String nome,
    required double potenciaRef,
    required double potenciaMin,
    required double potenciaMax,
    required double toleranciaPct,
    required int tempoTesteSec,
    DateTime? calibradoEm,
    String? calibradoDeviceId,
  }) async {
    await into(products).insertOnConflictUpdate(
      ProductsCompanion.insert(
        idProduto: idProduto,
        nome: nome,
        potenciaRef: potenciaRef,
        potenciaMin: potenciaMin,
        potenciaMax: potenciaMax,
        toleranciaPct: Value(toleranciaPct),
        tempoTesteSec: Value(tempoTesteSec),
        calibradoEm: Value(calibradoEm),
        calibradoDeviceId: Value(calibradoDeviceId),
      ),
    );
  }

  Future<void> updateProductMetadata({
    required String idProduto,
    required String nome,
    required double toleranciaPct,
    required int tempoTesteSec,
    required double potenciaMin,
    required double potenciaMax,
  }) async {
    await (update(products)..where((t) => t.idProduto.equals(idProduto))).write(
      ProductsCompanion(
        nome: Value(nome),
        toleranciaPct: Value(toleranciaPct),
        tempoTesteSec: Value(tempoTesteSec),
        potenciaMin: Value(potenciaMin),
        potenciaMax: Value(potenciaMax),
      ),
    );
  }

  Future<void> deleteProduct(String idProduto) async {
    await (delete(products)..where((t) => t.idProduto.equals(idProduto))).go();
  }

  Future<int> enqueueSync({
    required String collection,
    required String documentId,
    required String payload,
    required String operation,
    String? documentPath,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        collection: collection,
        documentId: documentId,
        documentPath: Value(documentPath),
        payload: payload,
        operation: operation,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<SyncQueueData>> getPendingItems({int limit = 50}) {
    return (select(syncQueue)
          ..where((t) => t.attempts.isSmallerThanValue(5))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> markSynced(int id) async {
    await (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markFailed(int id, String error, {required int attempts}) async {
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        attempts: Value(attempts),
        lastError: Value(error),
      ),
    );
  }

  Future<int> countPending() async {
    final total = countAll();
    final query = selectOnly(syncQueue)
      ..addColumns([total])
      ..where(syncQueue.attempts.isSmallerThanValue(5));
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  Future<int> countFailed() async {
    final total = countAll();
    final query = selectOnly(syncQueue)
      ..addColumns([total])
      ..where(syncQueue.attempts.isBiggerOrEqualValue(5));
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  Future<List<SyncQueueData>> getFailedSyncItems({int limit = 50}) {
    return (select(syncQueue)
          ..where((t) => t.attempts.isBiggerOrEqualValue(5))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> resetSyncAttempts(int id) async {
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      const SyncQueueCompanion(
        attempts: Value(0),
        lastError: Value(null),
      ),
    );
  }

  Future<int> resetAllFailedSyncAttempts() async {
    final failed = await getFailedSyncItems();
    for (final item in failed) {
      await resetSyncAttempts(item.id);
    }
    return failed.length;
  }

  Future<int> insertHardwareEvent({
    required String deviceId,
    required String falha,
  }) {
    return into(hardwareEvents).insert(
      HardwareEventsCompanion.insert(
        deviceId: deviceId,
        falha: falha,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<HardwareEvent>> recentHardwareEvents({int limit = 20}) {
    return (select(hardwareEvents)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  Future<int> insertCalibration({
    required String idProduto,
    required double potenciaRef,
    String? deviceId,
  }) {
    return into(calibrationHistory).insert(
      CalibrationHistoryCompanion.insert(
        idProduto: idProduto,
        potenciaRef: potenciaRef,
        deviceId: Value(deviceId),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<CalibrationHistoryData>> getCalibrationHistory(String idProduto) {
    return (select(calibrationHistory)
          ..where((t) => t.idProduto.equals(idProduto))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  Stream<List<CalibrationHistoryData>> watchCalibrationHistory(String idProduto) {
    return (select(calibrationHistory)
          ..where((t) => t.idProduto.equals(idProduto))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Stream<List<Operator>> watchActiveOperators() {
    return (select(operators)
          ..where((t) => t.ativo.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.nome)]))
        .watch();
  }

  Stream<List<Operator>> watchAllOperators() {
    return (select(operators)..orderBy([(t) => OrderingTerm.asc(t.nome)])).watch();
  }

  Future<Operator?> getOperatorById(int id) {
    return (select(operators)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> operatorCodigoExists(String codigo, {int? excludeId}) async {
    final query = select(operators)..where((t) => t.codigo.equals(codigo.trim()));
    if (excludeId != null) {
      query.where((t) => t.id.equals(excludeId).not());
    }
    final row = await query.getSingleOrNull();
    return row != null;
  }

  Future<int> insertOperator({
    required String codigo,
    required String nome,
    bool ativo = true,
    bool isGestor = false,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return into(operators).insert(
      OperatorsCompanion.insert(
        codigo: codigo.trim(),
        nome: nome.trim(),
        ativo: Value(ativo),
        isGestor: Value(isGestor),
        createdAt: now,
        updatedAt: Value(updatedAt ?? now),
      ),
    );
  }

  Future<void> updateOperator({
    required int id,
    required String codigo,
    required String nome,
    required bool ativo,
    bool? isGestor,
    DateTime? updatedAt,
  }) {
    return (update(operators)..where((t) => t.id.equals(id))).write(
      OperatorsCompanion(
        codigo: Value(codigo.trim()),
        nome: Value(nome.trim()),
        ativo: Value(ativo),
        isGestor: isGestor == null ? const Value.absent() : Value(isGestor),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }

  Future<List<Operator>> getAllOperators() {
    return (select(operators)..orderBy([(t) => OrderingTerm.asc(t.nome)])).get();
  }

  Future<void> upsertOperatorFromCloud({
    required String codigo,
    required String nome,
    required bool ativo,
    bool isGestor = false,
    required DateTime updatedAt,
  }) async {
    final existing = await (select(operators)
          ..where((t) => t.codigo.equals(codigo.trim())))
        .getSingleOrNull();
    if (existing != null) {
      await updateOperator(
        id: existing.id,
        codigo: codigo,
        nome: nome,
        ativo: ativo,
        isGestor: isGestor,
        updatedAt: updatedAt,
      );
      return;
    }
    await insertOperator(
      codigo: codigo,
      nome: nome,
      ativo: ativo,
      isGestor: isGestor,
      updatedAt: updatedAt,
    );
  }

  /// Rótulo legível para rastreio em testes.
  static String operatorLabel(Operator op) => '${op.codigo} — ${op.nome}';

  Future<void> lockOp(String numeroOp) async {
    await into(opLocks).insertOnConflictUpdate(
      OpLocksCompanion.insert(
        numeroOp: numeroOp,
        status: 'completed',
        lockedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> isOpLocked(String numeroOp) async {
    final row = await (select(opLocks)..where((t) => t.numeroOp.equals(numeroOp)))
        .getSingleOrNull();
    return row != null;
  }

  Future<List<TestResult>> testResultsFiltered({
    DateTime? since,
    String? numeroOp,
    String? idProduto,
    String? deviceId,
  }) async {
    final query = select(testResults);
    if (since != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(since));
    }
    if (numeroOp != null && numeroOp.isNotEmpty) {
      query.where((t) => t.numeroOp.equals(numeroOp));
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      query.where((t) => t.deviceId.equals(deviceId));
    }
    final rows = await query.get();
    if (idProduto == null || idProduto.isEmpty) return rows;
    final prefix = idProduto.padLeft(3, '0').substring(0, 3);
    return rows
        .where((r) =>
            r.serial != null && r.serial!.length >= 3 && r.serial!.startsWith(prefix))
        .toList();
  }

  Future<List<String>> distinctOps() async {
    final rows = await select(testResults).get();
    return rows.map((r) => r.numeroOp).toSet().toList()..sort();
  }

  Future<List<String>> distinctDevices() async {
    final rows = await select(testResults).get();
    return rows.map((r) => r.deviceId).toSet().toList()..sort();
  }

  Future<List<String>> distinctProducts() async {
    final fromSerials = <String>{};
    final rows = await select(testResults).get();
    for (final r in rows) {
      final serial = r.serial;
      if (serial != null && serial.length >= 3) {
        fromSerials.add(serial.substring(0, 3));
      }
    }
    final counters = await select(serialCounters).get();
    for (final c in counters) {
      fromSerials.add(c.idProduto.padLeft(3, '0').substring(0, 3));
    }
    final productRows = await select(products).get();
    for (final p in productRows) {
      fromSerials.add(p.idProduto.padLeft(3, '0').substring(0, 3));
    }
    return fromSerials.toList()..sort();
  }

  Future<ProductionSummary> productionSummary({
    DateTime? since,
    String? numeroOp,
    String? idProduto,
    String? deviceId,
  }) async {
    final rows = await testResultsFiltered(
      since: since,
      numeroOp: numeroOp,
      idProduto: idProduto,
      deviceId: deviceId,
    );
    var aprovados = 0;
    for (final r in rows) {
      if (isApprovedVeredito(r.veredito)) aprovados++;
    }
    return ProductionSummary(total: rows.length, aprovados: aprovados);
  }

  Future<List<BatchProductionSummary>> batchSummaryInPeriod({
    DateTime? since,
    String? idProduto,
    String? deviceId,
  }) async {
    final rows = await testResultsFiltered(
      since: since,
      idProduto: idProduto,
      deviceId: deviceId,
    );
    final byOp = <String, ({int total, int aprovados, DateTime? lastAt})>{};
    for (final r in rows) {
      final current = byOp[r.numeroOp] ?? (total: 0, aprovados: 0, lastAt: null);
      final lastAt = current.lastAt == null || r.createdAt.isAfter(current.lastAt!)
          ? r.createdAt
          : current.lastAt;
      byOp[r.numeroOp] = (
        total: current.total + 1,
        aprovados: current.aprovados + (isApprovedVeredito(r.veredito) ? 1 : 0),
        lastAt: lastAt,
      );
    }
    final result = byOp.entries
        .map(
          (e) => BatchProductionSummary(
            numeroOp: e.key,
            total: e.value.total,
            aprovados: e.value.aprovados,
            lastTestAt: e.value.lastAt,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  Future<List<BatchReportSummary>> batchReportSummaries({
    DateTime? since,
    String? idProduto,
    String? deviceId,
    String? opContains,
  }) async {
    var rows = await testResultsFiltered(
      since: since,
      idProduto: idProduto,
      deviceId: deviceId,
    );
    if (opContains != null && opContains.trim().isNotEmpty) {
      final q = opContains.trim().toUpperCase();
      rows = rows.where((r) => r.numeroOp.toUpperCase().contains(q)).toList();
    }

    final byOp = <String, List<TestResult>>{};
    for (final r in rows) {
      byOp.putIfAbsent(r.numeroOp, () => []).add(r);
    }

    final result = <BatchReportSummary>[];
    for (final entry in byOp.entries) {
      final tests = entry.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      var aprovados = 0;
      for (final t in tests) {
        if (isApprovedVeredito(t.veredito)) aprovados++;
      }
      result.add(
        BatchReportSummary(
          numeroOp: entry.key,
          total: tests.length,
          aprovados: aprovados,
          firstTestAt: tests.first.createdAt,
          lastTestAt: tests.last.createdAt,
        ),
      );
    }
    result.sort((a, b) {
      final aDate = a.lastTestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastTestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return result;
  }

  Future<List<TestResult>> testsForOp(
    String numeroOp, {
    DateTime? since,
    String? idProduto,
    String? deviceId,
    bool? approvedOnly,
  }) async {
    var rows = await testResultsFiltered(
      since: since,
      numeroOp: numeroOp,
      idProduto: idProduto,
      deviceId: deviceId,
    );
    if (approvedOnly != null) {
      rows = rows
          .where((r) => approvedOnly ? isApprovedVeredito(r.veredito) : !isApprovedVeredito(r.veredito))
          .toList();
    }
    rows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return rows;
  }

  Future<List<DailyThroughput>> throughputByDay({
    required DateTime since,
    required int days,
    String? numeroOp,
    String? idProduto,
    String? deviceId,
  }) async {
    final start = DateTime(since.year, since.month, since.day);
    final rows = await testResultsFiltered(
      since: start,
      numeroOp: numeroOp,
      idProduto: idProduto,
      deviceId: deviceId,
    );

    final byDay = <DateTime, ({int total, int aprovados})>{};
    for (final r in rows) {
      final local = r.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final current = byDay[day] ?? (total: 0, aprovados: 0);
      byDay[day] = (
        total: current.total + 1,
        aprovados: current.aprovados + (isApprovedVeredito(r.veredito) ? 1 : 0),
      );
    }

    final result = <DailyThroughput>[];
    for (var i = 0; i < days; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final entry = byDay[day] ?? (total: 0, aprovados: 0);
      result.add(DailyThroughput(day: day, total: entry.total, aprovados: entry.aprovados));
    }
    return result;
  }

  Future<List<FaultCount>> hardwareFaultCounts({
    DateTime? since,
    String? deviceId,
  }) async {
    final query = select(hardwareEvents);
    if (since != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(since));
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      query.where((t) => t.deviceId.equals(deviceId));
    }
    final rows = await query.get();
    final counts = <String, int>{};
    for (final r in rows) {
      counts[r.falha] = (counts[r.falha] ?? 0) + 1;
    }
    final result = counts.entries.map((e) => FaultCount(falha: e.key, count: e.value)).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  Future<int?> getLastSequencial(String idProduto, String ano) async {
    final row = await (select(serialCounters)
          ..where((t) => t.idProduto.equals(idProduto) & t.ano.equals(ano)))
        .getSingleOrNull();
    return row?.lastSequencial;
  }

  /// Próximo sequencial sugerido: último + 1, ou 1 se não houver histórico.
  Future<int> nextSequencialFor(String idProduto, String ano) async {
    final last = await getLastSequencial(idProduto, ano);
    return (last ?? 0) + 1;
  }

  /// Atualiza o contador para max(atual, sequencial). Idempotente.
  Future<void> bumpSerialCounter({
    required String idProduto,
    required String ano,
    required int sequencial,
  }) async {
    await transaction(() async {
      final current = await getLastSequencial(idProduto, ano);
      final next = current == null ? sequencial : (sequencial > current ? sequencial : current);
      await into(serialCounters).insertOnConflictUpdate(
        SerialCountersCompanion.insert(
          idProduto: idProduto,
          ano: ano,
          lastSequencial: next,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<bool> serialExists(String serial) async {
    final row = await (select(testResults)..where((t) => t.serial.equals(serial)))
        .getSingleOrNull();
    if (row != null) return true;
    final buffered = await (select(labelBufferEntries)..where((t) => t.serial.equals(serial)))
        .getSingleOrNull();
    return buffered != null;
  }

  /// Reconciliação dos sequenciais aprovados de um produto/ano.
  Future<SerialReconciliation> reconcileSerials(String idProduto, String ano) async {
    final prefix = '$idProduto$ano';
    final rows = await (select(testResults)..where((t) => t.serial.like('$prefix%'))).get();

    final seqCount = <int, int>{};
    for (final row in rows) {
      if (!isApprovedVeredito(row.veredito)) continue;
      final serial = row.serial;
      if (serial == null || serial.length < 9) continue;
      final seq = int.tryParse(serial.substring(5, 9));
      if (seq == null) continue;
      seqCount[seq] = (seqCount[seq] ?? 0) + 1;
    }

    if (seqCount.isEmpty) {
      return const SerialReconciliation(found: [], gaps: [], duplicates: []);
    }

    final found = seqCount.keys.toList()..sort();
    final duplicates = (seqCount.entries.where((e) => e.value > 1).map((e) => e.key).toList())
      ..sort();
    final gaps = <int>[];
    for (var s = found.first; s <= found.last; s++) {
      if (!seqCount.containsKey(s)) gaps.add(s);
    }
    return SerialReconciliation(found: found, gaps: gaps, duplicates: duplicates);
  }
}

class SerialReconciliation {
  const SerialReconciliation({
    required this.found,
    required this.gaps,
    required this.duplicates,
  });

  final List<int> found;
  final List<int> gaps;
  final List<int> duplicates;

  bool get isIntact => gaps.isEmpty && duplicates.isEmpty;
}

class ProductionSummary {
  const ProductionSummary({required this.total, required this.aprovados});

  final int total;
  final int aprovados;

  int get reprovados => total - aprovados;

  /// Yield em porcentagem (0–100). 0 quando não há testes.
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
}

class FaultCount {
  const FaultCount({required this.falha, required this.count});

  final String falha;
  final int count;
}

class BatchProductionSummary {
  const BatchProductionSummary({
    required this.numeroOp,
    required this.total,
    required this.aprovados,
    this.lastTestAt,
  });

  final String numeroOp;
  final int total;
  final int aprovados;
  final DateTime? lastTestAt;

  int get reprovados => total - aprovados;

  double get yieldPct => total == 0 ? 0 : (aprovados / total) * 100;
}

class BatchReportSummary extends BatchProductionSummary {
  const BatchReportSummary({
    required super.numeroOp,
    required super.total,
    required super.aprovados,
    this.firstTestAt,
    this.lastTestAt,
  });

  final DateTime? firstTestAt;
  final DateTime? lastTestAt;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final file = await AppDatabase.dbFile();
    return NativeDatabase.createInBackground(file);
  });
}
