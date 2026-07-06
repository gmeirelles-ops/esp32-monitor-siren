import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/ensaio/ensaio_config.dart';
import 'package:sirene_app/features/ensaio/ensaio_pdf_export.dart';
import 'package:sirene_app/features/mqtt/mqtt_parser.dart';

void main() {
  test('EnsaioConfig defaults alinhado ao firmware', () {
    expect(EnsaioConfig.defaults.validate(), isNull);
    expect(EnsaioConfig.defaults.toMqttPayload(), {
      'cmd': 'START_ENSAIO',
      'on_sec': 60,
      'off_sec': 60,
      'duracao_total_sec': 7200,
    });
  });

  test('parseEnsaioPayload reconhece eventos do tópico ensaio', () {
    final iniciado = MqttParser.parseEnsaioPayload(
      '{"tipo":"ensaio","evento":"iniciado","on_sec":30,"off_sec":15,"duracao_total_sec":7200}',
    );
    expect(iniciado?.isStarted, isTrue);
    expect(iniciado?.duracaoTotalSec, 7200);

    final ciclo = MqttParser.parseEnsaioPayload(
      '{"tipo":"ensaio","evento":"ciclo","n":3,"fase":"ligado","elapsed_sec":120}',
    );
    expect(ciclo?.isCycle, isTrue);
    expect(ciclo?.isOnPhase, isTrue);
    expect(ciclo?.n, 3);
  });

  test('buildEnsaioPdf gera bytes PDF', () async {
    final record = EnsaioRecord(
      id: 1,
      nome: 'Teste resistência',
      deviceId: 'bancada-01',
      operador: 'João',
      operatorId: 1,
      stationId: 'POSTO-1',
      onSeconds: 30,
      offSeconds: 15,
      totalSeconds: 7200,
      startedAt: DateTime(2026, 3, 1, 10),
      endedAt: DateTime(2026, 3, 1, 12),
      status: 'concluido',
      ciclos: 120,
      elapsedSec: 7200,
      motivo: 'duracao',
      pdfPath: null,
      demoMode: false,
    );
    final bytes = await buildEnsaioPdf(
      EnsaioPdfContext(
        record: record,
        bancadaLabel: 'Bancada 01',
        stationId: 'POSTO-1',
      ),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
