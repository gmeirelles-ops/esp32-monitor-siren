import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../database/database.dart';
import '../providers/core_providers.dart';
import '../../features/cloud/sync/sync_providers.dart';
import '../../features/labels/marking_providers.dart';
import '../../features/mqtt/mqtt_providers.dart';
import '../../features/operators/operators_provider.dart';

/// Versão do app embutida no manifest (manter alinhada a `pubspec.yaml`).
const kBackupAppVersion = '1.0.1+2';

const kBackupFormatVersion = 1;
const kBackupDbEntryName = 'sirene_app.sqlite';
const kBackupManifestEntryName = 'manifest.json';
const kBackupPrefsEntryName = 'prefs.json';

/// Chaves de SharedPreferences incluídas no backup (sem sessão/PIN ativo).
const kBackupPrefKeys = <String>[
  'mqtt_host',
  'mqtt_port',
  'mqtt_site',
  'mqtt_ws_path',
  'mqtt_use_ws',
  'mqtt_use_tls',
  'mqtt_username',
  'mqtt_password',
  'laser_tcp_port',
  'laser_tcp_command',
  'laser_model_command',
  'station_id',
  'selected_device_id',
  'bancada_setup_complete',
  'wifi_provisioned',
  'sync_enabled',
  'cloud_setup_complete',
  'yield_target_pct',
  'shift_start_hour',
];

class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.stationId,
    required this.appVersion,
    required this.createdAt,
  });

  final int formatVersion;
  final int schemaVersion;
  final String stationId;
  final String appVersion;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'stationId': stationId,
        'appVersion': appVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static BackupManifest fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    final createdAt = createdRaw is String
        ? DateTime.tryParse(createdRaw) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return BackupManifest(
      formatVersion: (json['formatVersion'] as num?)?.toInt() ?? 0,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? -1,
      stationId: (json['stationId'] as String?)?.trim() ?? '',
      appVersion: (json['appVersion'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }

  static BackupManifest parseJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('manifest.json inválido');
    }
    return fromJson(decoded);
  }
}

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Valida manifest antes do restore. Lança [BackupException] se incompatível.
void validateBackupManifest(
  BackupManifest manifest, {
  required int appSchemaVersion,
  int expectedFormatVersion = kBackupFormatVersion,
}) {
  if (manifest.formatVersion != expectedFormatVersion) {
    throw BackupException(
      'Formato de backup não suportado (formatVersion=${manifest.formatVersion}). '
      'Atualize o aplicativo.',
    );
  }
  if (manifest.schemaVersion < 0) {
    throw const BackupException('manifest.json sem schemaVersion válido');
  }
  if (manifest.schemaVersion > appSchemaVersion) {
    throw BackupException(
      'Este backup é de um app mais novo (schema ${manifest.schemaVersion}; '
      'este app está em $appSchemaVersion). Atualize o aplicativo antes de restaurar.',
    );
  }
}

String defaultBackupFileName({DateTime? now}) {
  final stamp = DateFormat('yyyyMMdd_HHmmss').format(now ?? DateTime.now());
  return 'sirene_backup_$stamp.zip';
}

Map<String, Object?> collectBackupPrefs(SharedPreferences prefs) {
  final out = <String, Object?>{};
  for (final key in kBackupPrefKeys) {
    if (!prefs.containsKey(key)) continue;
    out[key] = prefs.get(key);
  }
  return out;
}

Future<void> applyBackupPrefs(SharedPreferences prefs, Map<String, dynamic> data) async {
  for (final entry in data.entries) {
    if (!kBackupPrefKeys.contains(entry.key)) continue;
    final value = entry.value;
    if (value == null) {
      await prefs.remove(entry.key);
    } else if (value is bool) {
      await prefs.setBool(entry.key, value);
    } else if (value is int) {
      await prefs.setInt(entry.key, value);
    } else if (value is double) {
      await prefs.setDouble(entry.key, value);
    } else if (value is String) {
      await prefs.setString(entry.key, value);
    } else if (value is num) {
      if (value is double || value != value.roundToDouble()) {
        await prefs.setDouble(entry.key, value.toDouble());
      } else {
        await prefs.setInt(entry.key, value.toInt());
      }
    }
  }
}

/// Monta bytes ZIP a partir dos três artefatos (testável sem Drift).
List<int> buildBackupZipBytes({
  required List<int> sqliteBytes,
  required BackupManifest manifest,
  required Map<String, Object?> prefs,
}) {
  final archive = Archive();
  archive.addFile(ArchiveFile(kBackupDbEntryName, sqliteBytes.length, sqliteBytes));
  final manifestBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  archive.addFile(ArchiveFile(kBackupManifestEntryName, manifestBytes.length, manifestBytes));
  final prefsBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(prefs));
  archive.addFile(ArchiveFile(kBackupPrefsEntryName, prefsBytes.length, prefsBytes));
  final encoded = ZipEncoder().encode(archive);
  if (encoded.isEmpty) {
    throw const BackupException('Falha ao gerar arquivo ZIP');
  }
  return encoded;
}

