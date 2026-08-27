import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/remark_serial.dart';

void main() {
  group('remarkUiCopy', () {
    test('usa copy de regravação com pedal', () {
      final copy = remarkUiCopy('1232600018');
      expect(copy.actionLabel, 'Regravar');
      expect(copy.dialogTitle, 'Regravar serial');
      expect(copy.dialogBody, contains('pedal'));
      expect(copy.dialogBody, isNot(contains('F2')));
      expect(copy.successMessage, contains('1232600018'));
      expect(copy.successMessage, contains('pedal'));
    });

    test('nao exige confirmacao', () {
      expect(remarkRequiresConfirmation(), isFalse);
    });
  });
}
