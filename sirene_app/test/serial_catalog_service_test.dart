import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/cloud/sync/serial_catalog_service.dart';

void main() {
  test('catalogYearFromBatchAno mapeia ano de 2 dígitos', () {
    expect(catalogYearFromBatchAno('26', DateTime(2026, 9, 14)), '2026');
    expect(catalogYearFromBatchAno('99', DateTime(1999, 1, 1)), '1999');
    expect(catalogYearFromBatchAno('00', DateTime(2000, 5, 1)), '2000');
  });
}
