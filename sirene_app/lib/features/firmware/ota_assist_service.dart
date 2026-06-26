import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ota_assist_logic.dart';

/// Serve o `.bin` via HTTP local para OTA MQTT (sem dependência shelf).
class OtaAssistService {
  HttpServer? _server;
  Directory? _serveDir;
  String? _servedFilePath;

  bool get isServing => _server != null;

  Future<String> startServing({
    required String sourceBinPath,
    int port = kDefaultOtaHttpPort,
    String? mqttBrokerHost,
  }) async {
    await stop();

    final source = File(sourceBinPath);
    if (!await source.exists()) {
      throw StateError('Arquivo não encontrado: $sourceBinPath');
    }
    final size = await source.length();
    if (!isFirmwareBinSizeValid(size)) {
      throw StateError('Arquivo .bin inválido ou muito pequeno ($size bytes)');
    }

    _serveDir = await Directory.systemTemp.createTemp('sirene_ota_');
    _servedFilePath = p.join(_serveDir!.path, kOtaServedFileName);
    await source.copy(_servedFilePath!);

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException catch (e) {
      await _cleanupDir();
      throw StateError('Porta $port indisponível: ${e.message}');
    }

    _server!.listen(_handleRequest);

    final ok = await _verifyLocal(port);
    if (!ok) {
      await stop();
      throw StateError(
        'Servidor HTTP iniciou mas não respondeu em 127.0.0.1:$port — verifique firewall',
      );
    }

    final lanIp = await detectLanIPv4(mqttBrokerHost: mqttBrokerHost);
    if (lanIp == null) {
      await stop();
      throw StateError('Não foi possível detectar IP da rede local');
    }

    return buildOtaFirmwareUrl(lanIp, port);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (path != '/$kOtaServedFileName' && path != '/$kOtaServedFileName/') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final file = File(_servedFilePath!);
    request.response.headers.contentType = ContentType('application', 'octet-stream');
    request.response.headers.contentLength = await file.length();
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  Future<bool> _verifyLocal(int port) async {
    final client = HttpClient();
    try {
      final request = await client.get('127.0.0.1', port, '/$kOtaServedFileName');
      final response = await request.close();
      await response.drain();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _servedFilePath = null;
    await _cleanupDir();
  }

  Future<void> _cleanupDir() async {
    final dir = _serveDir;
    _serveDir = null;
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
