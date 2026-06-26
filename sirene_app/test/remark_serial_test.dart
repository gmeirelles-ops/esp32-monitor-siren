import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/features/labels/remark_serial.dart';

void main() {
  group('remarkUiCopy', () {
    test('modo etiquetas usa reimprimir', () {
      final copy = remarkUiCopy(MarkingMode.labels, '1232600018');
      expect(copy.actionLabel, 'Reimprimir');
      expect(copy.dialogTitle, 'Reimprimir etiqueta');
      expect(copy.dialogBody, contains('rolo'));
    });

    test('modo laser usa regravar', () {
      final copy = remarkUiCopy(MarkingMode.laser, '1232600018');
      expect(copy.actionLabel, 'Regravar');
      expect(copy.dialogTitle, 'Regravar serial');
      expect(copy.dialogBody, contains('DiatuCAD'));
    });
  });
}
