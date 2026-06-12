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
  });
}
