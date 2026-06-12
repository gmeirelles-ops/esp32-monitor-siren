import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/label_print_logic.dart';
import 'package:sirene_app/features/mqtt/message_pump.dart';

void main() {
  group('MessagePump', () {
    test('processa handlers em ordem FIFO', () async {
      final pump = MessagePump();
      final order = <int>[];

      pump.enqueue(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add(1);
      });
      pump.enqueue(() async => order.add(2));
      pump.enqueue(() async => order.add(3));

      await pump.drained;
      expect(order, [1, 2, 3]);
    });

    test('erro em um handler não interrompe os seguintes', () async {
      final pump = MessagePump();
      final order = <int>[];

      pump.enqueue(() async {
        order.add(1);
        throw Exception('falha simulada');
      });
      pump.enqueue(() async => order.add(2));

      await pump.drained;
      expect(order, [1, 2]);
    });
  });

  group('printLabelBatches', () {
    test('remove apenas ids dos blocos impressos com sucesso', () async {
      final entries = [
        (id: 1, serial: '1111111111'),
        (id: 2, serial: '2222222222'),
        (id: 3, serial: '3333333333'),
        (id: 4, serial: '4444444444'),
        (id: 5, serial: '5555555555'),
      ];

      final printed = <List<String>>[];
      final result = await printLabelBatches(
        entries: entries,
        sendZpl: (serials) async => printed.add(serials),
      );

      expect(result.error, isNull);
      expect(result.printedIds, [1, 2, 3, 4, 5]);
      expect(printed.length, 2);
      expect(printed[0].length, 3);
      expect(printed[1].length, 2);
    });

    test('falha parcial preserva blocos não enviados', () async {
      var batch = 0;
      final entries = [
        (id: 1, serial: '1111111111'),
        (id: 2, serial: '2222222222'),
        (id: 3, serial: '3333333333'),
        (id: 4, serial: '4444444444'),
      ];

      final result = await printLabelBatches(
        entries: entries,
        sendZpl: (_) async {
          batch++;
          if (batch == 2) throw Exception('impressora offline');
        },
      );

      expect(result.printedIds, [1, 2, 3]);
      expect(result.error, isNotNull);
    });
  });
}
