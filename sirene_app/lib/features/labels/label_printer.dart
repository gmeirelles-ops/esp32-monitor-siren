import 'dart:io';

class LabelPrinter {
  LabelPrinter({required this.host, required this.port});

  final String host;
  final int port;

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
