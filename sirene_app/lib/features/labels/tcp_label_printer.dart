import 'dart:io';

import 'label_printer_transport.dart';

class TcpLabelPrinter implements LabelPrinterTransport {
  TcpLabelPrinter({required this.host, required this.port});

  final String host;
  final int port;

  @override
  String get modeDescription => 'rede ($host:$port)';

  @override
  Future<void> sendZpl(String zpl) async {
    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    try {
      socket.write(zpl);
      await socket.flush();
    } finally {
      await socket.close();
    }
  }
}
