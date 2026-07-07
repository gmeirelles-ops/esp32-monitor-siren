import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

void main() {
  group('SET_BATCH contract', () {
    test('toSetBatchJson contém campos exigidos pelo firmware', () {
      const batch = BatchConfig(
        numeroOp: '12345',
        idProduto: '071',
        ano: '26',
        tempoTeste: 5,
        potenciaMin: 18.0,
        potenciaMax: 22.0,
        quantidadeTotal: 100,
        proximoSequencial: 501,
        modoReteste: false,
      );

      final json = batch.toSetBatchJson();

      expect(json['cmd'], 'SET_BATCH');
      expect(json['numero_op'], '12345');
      expect(json['id_produto'], '071');
      expect(json['ano'], '26');
      expect(json['tempo_teste'], 5);
      expect(json['potencia_min'], 18.0);
      expect(json['potencia_max'], 22.0);
      expect(json['quantidade_total'], 100);
      expect(json['proximo_sequencial'], 501);
      expect(json['modo_reteste'], isFalse);
    });

    test('potencia_min menor que potencia_max', () {
      const batch = BatchConfig(
        numeroOp: '1',
        idProduto: '001',
        ano: '26',
        tempoTeste: 10,
        potenciaMin: 19.5,
        potenciaMax: 20.5,
        quantidadeTotal: 1,
        proximoSequencial: 1,
      );
      expect(batch.potenciaMin, lessThan(batch.potenciaMax));
    });
  });
}
