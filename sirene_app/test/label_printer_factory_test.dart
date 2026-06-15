import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/features/labels/label_printer.dart';
import 'package:sirene_app/features/labels/tcp_label_printer.dart';

void main() {
  test('factory cria TcpLabelPrinter em modo rede', () {
    final transport = createLabelPrinterTransportFromValues(
      mode: PrinterMode.network,
      host: '192.168.1.50',
      port: 9100,
      windowsName: '',
    );
    expect(transport, isA<TcpLabelPrinter>());
    expect(transport.modeDescription, contains('192.168.1.50'));
  });

  test('factory exige nome da impressora em modo USB', () {
    expect(
      () => createLabelPrinterTransportFromValues(
        mode: PrinterMode.usb,
        host: '',
        port: 9100,
        windowsName: '',
      ),
      throwsStateError,
    );
  });

  test('formatPrinterError distingue modo USB e rede', () {
    expect(
      formatPrinterError(Exception('timeout'), PrinterMode.usb),
      contains('USB'),
    );
    expect(
      formatPrinterError(Exception('timeout'), PrinterMode.network),
      contains('rede'),
    );
  });
}
