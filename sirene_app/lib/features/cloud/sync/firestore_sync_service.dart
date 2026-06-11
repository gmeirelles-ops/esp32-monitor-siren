import 'dart:convert';

import '../../../core/database/database.dart';
import '../../mqtt/models/mqtt_messages.dart';
import '../models/firestore_mappers.dart';
import 'device_update_debouncer.dart';

typedef SyncEnabledGetter = bool Function();
typedef StationIdGetter = String Function();

class FirestoreSyncService {
  FirestoreSyncService({
    required AppDatabase db,
    required SyncEnabledGetter isSyncEnabled,
    required StationIdGetter stationId,
    DeviceUpdateDebouncer? debouncer,
  })  : _db = db,
        _isSyncEnabled = isSyncEnabled,
        _stationId = stationId,
        _debouncer = debouncer ?? DeviceUpdateDebouncer();

  final AppDatabase _db;
  final SyncEnabledGetter _isSyncEnabled;
  final StationIdGetter _stationId;
  final DeviceUpdateDebouncer _debouncer;

  final Map<String, Map<String, dynamic>> _pendingDevices = {};

  bool get isActive => _isSyncEnabled();

  Future<void> enqueueTestResult({
    required String deviceId,
    required TestResultMessage test,
    String? serial,
    String? operador,
  }) async {
    if (!isActive) return;
    final payload = mapTestResult(
      deviceId: deviceId,
      test: test,
      serial: serial,
      operador: operador,
      stationId: _stationId(),
      timestamp: DateTime.now(),
    );
    await _db.enqueueSync(
      collection: 'test_results',
      documentId: testResultDocumentId(test.numeroOp, test.sequencial),
      payload: jsonEncode(payload),
      operation: 'set',
    );
  }

  Future<void> enqueueDeviceUpdate({
    required String deviceId,
    required DeviceFsmState estado,
    required String firmwareVersion,
    required int rssi,
    required int filaOffline,
    required bool online,
    bool force = false,
  }) async {
    if (!isActive) return;

    final payload = mapDevice(
      deviceId: deviceId,
      estado: estado,
      firmwareVersion: firmwareVersion,
      rssi: rssi,
      filaOffline: filaOffline,
      online: online,
      stationId: _stationId(),
      lastSeen: DateTime.now(),
    );

    if (!force && !_debouncer.shouldSendNow(deviceId)) {
      _pendingDevices[deviceId] = payload;
      return;
    }

    _pendingDevices.remove(deviceId);
    _debouncer.recordSent(deviceId);
    await _db.enqueueSync(
      collection: 'devices',
      documentId: deviceId,
      payload: jsonEncode(payload),
      operation: 'merge',
    );
  }

  Future<void> flushPendingDeviceUpdates() async {
    if (!isActive || _pendingDevices.isEmpty) return;
    for (final entry in _pendingDevices.entries.toList()) {
      if (_debouncer.shouldSendNow(entry.key)) {
        _debouncer.recordSent(entry.key);
        await _db.enqueueSync(
          collection: 'devices',
          documentId: entry.key,
          payload: jsonEncode(entry.value),
          operation: 'merge',
        );
        _pendingDevices.remove(entry.key);
      }
    }
  }

  Future<void> enqueueBatch({
    required BatchConfig batch,
    required String deviceId,
    required String status,
    required DateTime startedAt,
    DateTime? endedAt,
    int? aprovados,
  }) async {
    if (!isActive) return;
    final payload = mapBatch(
      batch: batch,
      deviceId: deviceId,
      status: status,
      stationId: _stationId(),
      startedAt: startedAt,
      endedAt: endedAt,
      aprovados: aprovados,
    );
    await _db.enqueueSync(
      collection: 'batches',
      documentId: batch.numeroOp,
      payload: jsonEncode(payload),
      operation: 'set',
    );
  }

  Future<void> enqueueProduct(Product product) async {
    if (!isActive) return;
    await _enqueueProductToQueue(product);
  }

  /// Reenvia todo o catálogo local (ex.: cadastro feito antes de habilitar sync).
  Future<int> syncAllProducts() async {
    if (!isActive) return 0;
    final products = await _db.getProducts();
    for (final product in products) {
      await _enqueueProductToQueue(product);
    }
    return products.length;
  }

  Future<void> _enqueueProductToQueue(Product product) async {
    final payload = mapProduct(product: product, updatedAt: DateTime.now());
    await _db.enqueueSync(
      collection: 'products',
      documentId: product.idProduto,
      payload: jsonEncode(payload),
      operation: 'set',
    );
  }
}
