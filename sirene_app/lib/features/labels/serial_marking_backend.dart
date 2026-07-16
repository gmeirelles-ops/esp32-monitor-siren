import '../../core/config/app_config.dart';
import 'diatu_laser_tcp_server.dart';

/// Backend de marcação física do serial (Zebra ZPL ou laser DiatuCAD).
abstract class SerialMarkingBackend {
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
  String get modeDescription;
}

SerialMarkingBackend createDiatuLaserBackend({
  required int port,
  required String commandPrefix,
  required String modelCommandPrefix,
  required String manualCommandPrefix,
  required Future<String?> Function() onRequestSerial,
  required Future<String?> Function() onRequestModel,
  required Future<String?> Function() onRequestManual,
}) {
  return DiatuLaserTcpServer(
    port: port,
    commandPrefix: commandPrefix,
    modelCommandPrefix: modelCommandPrefix,
    manualCommandPrefix: manualCommandPrefix,
    onRequestSerial: onRequestSerial,
    onRequestModel: onRequestModel,
    onRequestManual: onRequestManual,
  );
}

SerialMarkingBackend createSerialMarkingBackendFromConfig(
  AppConfig config, {
  required Future<String?> Function() onRequestSerial,
  required Future<String?> Function() onRequestModel,
  required Future<String?> Function() onRequestManual,
}) {
  return createDiatuLaserBackend(
    port: config.laserTcpPort,
    commandPrefix: config.laserTcpCommand,
    modelCommandPrefix: config.laserModelCommand,
    manualCommandPrefix: config.laserManualCommand,
    onRequestSerial: onRequestSerial,
    onRequestModel: onRequestModel,
    onRequestManual: onRequestManual,
  );
}

String formatMarkingError(Object error) => 'Erro na gravação laser: $error';

const kMarkQueueEmptyResponse = 'ERROR:EMPTY';
