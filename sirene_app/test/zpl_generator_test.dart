import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/zpl_generator.dart';

void main() {
  test('gera ZPL com 3 seriais', () {
    final zpl = generateZplLabelRow(['1232600196', '1232600293', '1232600390']);
    expect(zpl, contains('^XA'));
    expect(zpl, contains('^XZ'));
    expect(zpl, contains('1232600196'));
    expect(zpl, contains('^BI'));
  });

  test('rejeita mais de 3 seriais', () {
    expect(
      () => generateZplLabelRow(['1', '2', '3', '4']),
      throwsArgumentError,
    );
  });
}
