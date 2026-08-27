import 'package:flutter_test/flutter_test.dart';
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
}
