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
    this.inProgressTimeout = const Duration(minutes: 5),
    LaserTcpEventLog? eventLog,
  }) : _db = db,
       _readConfig = readConfig,
       eventLog = eventLog ?? LaserTcpEventLog();

  final AppDatabase _db;
  final AppConfig Function() _readConfig;
  final Duration healthCheckInterval;
  final Duration inProgressTimeout;
  final LaserTcpEventLog eventLog;

  SerialMarkingBackend? _backend;
  Timer? _timer;
  int? _runningPort;
  String? _runningCommand;
  String? _runningModelCommand;
  String? _lastDeliveredSerial;
  int? _activeMarkId;
  DateTime? _activeMarkStartedAt;
  bool _recoveredInterrupted = false;
  String? lastError;

  bool get isServerRunning => _backend?.isRunning ?? false;

  int? get activePort => _runningPort;

  void start() {
    _timer ??= Timer.periodic(healthCheckInterval, (_) => _safeEnsureRunning());
    unawaited(_safeEnsureRunning());
  }

  Future<void> _safeEnsureRunning() async {
    try {
      if (!_recoveredInterrupted) {
        _recoveredInterrupted = true;
        final requeued = await _db.requeueAllInProgressMarks();
        if (requeued > 0) {
          _activeMarkId = null;
          _activeMarkStartedAt = null;
          await AppLog.write(
            'Laser: recuperou $requeued marcação(ões) interrompida(s)',
          );
        }
      }
      if (_activeMarkId != null && _activeMarkStartedAt != null) {
        final elapsed = DateTime.now().difference(_activeMarkStartedAt!);
        if (elapsed > inProgressTimeout) {
          await _db.markQueueRequeue(_activeMarkId!);
          await AppLog.write(
            'Laser: marcação expirou sem confirmação',
          );
          _activeMarkId = null;
          _activeMarkStartedAt = null;
        }
      }
      await ensureRunning();
    } catch (e) {
      lastError = formatMarkingError(e);
      unawaited(AppLog.write('Laser TCP: $lastError'));
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    final backend = _backend;
    _backend = null;
    _runningPort = null;
    _runningCommand = null;
    _runningModelCommand = null;
    if (backend != null) {
      unawaited(backend.stop().catchError((_) {}));
    }
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

  /// Entrega o próximo serial e conclui a fila na mesma operação.
  Future<String?> _serveNextSerial() async {
    final entry = await _db.peekNextPendingMark();
    if (entry == null) return null;
    _lastDeliveredSerial = entry.serial;
    await _db.markQueueDelivered(entry.id);
    return entry.serial;
  }

  /// Resolve o nome do produto; não altera status da fila.
  Future<String?> _serveModel() async {
    final serial = _lastDeliveredSerial;
    if (serial == null || serial.isEmpty) {
      final inProgress = await _db.peekInProgressMark();
      final fallback = inProgress?.serial;
      if (fallback == null || fallback.isEmpty) return null;
      return _productNameForSerial(fallback);
    }
    return _productNameForSerial(serial);
  }

  Future<String?> _productNameForSerial(String serial) async {
    final idProduto = extractIdProdutoFromSerial(serial);
    if (idProduto == null) return null;
    final product = await _db.getProduct(idProduto);
    final nome = product?.nome.trim();
    if (nome == null || nome.isEmpty) return null;
    return nome;
  }

  /// Enfileira serial de teste na frente da fila (Configurações).
  Future<void> enqueueTestSerial(String serial) async {
    await _db.addToMarkQueue(serial: serial, numeroOp: 'TEST', pinned: true);
  }

  /// Regravação: serial vai para a frente da fila.
  Future<void> enqueueRemark(String serial, String numeroOp) async {
    await _db.addToMarkQueue(serial: serial, numeroOp: numeroOp, pinned: true);
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
