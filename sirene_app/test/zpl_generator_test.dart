import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/labels/zpl_generator.dart';

void main() {
  test('gera ZPL NiceLabel com 3 etiquetas', () {
    const items = [
      LabelZplItem(serial: '1232600196', productName: 'DP1000 220V'),
      LabelZplItem(serial: '1232600293', productName: 'DP1000 220V'),
      LabelZplItem(serial: '1232600390', productName: 'DP1000 220V'),
    ];
    final zpl = generateZplLabelRow(items);
    expect(zpl, contains('^XA'));
    expect(zpl, contains('^XZ'));
    expect(zpl, contains('^PW$zplRowPrintWidth'));
    expect(zpl, contains('DP1000 220V'));
    expect(zpl, contains('MADE IN'));
    expect(zpl, contains('BRAZIL'));
    expect(zpl, contains('1232600196'));
    expect(zpl, contains('^GB145,40,40,B,0^FS'));
  });

  test('rejeita mais de 3 etiquetas', () {
    expect(
      () => generateZplLabelRow([
        const LabelZplItem(serial: '1', productName: 'A'),
        const LabelZplItem(serial: '2', productName: 'A'),
        const LabelZplItem(serial: '3', productName: 'A'),
        const LabelZplItem(serial: '4', productName: 'A'),
      ]),
      throwsArgumentError,
    );
  });

  test('reimpressão usa layout na coluna 1 apenas', () {
    final zpl = generateZplReprintRow(
      serial: '1232600196',
      productName: 'DP1000 220V',
    );
    expect(zpl, contains('^XA'));
    expect(zpl, contains('^XZ'));
    expect(zpl, contains('1232600196'));
    expect(zpl.contains('^FO${6 + zplColumnPitch},3^GB'), isFalse);
  });

  test('serial 1232600196 segue comandos da referência NiceLabel', () {
    final zpl = generateZplLabelRow([
      const LabelZplItem(serial: '1232600196', productName: 'DP1000 220V'),
    ]);
    expect(zpl, contains('^PW$zplRowPrintWidth'));
    expect(zpl, contains('^LL$zplLabelLength'));
    expect(zpl, contains('^FO6,3^GB145,40,40,B,0^FS'));
    expect(zpl, contains('^FO6,12^A0N,25,25^FR^FD DP1000 220V ^FS'));
    expect(zpl, contains('^FO152,8^A0N,22,22^FDMADE IN^FS'));
    expect(zpl, contains('^FO152,25^A0N,22,22^FDBRAZIL^FS'));
    expect(zpl, contains('^FO75,55^A0N,20,20^FD1232600196^FS'));
  });

  test('linha 3-across repete layout nas colunas 0, 239, 478', () {
    const items = [
      LabelZplItem(serial: '1232600196', productName: 'DP1000 220V'),
      LabelZplItem(serial: '1232600293', productName: 'DP1000 220V'),
      LabelZplItem(serial: '1232600390', productName: 'DP1000 220V'),
    ];
    final zpl = generateZplLabelRow(items);
    expect(zpl, contains('^FO6,3^GB145,40,40,B,0^FS'));
    expect(zpl, contains('^FO245,3^GB145,40,40,B,0^FS'));
    expect(zpl, contains('^FO484,3^GB145,40,40,B,0^FS'));
  });
}
