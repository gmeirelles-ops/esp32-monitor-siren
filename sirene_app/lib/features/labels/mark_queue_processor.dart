import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import 'diatu_laser_tcp_server.dart';
import 'laser_tcp_diagnostics.dart';
import 'serial_marking_backend.dart';

/// Mantém o servidor TCP Diatu ativo e atende pedidos de serial da fila.
class MarkQueueProcessor {
  MarkQueueProcessor({
    required AppDatabase db,
    required AppConfig Function() readConfig,
    this.healthCheckInterval = const Duration(seconds: 10),
    LaserTcpEventLog? eventLog,
  })  : _db = db,
        _readConfig = readConfig,
        eventLog = eventLog ?? LaserTcpEventLog();

  final AppDatabase _db;
  final AppConfig Function() _readConfig;
  final Duration healthCheckInterval;
  final LaserTcpEventLog eventLog;

  SerialMarkingBackend? _backend;
  Timer? _timer;
  int? _runningPort;
  String? _runningCommand;
  String? lastError;

  bool get isServerRunning => _backend?.isRunning ?? false;

  int? get activePort => _runningPort;

  void start() {
    _timer ??= Timer.periodic(healthCheckInterval, (_) => ensureRunning());
    unawaited(ensureRunning());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    unawaited(_backend?.stop());
    _backend = null;
    _runningPort = null;
    _runningCommand = null;
  }

  Future<void> ensureRunning() async {
    final config = _readConfig();
    if (config.markingMode != MarkingMode.laser) {
      if (_backend != null) {
        await _backend!.stop();
        _backend = null;
        _runningPort = null;
        _runningCommand = null;
      }
      return;
    }

    if (_backend != null &&
        _runningPort == config.laserTcpPort &&
        _runningCommand == config.laserTcpCommand &&
        _backend!.isRunning) {
      return;
    }

    await _backend?.stop();
    _backend = DiatuLaserTcpServer(
      port: config.laserTcpPort,
      commandPrefix: config.laserTcpCommand,
      onRequestSerial: _serveNextSerial,
      eventLog: eventLog,
    );
    try {
      await _backend!.start();
      _runningPort = config.laserTcpPort;
      _runningCommand = config.laserTcpCommand;
      lastError = null;
    } catch (e) {
      lastError = formatMarkingError(e);
      _backend = null;
      _runningPort = null;
      _runningCommand = null;
      rethrow;
    }
  }

  Future<String?> _serveNextSerial() async {
    final entry = await _db.peekNextPendingMark();
    if (entry == null) return null;
    await _db.markQueueDelivered(entry.id);
    return entry.serial;
  }

  /// Enfileira serial de teste na frente da fila (Configurações).
  Future<void> enqueueTestSerial(String serial) async {
    await _db.addToMarkQueue(
      serial: serial,
      numeroOp: 'TEST',
      pinned: true,
    );
  }

  /// Regravação manual: serial vai para a frente da fila.
  Future<void> enqueueRemark(String serial, String numeroOp) async {
    await _db.addToMarkQueue(
      serial: serial,
      numeroOp: numeroOp,
      pinned: true,
    );
  }

  /// Simula cliente DiatuCAD contra o servidor local.
  Future<String> simulateDiatuClient() async {
    final config = _readConfig();
    await ensureRunning();
    return simulateDiatuTcpClient(
      port: config.laserTcpPort,
      command: config.laserTcpCommand,
    );
  }
}
