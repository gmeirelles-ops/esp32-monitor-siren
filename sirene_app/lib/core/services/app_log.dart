import 'dart:io';

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Log simples em Documents para diagnosticar fechamentos inesperados no posto.
class AppLog {
  static final _stamp = DateFormat('yyyy-MM-dd HH:mm:ss');

  static Future<void> write(String message, {Object? error, StackTrace? stack}) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'sirene_app.log'));
      final buf = StringBuffer()
        ..writeln('[${_stamp.format(DateTime.now())}] $message');
      if (error != null) buf.writeln('  erro: $error');
      if (stack != null) buf.writeln(stack);
      await file.writeAsString(buf.toString(), mode: FileMode.append, flush: true);
    } catch (_) {
      // Não propagar falha de log.
    }
  }
}

void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLog.write(
      'FlutterError: ${details.exceptionAsString()}',
      stack: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.write('Uncaught async error', error: error, stack: stack);
    return true;
  };
}
