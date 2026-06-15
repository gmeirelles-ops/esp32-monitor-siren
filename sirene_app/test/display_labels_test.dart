import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/shared/display_labels.dart';
import 'package:sirene_app/shared/portuguese_labels.dart';

void main() {
  test('formatBancadaLabel usa número quando disponível', () {
    expect(formatBancadaLabel('AA:BB:CC:DD:EE:FF', numero: 3), 'Bancada 3');
    expect(formatBancadaLabel('AA:BB:CC:DD:EE:FF'), 'Bancada …');
  });

  test('formatBancadaLabelFromMap resolve pelo deviceId', () {
    final map = {'dev-a': 1, 'dev-b': 2};
    expect(formatBancadaLabelFromMap('dev-a', map), 'Bancada 1');
    expect(formatBancadaLabelFromMap('unknown', map), 'Bancada …');
  });

  test('portuguese_labels define rótulos principais', () {
    expect(PortugueseLabels.navBancadas, 'Bancadas');
    expect(PortugueseLabels.rendimento, 'Rendimento');
    expect(PortugueseLabels.conectada, 'Conectada');
    expect(PortugueseLabels.desconectada, 'Desconectada');
    expect(PortugueseLabels.baixarArquivoZpl, 'Baixar arquivo ZPL');
  });
}
