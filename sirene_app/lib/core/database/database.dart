import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

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
  DateTimeColumn get createdAt => dateTime()();
}

class LabelBufferEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serial => text()();
  TextColumn get numeroOp => text()();
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
  TextColumn get payload => text()();
  TextColumn get operation => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(tables: [TestResults, LabelBufferEntries, Products, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

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
        },
      );

  Future<int> insertTestResult({
    required String deviceId,
    required String numeroOp,
    required String veredito,
    required double potenciaMedia,
    required int sequencial,
    required int aprovadosNoLote,
    String? serial,
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

  Future<void> removeLabelsFromBuffer(List<int> ids) async {
    await (delete(labelBufferEntries)..where((t) => t.id.isIn(ids))).go();
  }

  Future<int> labelBufferCount() async {
    final count = countAll();
    final query = selectOnly(labelBufferEntries)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
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
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        collection: collection,
        documentId: documentId,
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sirene_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
