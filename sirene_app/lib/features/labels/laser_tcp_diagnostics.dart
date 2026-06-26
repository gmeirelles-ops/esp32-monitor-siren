import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Normaliza payload TCP (remove CRLF e espaços nas extremidades).
String normalizeTcpPayload(String value) =>
    value.replaceAll('\r', '').replaceAll('\n', '').trim();

/// Evento de uma conexão TCP laser (diagnóstico).
class LaserTcpEvent {
  const LaserTcpEvent({
    required this.at,
    required this.remote,
    this.request,
    this.response,
    this.error,
  });

  final DateTime at;
  final String remote;
  final String? request;
  final String? response;
  final String? error;

  String get summary {
    if (error != null) return error!;
    final req = request ?? '(vazio)';
    final res = response ?? '(sem resposta)';
    return '$req → $res';
  }
}

/// Buffer circular de eventos TCP (últimos [maxEvents]).
class LaserTcpEventLog extends ChangeNotifier {
  LaserTcpEventLog({this.maxEvents = 20});

  final int maxEvents;
  final List<LaserTcpEvent> _events = [];

  List<LaserTcpEvent> get events => List.unmodifiable(_events);
  LaserTcpEvent? get lastEvent => _events.isEmpty ? null : _events.first;

  void record(LaserTcpEvent event) {
    _events.insert(0, event);
    while (_events.length > maxEvents) {
      _events.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }
}

/// Mensagem amigável quando a porta TCP já está em uso.
String formatLaserPortInUseError(int port, Object error) {
  return 'Porta $port em uso ($error). '
      'Desative "Marca de controlo TCP" no Diaotu ou altere a porta no app. '
      'Verifique com: netstat -ano | findstr $port';
}

/// Cliente TCP local que simula o DiatuCAD (texto variável).
Future<String> simulateDiatuTcpClient({
  required int port,
  required String command,
  Duration connectTimeout = const Duration(seconds: 5),
}) async {
  Socket? socket;
  try {
    socket = await Socket.connect('127.0.0.1', port).timeout(connectTimeout);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    socket.write(command);
    await socket.flush();

    final data = await socket.first.timeout(const Duration(seconds: 2));
    return utf8.decode(data).trim();
  } on SocketException catch (e) {
    return 'ERRO: não conectou em 127.0.0.1:$port — $e';
  } on TimeoutException {
    return 'ERRO: timeout ao conectar ou ler resposta em 127.0.0.1:$port';
  } finally {
    await socket?.close();
  }
}
