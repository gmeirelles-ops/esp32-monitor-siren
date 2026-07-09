import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/serial/itf_check_digit.dart';

void main() {
  group('ITF 2 de 5', () {
    test('calcula dígito verificador para corpo conhecido', () {
      expect(calculateItfCheckDigit('123260019'), 8);
    });

    test('gera serial completo de 10 dígitos', () {
      final serial = generateFullSerial(
        idProduto: '123',
        ano: '26',
        sequencial: 19,
      );
      expect(serial, '1232600198');
      expect(serial.length, 10);
    });

    test('aplica padding no sequencial', () {
      final serial = generateFullSerial(
        idProduto: '001',
        ano: '26',
        sequencial: 1,
      );
      expect(serial.startsWith('001260001'), isTrue);
      expect(serial.length, 10);
    });

    test('rejeita corpo inválido', () {
      expect(() => calculateItfCheckDigit('12345'), throwsArgumentError);
      expect(() => calculateItfCheckDigit('12345678A'), throwsArgumentError);
    });

    test('extrai idProduto do serial', () {
      expect(extractIdProdutoFromSerial('1232600198'), '123');
      expect(extractIdProdutoFromSerial('0012600012'), '001');
      expect(extractIdProdutoFromSerial('12'), isNull);
      expect(extractIdProdutoFromSerial('ABC2600198'), isNull);
    });

    test('monta serial a partir do corpo de 9 dígitos', () {
      expect(composeItfSerial('123260019'), '1232600198');
    });

    test('valida serial ITF e produto', () {
      expect(isValidItfSerial('1232600198'), isTrue);
      expect(isValidItfSerial('1232600199'), isFalse);
      expect(validateItfSerialForProduct('1232600198', '123'), isNull);
      expect(
        validateItfSerialForProduct('1232600198', '999'),
        isNotNull,
      );
      expect(parseSequencialFromSerial('0372600013'), 1);
      expect(parseAnoFromSerial('0372600013'), '26');
    });
  });
}
