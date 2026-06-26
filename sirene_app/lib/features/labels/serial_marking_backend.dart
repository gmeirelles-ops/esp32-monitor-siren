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
  required Future<String?> Function() onRequestSerial,
}) {
  return DiatuLaserTcpServer(
    port: port,
    commandPrefix: commandPrefix,
    onRequestSerial: onRequestSerial,
  );
}

SerialMarkingBackend createSerialMarkingBackendFromConfig(
  AppConfig config, {
  required Future<String?> Function() onRequestSerial,
}) {
  return createDiatuLaserBackend(
    port: config.laserTcpPort,
    commandPrefix: config.laserTcpCommand,
    onRequestSerial: onRequestSerial,
  );
}

String formatMarkingError(Object error) => 'Erro na gravação laser: $error';

const kMarkQueueEmptyResponse = 'ERROR:EMPTY';
