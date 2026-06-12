import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/products/power_limits.dart';

void main() {
  group('calcularLimites', () {
    test('20 W com 10% gera 18 e 22', () {
      final limits = calcularLimites(20.0, 10);
      expect(limits.min, 18.0);
      expect(limits.max, 22.0);
    });

    test('arredonda para 2 casas decimais', () {
      final limits = calcularLimites(19.95, 10);
      expect(limits.min, 17.95);
      expect(limits.max, 21.95);
    });
  });

  group('isValidProductId', () {
    test('aceita 3 dígitos', () {
      expect(isValidProductId('123'), isTrue);
      expect(isValidProductId('001'), isTrue);
    });

    test('rejeita id inválido', () {
      expect(isValidProductId('12'), isFalse);
      expect(isValidProductId('1234'), isFalse);
      expect(isValidProductId('abc'), isFalse);
    });
  });

  group('normalizeProductId', () {
    test('preenche com zeros à esquerda', () {
      expect(normalizeProductId('1'), '001');
      expect(normalizeProductId('42'), '042');
    });
  });
}
