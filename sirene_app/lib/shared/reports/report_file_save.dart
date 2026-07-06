import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final reportFileDateFmt = DateFormat('yyyyMMdd_HHmmss');

Future<String> saveReportBytes(String basename, Uint8List bytes, String extension) async {
  final dir = await _reportsDir();
  final stamp = reportFileDateFmt.format(DateTime.now());
  final file = File(p.join(dir.path, '${basename}_$stamp.$extension'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String> saveReportText(String basename, String content, String extension) async {
  final dir = await _reportsDir();
  final stamp = reportFileDateFmt.format(DateTime.now());
  final file = File(p.join(dir.path, '${basename}_$stamp.$extension'));
  await file.writeAsString(content, encoding: utf8);
  return file.path;
}

Future<Directory> _reportsDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final reportsDir = Directory(p.join(docs.path, 'relatorios'));
  if (!await reportsDir.exists()) {
    await reportsDir.create(recursive: true);
  }
  return reportsDir;
}
