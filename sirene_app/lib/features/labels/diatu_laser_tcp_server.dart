import 'dart:async';
import 'dart:io';

import 'laser_tcp_diagnostics.dart';
import 'serial_marking_backend.dart';

/// Servidor TCP para DiatuCAD/EzCad (texto variável).
/// O laser conecta, envia o comando configurado e recebe o serial ITF.
class DiatuLaserTcpServer implements SerialMarkingBackend {
  DiatuLaserTcpServer({
    required this.port,
    required this.commandPrefix,
    required this.onRequestSerial,
    this.eventLog,
    this.connectionTimeout = const Duration(seconds: 10),
  });

  final int port;
  final String commandPrefix;
  final Future<String?> Function() onRequestSerial;
  final LaserTcpEventLog? eventLog;
  final Duration connectionTimeout;

  ServerSocket? _server;
  final _clients = <Socket>{};

  @override
  bool get isRunning => _server != null;

  int? get boundPort => _server?.port;

  @override
  String get modeDescription => 'Laser Diatu TCP :$port';

  @override
  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } on SocketException catch (e) {
      throw StateError(formatLaserPortInUseError(port, e.message));
    }
    _server!.listen(_onConnection, onError: (_) {}, cancelOnError: false);
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    for (final client in _clients.toList()) {
      await client.close();
    }
    _clients.clear();
    await server?.close();
  }

  Future<void> _onConnection(Socket client) async {
    _clients.add(client);
    final remote = '${client.remoteAddress.address}:${client.remotePort}';
    final requestBuffer = <int>[];
    final requestDone = Completer<void>();
    late final StreamSubscription<List<int>> requestSub;
    requestSub = client.listen(
      (data) {
        requestBuffer.addAll(data);
        if (!requestDone.isCompleted) requestDone.complete();
      },
    );

    String? requestText;
    String? response;
    String? error;

    try {
      try {
        await requestDone.future.timeout(connectionTimeout);
      } on TimeoutException {
        // Cliente não enviou comando a tempo.
      }
      await requestSub.cancel();

      requestText = requestBuffer.isEmpty ? '' : String.fromCharCodes(requestBuffer);
      if (!matchesDiatuTcpCommand(requestText, commandPrefix)) {
        response = 'ERROR:BADCMD';
        client.write(response);
        await client.flush();
        return;
      }

      final serial = await onRequestSerial();
      response = serial ?? kMarkQueueEmptyResponse;
      client.write(response);
      await client.flush();
    } catch (e) {
      error = 'ERROR:SERVER';
      response = error;
      try {
        client.write(error);
        await client.flush();
      } catch (_) {}
    } finally {
      eventLog?.record(LaserTcpEvent(
        at: DateTime.now(),
        remote: remote,
        request: requestText,
        response: response,
        error: error,
      ));
      _clients.remove(client);
      await client.close();
    }
  }

}

/// Compara comando recebido do DiatuCAD com o prefixo configurado.
bool matchesDiatuTcpCommand(String request, String commandPrefix) {
  final normalized = normalizeTcpPayload(request);
  if (normalized.isEmpty) return false;
  final prefix = normalizeTcpPayload(commandPrefix);
  if (prefix.isEmpty) return true;
  return normalized.contains(prefix);
}
