import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/diatu_laser_tcp_server.dart';
import 'package:sirene_app/features/labels/laser_tcp_diagnostics.dart';
import 'package:sirene_app/features/labels/serial_marking_backend.dart';

void main() {
  group('normalizeTcpPayload', () {
    test('remove CRLF e trim', () {
      expect(normalizeTcpPayload('TCP: Give me string\r\n'), 'TCP: Give me string');
      expect(normalizeTcpPayload('  cmd  '), 'cmd');
    });
  });

  group('matchesDiatuTcpCommand', () {
    test('aceita comando EzCad/DiatuCAD', () {
      expect(
        matchesDiatuTcpCommand('TCP: Give me string', 'TCP: Give me string'),
        isTrue,
      );
      expect(
        matchesDiatuTcpCommand('TCP: Give me string\r\n', 'TCP: Give me string'),
        isTrue,
      );
      expect(matchesDiatuTcpCommand('wrong', 'TCP: Give me string'), isFalse);
      expect(matchesDiatuTcpCommand('', 'TCP: Give me string'), isFalse);
    });

    test('prefixo parcial no payload maior', () {
      expect(
        matchesDiatuTcpCommand('prefix TCP: Give me string suffix', 'TCP: Give me string'),
        isTrue,
      );
    });
  });

  group('DiatuLaserTcpServer E2E', () {
    const command = 'TCP: Give me string';
    late DiatuLaserTcpServer server;
    late LaserTcpEventLog log;

    setUp(() async {
      log = LaserTcpEventLog();
      server = DiatuLaserTcpServer(
        port: 0,
        commandPrefix: command,
        eventLog: log,
        onRequestSerial: () async => '1234567890',
      );
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    Future<String> clientRoundTrip(String payload) async {
      final client = await Socket.connect('127.0.0.1', server.boundPort!);
      try {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        client.write(payload);
        await client.flush();
        final data = await client.timeout(const Duration(seconds: 2)).first;
        return utf8.decode(data).trim();
      } finally {
        await client.close();
      }
    }

    test('comando válido retorna serial', () async {
      final response = await clientRoundTrip(command);
      expect(response, '1234567890');
      expect(log.events, isNotEmpty);
      expect(log.lastEvent?.response, '1234567890');
      expect(log.lastEvent?.request, command);
    });

    test('comando inválido retorna ERROR:BADCMD', () async {
      final response = await clientRoundTrip('wrong');
      expect(response, 'ERROR:BADCMD');
      expect(log.lastEvent?.response, 'ERROR:BADCMD');
    });

    test('fila vazia retorna ERROR:EMPTY', () async {
      await server.stop();
      server = DiatuLaserTcpServer(
        port: 0,
        commandPrefix: command,
        eventLog: log,
        onRequestSerial: () async => null,
      );
      await server.start();
      final response = await clientRoundTrip(command);
      expect(response, kMarkQueueEmptyResponse);
    });

    test('múltiplas conexões sequenciais', () async {
      for (var i = 0; i < 3; i++) {
        final response = await clientRoundTrip(command);
        expect(response, '1234567890');
      }
      expect(log.events.length, greaterThanOrEqualTo(3));
    });
  });

  test('resposta vazia usa ERROR:EMPTY', () {
    expect(kMarkQueueEmptyResponse, 'ERROR:EMPTY');
  });
}
