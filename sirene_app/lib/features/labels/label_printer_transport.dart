import 'dart:io';

import '../../core/config/app_config.dart';
import 'tcp_label_printer.dart';
import 'windows_raw_label_printer.dart';

/// Transporte de ZPL para a impressora (rede TCP ou USB via spooler Windows).
abstract class LabelPrinterTransport {
  Future<void> sendZpl(String zpl);

  String get modeDescription;
}

/// ZPL mínimo para teste de impressão nas Configurações.
const kTestPrintZpl = '^XA^FO50,50^A0N,30,30^FDTESTE^FS^XZ';

LabelPrinterTransport createLabelPrinterTransport(AppConfig config) {
  return createLabelPrinterTransportFromValues(
    mode: config.printerMode,
    host: config.printerHost,
    port: config.printerPort,
    windowsName: config.printerWindowsName,
  );
}

LabelPrinterTransport createLabelPrinterTransportFromValues({
  required PrinterMode mode,
  required String host,
  required int port,
  required String windowsName,
}) {
  switch (mode) {
    case PrinterMode.usb:
      if (!Platform.isWindows) {
        throw UnsupportedError('Impressão USB só está disponível no Windows');
      }
      if (windowsName.trim().isEmpty) {
        throw StateError('Selecione uma impressora Windows em Configurações (modo USB)');
      }
      return WindowsRawLabelPrinter(printerName: windowsName.trim());
    case PrinterMode.network:
      return TcpLabelPrinter(host: host, port: port);
  }
}

String formatPrinterError(Object error, PrinterMode mode) {
  final prefix = mode == PrinterMode.usb
      ? 'Erro na impressão USB'
      : 'Erro na impressão em rede';
  return '$prefix: $error';
}
