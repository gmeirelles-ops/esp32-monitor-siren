import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'laser_tcp_diagnostics.dart';
import 'serial_marking_backend.dart';

/// Rota de um comando TCP recebido do DiatuCAD.
enum DiatuTcpRoute { serial, model, manual, bad }

/// Servidor TCP para DiatuCAD/EzCad (texto variável).
/// O laser conecta e recebe serial, modelo ou manual do produto.
class DiatuLaserTcpServer implements SerialMarkingBackend {
  DiatuLaserTcpServer({
    required this.port,
    required this.commandPrefix,
    required this.modelCommandPrefix,
    required this.manualCommandPrefix,
    required this.onRequestSerial,
    required this.onRequestModel,
    required this.onRequestManual,
    this.eventLog,
    this.connectionTimeout = const Duration(seconds: 10),
  });

  final int port;
  final String commandPrefix;
  final String modelCommandPrefix;
  final String manualCommandPrefix;
  final Future<String?> Function() onRequestSerial;
  final Future<String?> Function() onRequestModel;
  final Future<String?> Function() onRequestManual;
  final LaserTcpEventLog? eventLog;
  final Duration connectionTimeout;

  ServerSocket? _server;
  final _clients = <Socket>{};
  final List<Future<void>> _pendingHandlers = [];

  @override
  bool get isRunning => _server != null;

  int? get boundPort => _server?.port;

  /// Aguarda handlers de conexão em andamento (útil em testes).
  @visibleForTesting
  Future<void> get handlersDrained async {
    if (_pendingHandlers.isEmpty) return;
    await Future.wait(List<Future<void>>.from(_pendingHandlers));
  }

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
    _server!.listen(
      (client) {
        final handler = _onConnection(client);
        _pendingHandlers.add(handler);
        unawaited(handler.whenComplete(() => _pendingHandlers.remove(handler)));
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    try {
      await server?.close();
    } catch (_) {}
    if (_pendingHandlers.isNotEmpty) {
      await Future.wait(List<Future<void>>.from(_pendingHandlers));
    }
    final clients = _clients.toList();
    _clients.clear();
    for (final client in clients) {
      try {
        client.destroy();
      } catch (_) {}
    }
  }

  Future<void> _onConnection(Socket client) async {
    _clients.add(client);
    final remote = '${client.remoteAddress.address}:${client.remotePort}';
    String? requestText;
    String? response;
    String? error;

    try {
      final data = await client.first.timeout(connectionTimeout);
      requestText = data.isEmpty ? '' : String.fromCharCodes(data);
      final route = routeDiatuTcpCommand(
        requestText,
        serialCommandPrefix: commandPrefix,
        modelCommandPrefix: modelCommandPrefix,
        manualCommandPrefix: manualCommandPrefix,
      );
      if (route == DiatuTcpRoute.bad) {
        response = 'ERROR:BADCMD';
        client.write(response);
        await client.flush();
        return;
      }

      final payload = switch (route) {
        DiatuTcpRoute.model => await onRequestModel(),
        DiatuTcpRoute.manual => await onRequestManual(),
        _ => await onRequestSerial(),
      };
      response = payload ?? kMarkQueueEmptyResponse;
      client.write(response);
      await client.flush();
    } catch (e) {
      error = e is TimeoutException ? 'ERROR:TIMEOUT' : 'ERROR:SERVER';
      response = error;
      try {
        client.write(error);
        await client.flush();
      } catch (_) {}
    } finally {
      eventLog?.record(
        LaserTcpEvent(
          at: DateTime.now(),
          remote: remote,
          request: requestText,
          response: response,
          error: error,
        ),
      );
      _clients.remove(client);
      try {
        client.destroy();
      } catch (_) {}
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

/// Decide se o comando TCP pede serial, modelo, manual ou é inválido.
DiatuTcpRoute routeDiatuTcpCommand(
  String request, {
  required String serialCommandPrefix,
  required String modelCommandPrefix,
  required String manualCommandPrefix,
}) {
  final normalized = normalizeTcpPayload(request);
  if (normalized.isEmpty) return DiatuTcpRoute.bad;

  final modelPrefix = normalizeTcpPayload(modelCommandPrefix);
  final manualPrefix = normalizeTcpPayload(manualCommandPrefix);
  final serialPrefix = normalizeTcpPayload(serialCommandPrefix);

  if (manualPrefix.isNotEmpty && normalized.contains(manualPrefix)) {
    return DiatuTcpRoute.manual;
  }
  if (modelPrefix.isNotEmpty && normalized.contains(modelPrefix)) {
    return DiatuTcpRoute.model;
  }
  if (serialPrefix.isEmpty || normalized.contains(serialPrefix)) {
    return DiatuTcpRoute.serial;
  }
  return DiatuTcpRoute.bad;
}
