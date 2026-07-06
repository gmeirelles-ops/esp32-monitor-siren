import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/shared/dropdown_value.dart';

void main() {
  test('validDropdownValue retorna null se valor ausente na lista', () {
    expect(validDropdownValue('841fe839e3b4', ['abc', 'def']), isNull);
    expect(validDropdownValue('abc', ['abc', 'def']), 'abc');
    expect(validDropdownValue<String>(null, ['a']), isNull);
  });
}