class ParsedBackupZip {
  const ParsedBackupZip({
    required this.sqliteBytes,
    required this.manifest,
    required this.prefs,
  });

  final List<int> sqliteBytes;
  final BackupManifest manifest;
  final Map<String, dynamic> prefs;
}

ParsedBackupZip parseBackupZipBytes(List<int> zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  ArchiveFile? dbFile;
  ArchiveFile? manifestFile;
  ArchiveFile? prefsFile;
  for (final f in archive.files) {
    if (!f.isFile) continue;
    switch (f.name) {
      case kBackupDbEntryName:
        dbFile = f;
      case kBackupManifestEntryName:
        manifestFile = f;
      case kBackupPrefsEntryName:
        prefsFile = f;
    }
  }
  if (dbFile == null || manifestFile == null) {
    throw const BackupException(
      'ZIP inválido: faltam sirene_app.sqlite e/ou manifest.json',
    );
  }
  final manifest = BackupManifest.parseJsonString(utf8.decode(manifestFile.content));
  Map<String, dynamic> prefs = {};
  if (prefsFile != null) {
    final decoded = jsonDecode(utf8.decode(prefsFile.content));
    if (decoded is Map<String, dynamic>) {
      prefs = decoded;
    }
  }
  return ParsedBackupZip(
    sqliteBytes: List<int>.from(dbFile.content),
    manifest: manifest,
    prefs: prefs,
  );
}

class BackupService {
  BackupService({
    required this.ref,
    required this.prefs,
    required this.closeDatabase,
    required this.deleteSidecarFiles,
    this.appSchemaVersion = 20,
    this.appVersion = kBackupAppVersion,
  });

  final Ref ref;
  final SharedPreferences prefs;
  final Future<void> Function() closeDatabase;
  final Future<void> Function(File dbFile) deleteSidecarFiles;
  final int appSchemaVersion;
  final String appVersion;

  Future<int> countPendingSync() async {
    return ref.read(databaseProvider).countPending();
  }

  /// Fecha o DB, copia o SQLite, gera ZIP em [destinationZip], reabre o DB.
  Future<BackupManifest> exportToFile(File destinationZip) async {
    final dbFile = await AppDatabase.dbFile();
    if (!await dbFile.exists()) {
      throw const BackupException('Banco local não encontrado');
    }

    await closeDatabase();
    await deleteSidecarFiles(dbFile);

    try {
      final sqliteBytes = await dbFile.readAsBytes();
      final config = AppConfig(prefs);
      final manifest = BackupManifest(
        formatVersion: kBackupFormatVersion,
        schemaVersion: appSchemaVersion,
        stationId: config.stationId,
        appVersion: appVersion,
        createdAt: DateTime.now().toUtc(),
      );
      final zipBytes = buildBackupZipBytes(
        sqliteBytes: sqliteBytes,
        manifest: manifest,
        prefs: collectBackupPrefs(prefs),
      );
      await destinationZip.parent.create(recursive: true);
      await destinationZip.writeAsBytes(zipBytes, flush: true);
      return manifest;
    } finally {
      _invalidateAfterDbChange();
    }
  }

  /// Valida e restaura ZIP. Chamar só após confirmação do usuário.
  Future<BackupManifest> restoreFromFile(File zipFile) async {
    if (!await zipFile.exists()) {
      throw const BackupException('Arquivo de backup não encontrado');
    }
    final parsed = parseBackupZipBytes(await zipFile.readAsBytes());
    validateBackupManifest(parsed.manifest, appSchemaVersion: appSchemaVersion);

    final dbFile = await AppDatabase.dbFile();
    await closeDatabase();
    await deleteSidecarFiles(dbFile);

    try {
      await dbFile.parent.create(recursive: true);
      await dbFile.writeAsBytes(parsed.sqliteBytes, flush: true);
      await applyBackupPrefs(prefs, parsed.prefs);
      return parsed.manifest;
    } finally {
      _invalidateAfterDbChange();
    }
  }

  void _invalidateAfterDbChange() {
    ref.invalidate(databaseProvider);
    ref.invalidate(appConfigProvider);
    ref.invalidate(bancadaSetupCompleteProvider);
    ref.invalidate(wifiProvisionedProvider);
    ref.invalidate(cloudSetupCompleteProvider);
    ref.invalidate(syncEnabledProvider);
    ref.invalidate(activeOperatorProvider);
    ref.invalidate(devicesProvider);
    ref.invalidate(syncQueueProcessorProvider);
    ref.invalidate(syncStatusProvider);
    ref.invalidate(markQueueProcessorProvider);
  }
}

Future<void> deleteSqliteSidecars(File dbFile) async {
  for (final suffix in ['-wal', '-shm']) {
    final side = File('${dbFile.path}$suffix');
    if (await side.exists()) {
      await side.delete();
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref: ref,
    prefs: ref.watch(sharedPreferencesProvider),
    closeDatabase: () async {
      final db = ref.read(databaseProvider);
      await db.close();
    },
    deleteSidecarFiles: deleteSqliteSidecars,
    appSchemaVersion: 20,
  );
});
