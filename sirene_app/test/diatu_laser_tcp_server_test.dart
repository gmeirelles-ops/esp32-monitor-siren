import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/diatu_laser_tcp_server.dart';
import 'package:sirene_app/features/labels/laser_tcp_diagnostics.dart';
import 'package:sirene_app/features/labels/serial_marking_backend.dart';

void main() {
  group('normalizeTcpPayload', () {
    test('remove CRLF e trim', () {
      expect(
        normalizeTcpPayload('TCP: Give me string\r\n'),
        'TCP: Give me string',
      );
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
        matchesDiatuTcpCommand(
          'TCP: Give me string\r\n',
          'TCP: Give me string',
        ),
        isTrue,
      );
      expect(matchesDiatuTcpCommand('wrong', 'TCP: Give me string'), isFalse);
      expect(matchesDiatuTcpCommand('', 'TCP: Give me string'), isFalse);
    });

    test('prefixo parcial no payload maior', () {
      expect(
        matchesDiatuTcpCommand(
          'prefix TCP: Give me string suffix',
          'TCP: Give me string',
        ),
        isTrue,
      );
    });
  });

  group('routeDiatuTcpCommand', () {
    const serialCmd = 'TCP: Give me string';
    const modelCmd = 'TCP: model';
    const manualCmd = 'TCP: manual';

    test('roteia serial, modelo e manual', () {
      expect(
        routeDiatuTcpCommand(
          serialCmd,
          serialCommandPrefix: serialCmd,
          modelCommandPrefix: modelCmd,
          manualCommandPrefix: manualCmd,
        ),
        DiatuTcpRoute.serial,
      );
      expect(
        routeDiatuTcpCommand(
          modelCmd,
          serialCommandPrefix: serialCmd,
          modelCommandPrefix: modelCmd,
          manualCommandPrefix: manualCmd,
        ),
        DiatuTcpRoute.model,
      );
      expect(
        routeDiatuTcpCommand(
          manualCmd,
          serialCommandPrefix: serialCmd,
          modelCommandPrefix: modelCmd,
          manualCommandPrefix: manualCmd,
        ),
        DiatuTcpRoute.manual,
      );
      expect(
        routeDiatuTcpCommand(
          'wrong',
          serialCommandPrefix: serialCmd,
          modelCommandPrefix: modelCmd,
          manualCommandPrefix: manualCmd,
        ),
        DiatuTcpRoute.bad,
      );
    });

    test('modelo tem prioridade se ambos casarem', () {
      expect(
        routeDiatuTcpCommand(
          'TCP: model extra',
          serialCommandPrefix: 'TCP:',
          modelCommandPrefix: modelCmd,
          manualCommandPrefix: manualCmd,
        ),
        DiatuTcpRoute.model,
      );
    });
  });

  group('DiatuLaserTcpServer E2E', () {
    const command = 'TCP: Give me string';
    const modelCommand = 'TCP: model';
    late DiatuLaserTcpServer server;
    late LaserTcpEventLog log;
    var serialCalls = 0;
    var modelCalls = 0;

    setUp(() async {
      log = LaserTcpEventLog();
      serialCalls = 0;
      modelCalls = 0;
      server = DiatuLaserTcpServer(
        port: 0,
        commandPrefix: command,
        modelCommandPrefix: modelCommand,
        manualCommandPrefix: 'TCP: manual',
        eventLog: log,
        onRequestSerial: () async {
          serialCalls++;
          return '1234567890';
        },
        onRequestModel: () async {
          modelCalls++;
          return 'Sirene Modelo X';
        },
        onRequestManual: () async => 'Manual 123',
      );
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    Future<String> clientRoundTrip(String payload) async {
      final client = await Socket.connect('127.0.0.1', server.boundPort!);
      final responseCompleter = Completer<String>();
      client.listen(
        (data) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(utf8.decode(data).trim());
          }
        },
        onError: (Object e, StackTrace st) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(e, st);
          }
        },
      );
      client.write(payload);
      await client.flush();
      try {
        return await responseCompleter.future.timeout(
          const Duration(seconds: 3),
        );
      } finally {
        await client.close();
      }
    }

    test('comando serial válido retorna serial', () async {
      final response = await clientRoundTrip(command);
      await server.handlersDrained;
      expect(response, '1234567890');
      expect(serialCalls, 1);
      expect(modelCalls, 0);
      expect(log.events, isNotEmpty);
      expect(log.lastEvent?.response, '1234567890');
      expect(log.lastEvent?.request, command);
    });

    test('comando modelo retorna nome sem chamar serial', () async {
      final response = await clientRoundTrip(modelCommand);
      expect(response, 'Sirene Modelo X');
      expect(modelCalls, 1);
      expect(serialCalls, 0);
    });

    test('comando inválido retorna ERROR:BADCMD', () async {
      final response = await clientRoundTrip('wrong');
      await server.handlersDrained;
      expect(response, 'ERROR:BADCMD');
      expect(log.lastEvent?.response, 'ERROR:BADCMD');
    });

    test('fila vazia retorna ERROR:EMPTY', () async {
      await server.stop();
      server = DiatuLaserTcpServer(
        port: 0,
        commandPrefix: command,
        modelCommandPrefix: modelCommand,
        manualCommandPrefix: 'TCP: manual',
        eventLog: log,
        onRequestSerial: () async => null,
        onRequestModel: () async => null,
        onRequestManual: () async => null,
      );
      await server.start();
      final response = await clientRoundTrip(command);
      expect(response, kMarkQueueEmptyResponse);
    });

    test('múltiplas conexões sequenciais', () async {
      for (var i = 0; i < 3; i++) {
        final response = await clientRoundTrip(command);
        expect(response, '1234567890');
        await server.handlersDrained;
      }
      expect(log.events.length, greaterThanOrEqualTo(3));
    });
  });

  test('resposta vazia usa ERROR:EMPTY', () {
    expect(kMarkQueueEmptyResponse, 'ERROR:EMPTY');
  });
}
