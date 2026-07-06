import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ota_assist_logic.dart';

/// Serve o `.bin` via HTTP local para OTA MQTT.
///
/// No Windows usa `python -m http.server` (mesmo fluxo que funciona no terminal).
/// Se já houver um servidor na porta servindo o `.bin`, reutiliza (ex.: python no terminal).
class OtaAssistService {
  HttpServer? _dartServer;
  Process? _pythonProcess;
  Directory? _serveDir;
  String? _servedFilePath;
  bool _reusingExternalServer = false;

  bool get isServing => _reusingExternalServer || _dartServer != null || _pythonProcess != null;

  Future<String> startServing({
    required String sourceBinPath,
    int port = kDefaultOtaHttpPort,
    String? mqttBrokerHost,
  }) async {
    final source = File(sourceBinPath);
    if (!await source.exists()) {
      throw StateError('Arquivo não encontrado: $sourceBinPath');
    }
    final size = await source.length();
    if (!isFirmwareBinSizeValid(size)) {
      throw StateError('Arquivo .bin inválido ou muito pequeno ($size bytes)');
    }

    final lanIp = await detectLanIPv4(mqttBrokerHost: mqttBrokerHost);
    if (lanIp == null) {
      throw StateError('Não foi possível detectar IP da rede local');
    }

    // Servidor já ativo (ex.: python -m http.server no terminal)
    if (await _waitForFirmware('127.0.0.1', port, minBytes: kMinFirmwareBinBytes)) {
      if (await _waitForFirmware(lanIp, port, minBytes: kMinFirmwareBinBytes, attempts: 4)) {
        _reusingExternalServer = true;
        return buildOtaFirmwareUrl(lanIp, port);
      }
      throw StateError(
        'Há um servidor na porta $port em localhost, mas a rede não alcança $lanIp:$port. '
        'Libere a porta $port no Firewall do Windows (rede privada).',
      );
    }

    await stop();

    _serveDir = await Directory.systemTemp.createTemp('sirene_ota_');
    _servedFilePath = p.join(_serveDir!.path, kOtaServedFileName);
    await source.copy(_servedFilePath!);

    Object? pythonError;
    if (Platform.isWindows) {
      final python = await _resolvePythonExecutable();
      if (python != null) {
        try {
          await _startPythonServer(python, port, _serveDir!.path);
        } catch (e) {
          pythonError = e;
          await _stopPython();
        }
      } else {
        pythonError = 'Python não encontrado no PATH';
      }
    }

    if (_pythonProcess == null) {
      try {
        await _startDartServer(port);
      } on StateError catch (e) {
        throw StateError(
          'Porta $port indisponível (${e.message}). '
          'Feche o servidor HTTP no terminal (Ctrl+C no python) ou use outra porta.',
        );
      }
    }

    if (!await _waitForFirmware('127.0.0.1', port, minBytes: kMinFirmwareBinBytes)) {
      await stop();
      final extra = pythonError != null ? ' Detalhe Python: $pythonError' : '';
      throw StateError(
        'Servidor HTTP não respondeu em 127.0.0.1:$port após iniciar.$extra '
        'Confirme que a porta está livre e que o Python funciona: '
        'python -m http.server $port',
      );
    }

    if (!await _waitForFirmware(lanIp, port, minBytes: kMinFirmwareBinBytes, attempts: 8)) {
      await stop();
      throw StateError(
        'Servidor OK em localhost mas não em $lanIp:$port. '
        'Libere a porta $port no Firewall do Windows para '
        '${_pythonProcess != null ? 'python.exe' : 'sirene_app.exe'}.',
      );
    }

    return buildOtaFirmwareUrl(lanIp, port);
  }

  Future<void> _startPythonServer(String python, int port, String directory) async {
    final dir = directory.replaceAll('\\', '/');
    _pythonProcess = await Process.start(
      python,
      ['-m', 'http.server', '$port', '--bind', '0.0.0.0', '--directory', dir],
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    try {
      final code = await _pythonProcess!.exitCode.timeout(const Duration(milliseconds: 200));
      final stderr = await _pythonProcess!.stderr.transform(SystemEncoding().decoder).join();
      throw StateError('encerrado ($code): $stderr');
    } on TimeoutException {
      // processo ativo
    }
  }

  Future<void> _startDartServer(int port) async {
    try {
      _dartServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException catch (e) {
      throw StateError(e.message);
    }
    _dartServer!.listen(_handleRequest);
  }

  Future<String?> _resolvePythonExecutable() async {
    for (final cmd in const ['python', 'py', 'python3']) {
      try {
        final result = await Process.run(cmd, ['--version'], runInShell: true);
        if (result.exitCode == 0) return cmd;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path != '/$kOtaServedFileName' && path != '/$kOtaServedFileName/') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final file = File(_servedFilePath!);
      final length = await file.length();
      request.response.headers.contentType = ContentType('application', 'octet-stream');
      request.response.headers.contentLength = length;
      request.response.headers.set(HttpHeaders.connectionHeader, 'close');

      if (request.method == 'HEAD') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      if (request.method != 'GET') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }

      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<bool> _waitForFirmware(
    String host,
    int port, {
    required int minBytes,
    int attempts = 10,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (await _probeFirmware(host, port, minBytes: minBytes)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<bool> _probeFirmware(String host, int port, {required int minBytes}) async {
    final client = HttpClient();
    try {
      final request = await client.get(host, port, '/$kOtaServedFileName');
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain();
        return false;
      }
      final len = response.contentLength;
      await response.drain();
      if (len >= 0 && len < minBytes) return false;
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _stopPython() async {
    final proc = _pythonProcess;
    _pythonProcess = null;
    if (proc == null) return;
    try {
      proc.kill(ProcessSignal.sigterm);
      await proc.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          proc.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (_) {
      proc.kill(ProcessSignal.sigkill);
    }
  }

  Future<void> stop() async {
    _reusingExternalServer = false;
    await _dartServer?.close(force: true);
    _dartServer = null;
    await _stopPython();
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
