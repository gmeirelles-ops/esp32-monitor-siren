import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/database/database.dart';
import '../../core/services/app_log.dart';
import '../serial/itf_check_digit.dart';
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
  String? _runningModelCommand;
  String? _lastDeliveredSerial;
  String? lastError;

  bool get isServerRunning => _backend?.isRunning ?? false;

  int? get activePort => _runningPort;

  void start() {
    _timer ??= Timer.periodic(healthCheckInterval, (_) => _safeEnsureRunning());
    unawaited(_safeEnsureRunning());
  }

  Future<void> _safeEnsureRunning() async {
    try {
      await ensureRunning();
    } catch (e) {
      lastError = formatMarkingError(e);
      unawaited(AppLog.write('Laser TCP: $lastError'));
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    unawaited(_backend?.stop());
    _backend = null;
    _runningPort = null;
    _runningCommand = null;
    _runningModelCommand = null;
  }

  Future<void> ensureRunning() async {
    final config = _readConfig();
    if (config.markingMode != MarkingMode.laser) {
      if (_backend != null) {
        await _backend!.stop();
        _backend = null;
        _runningPort = null;
        _runningCommand = null;
        _runningModelCommand = null;
      }
      return;
    }

    if (_backend != null &&
        _runningPort == config.laserTcpPort &&
        _runningCommand == config.laserTcpCommand &&
        _runningModelCommand == config.laserModelCommand &&
        _backend!.isRunning) {
      return;
    }

    await _backend?.stop();
    _backend = DiatuLaserTcpServer(
      port: config.laserTcpPort,
      commandPrefix: config.laserTcpCommand,
      modelCommandPrefix: config.laserModelCommand,
      onRequestSerial: _serveNextSerial,
      onRequestModel: _serveModel,
      eventLog: eventLog,
    );
    try {
      await _backend!.start();
      _runningPort = config.laserTcpPort;
      _runningCommand = config.laserTcpCommand;
      _runningModelCommand = config.laserModelCommand;
      lastError = null;
    } catch (e) {
      lastError = formatMarkingError(e);
      _backend = null;
      _runningPort = null;
      _runningCommand = null;
      _runningModelCommand = null;
    }
  }

  Future<String?> _serveNextSerial() async {
    final entry = await _db.peekNextPendingMark();
    if (entry == null) return null;
    await _db.markQueueDelivered(entry.id);
    _lastDeliveredSerial = entry.serial;
    return entry.serial;
  }

  Future<String?> _serveModel() async {
    final pending = await _db.peekNextPendingMark();
    final serial = pending?.serial ?? _lastDeliveredSerial;
    if (serial == null || serial.isEmpty) return null;

    final idProduto = extractIdProdutoFromSerial(serial);
    if (idProduto == null) return null;

    final product = await _db.getProduct(idProduto);
    final nome = product?.nome.trim();
    if (nome == null || nome.isEmpty) return null;
    return nome;
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

  /// Simula cliente DiatuCAD contra o servidor local (comando serial).
  Future<String> simulateDiatuClient() async {
    final config = _readConfig();
    await ensureRunning();
    return simulateDiatuTcpClient(
      port: config.laserTcpPort,
      command: config.laserTcpCommand,
    );
  }

  /// Simula cliente DiatuCAD pedindo o nome do modelo.
  Future<String> simulateDiatuModelClient() async {
    final config = _readConfig();
    await ensureRunning();
    return simulateDiatuTcpClient(
      port: config.laserTcpPort,
      command: config.laserModelCommand,
    );
  }
}
