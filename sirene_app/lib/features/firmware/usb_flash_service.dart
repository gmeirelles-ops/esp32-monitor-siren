import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'usb_flash_logic.dart';

enum UsbFlashMode { appOnly, full }

class EsptoolCommand {
  const EsptoolCommand({required this.executable, required this.prefixArgs});

  final String executable;
  final List<String> prefixArgs;
}

/// Executa esptool para gravação USB (Windows).
class UsbFlashService {
  Process? _process;

  List<String> listSerialPorts() {
    if (!Platform.isWindows) {
      return [];
    }
    try {
      final result = Process.runSync(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          r"[System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object",
        ],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return [];
      }
      final output = (result.stdout as String).trim();
      if (output.isEmpty) {
        return [];
      }
      return output
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map(normalizeComPort)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<EsptoolCommand?> resolveEsptoolCommand() async {
    final candidates = <String>[];

    final exeDir = File(Platform.resolvedExecutable).parent;
    candidates.add(p.normalize(p.join(exeDir.path, 'tools', 'windows', 'esptool.exe')));
    candidates.add(p.normalize(p.join(exeDir.path, '..', 'tools', 'windows', 'esptool.exe')));

    final cwd = Directory.current.path;
    candidates.add(p.normalize(p.join(cwd, 'tools', 'windows', 'esptool.exe')));
    candidates.add(p.normalize(p.join(cwd, 'sirene_app', 'tools', 'windows', 'esptool.exe')));

    for (final path in candidates) {
      if (await File(path).exists()) {
        return EsptoolCommand(executable: path, prefixArgs: const []);
      }
    }

    for (final cmd in ['python', 'py', 'python3']) {
      try {
        final result = await Process.run(cmd, ['-m', 'esptool', 'version']);
        if (result.exitCode == 0) {
          return EsptoolCommand(executable: cmd, prefixArgs: const ['-m', 'esptool']);
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> flash({
    required UsbFlashMode mode,
    required String comPort,
    required String appBinPath,
    String? buildDirectory,
    void Function(String line)? onLog,
  }) async {
    await cancel();

    final tool = await resolveEsptoolCommand();
    if (tool == null) {
      throw StateError(
        'esptool não encontrado. Instale Python+esptool ou execute scripts/bundle_esptool_windows.ps1',
      );
    }

    late final List<String> flashArgs;
    if (mode == UsbFlashMode.appOnly) {
      flashArgs = buildAppOnlyFlashArgs(
        comPort: normalizeComPort(comPort),
        appBinPath: appBinPath,
      );
    } else {
      final dir = buildDirectory;
      if (dir == null || dir.isEmpty) {
        throw StateError('Selecione a pasta build/ com os 4 binários');
      }
      final bootloader = p.join(dir, 'bootloader', 'bootloader.bin');
      final partition = p.join(dir, 'partition_table', 'partition-table.bin');
      final otaData = p.join(dir, 'ota_data_initial.bin');
      final app = p.join(dir, 'sirene-validator.bin');
      for (final f in [bootloader, partition, otaData, app]) {
        if (!await File(f).exists()) {
          throw StateError('Arquivo ausente: $f');
        }
      }
      flashArgs = buildFullFlashArgs(
        comPort: normalizeComPort(comPort),
        bootloaderPath: bootloader,
        partitionTablePath: partition,
        otaDataPath: otaData,
        appBinPath: app,
      );
    }

    final allArgs = [...tool.prefixArgs, ...flashArgs];
    onLog?.call('> ${tool.executable} ${allArgs.join(' ')}');

    _process = await Process.start(
      tool.executable,
      allArgs,
      runInShell: Platform.isWindows,
    );

    final buffer = StringBuffer();
    void consume(Stream<List<int>> stream) {
      stream.transform(SystemEncoding().decoder).listen((chunk) {
        buffer.write(chunk);
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) onLog?.call(trimmed);
        }
      });
    }

    consume(_process!.stdout);
    consume(_process!.stderr);

    final code = await _process!.exitCode;
    _process = null;
    final log = buffer.toString();

    if (!esptoolExitSuccess(code, log)) {
      throw StateError('Gravação falhou (código $code)');
    }
  }

  Future<void> cancel() async {
    final proc = _process;
    _process = null;
    if (proc != null) {
      proc.kill(ProcessSignal.sigterm);
      try {
        await proc.exitCode.timeout(const Duration(seconds: 3));
      } catch (_) {
        proc.kill(ProcessSignal.sigkill);
      }
    }
  }
}
