import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/label_print_logic.dart';
import 'package:sirene_app/features/labels/zpl_generator.dart';
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
    LabelZplItem item(int id, String serial) =>
        LabelZplItem(serial: serial, productName: 'DP1000 220V');

    test('remove apenas ids dos blocos impressos com sucesso', () async {
      final entries = [
        (id: 1, item: item(1, '1111111111')),
        (id: 2, item: item(2, '2222222222')),
        (id: 3, item: item(3, '3333333333')),
        (id: 4, item: item(4, '4444444444')),
        (id: 5, item: item(5, '5555555555')),
      ];

      final printed = <List<LabelZplItem>>[];
      final result = await printLabelBatches(
        entries: entries,
        sendZpl: (batch) async => printed.add(batch),
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
        (id: 1, item: item(1, '1111111111')),
        (id: 2, item: item(2, '2222222222')),
        (id: 3, item: item(3, '3333333333')),
        (id: 4, item: item(4, '4444444444')),
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
