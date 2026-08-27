import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/services/backup_service.dart';

void main() {
  group('BackupManifest', () {
    test('round-trip JSON', () {
      final m = BackupManifest(
        formatVersion: 1,
        schemaVersion: 20,
        stationId: 'posto-01',
        appVersion: '1.0.1+2',
        createdAt: DateTime.utc(2026, 8, 27, 12),
      );
      final parsed = BackupManifest.fromJson(m.toJson());
      expect(parsed.formatVersion, 1);
      expect(parsed.schemaVersion, 20);
      expect(parsed.stationId, 'posto-01');
      expect(parsed.appVersion, '1.0.1+2');
    });

    test('parseJsonString rejeita não-mapa', () {
      expect(
        () => BackupManifest.parseJsonString('[]'),
        throwsA(isA<BackupException>()),
      );
    });
  });

  group('validateBackupManifest', () {
    final base = BackupManifest(
      formatVersion: 1,
      schemaVersion: 18,
      stationId: 'posto-01',
      appVersion: '1.0.0',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    test('aceita schema menor ou igual', () {
      expect(
        () => validateBackupManifest(base, appSchemaVersion: 20),
        returnsNormally,
      );
      expect(
        () => validateBackupManifest(
          BackupManifest(
            formatVersion: 1,
            schemaVersion: 20,
            stationId: 'p',
            appVersion: 'x',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          appSchemaVersion: 20,
        ),
        returnsNormally,
      );
    });

    test('rejeita schema maior que o app', () {
      expect(
        () => validateBackupManifest(
          BackupManifest(
            formatVersion: 1,
            schemaVersion: 99,
            stationId: 'p',
            appVersion: 'x',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          appSchemaVersion: 20,
        ),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('mais novo'),
          ),
        ),
      );
    });

    test('rejeita formatVersion errado', () {
      expect(
        () => validateBackupManifest(
          BackupManifest(
            formatVersion: 2,
            schemaVersion: 10,
            stationId: 'p',
            appVersion: 'x',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          appSchemaVersion: 20,
        ),
        throwsA(isA<BackupException>()),
      );
    });
  });

  group('ZIP build/parse', () {
    test('export cria 3 entradas e parse round-trip', () {
      final manifest = BackupManifest(
        formatVersion: 1,
        schemaVersion: 20,
        stationId: 'posto-lab',
        appVersion: kBackupAppVersion,
        createdAt: DateTime.utc(2026, 8, 27, 15, 30),
      );
      final prefs = <String, Object?>{
        'mqtt_host': 'mqtt.example',
        'mqtt_port': 1883,
        'station_id': 'posto-lab',
      };
      final sqlite = utf8.encode('SQLite-fake-bytes');
      final zip = buildBackupZipBytes(
        sqliteBytes: sqlite,
        manifest: manifest,
        prefs: prefs,
      );
      expect(zip, isNotEmpty);

      final parsed = parseBackupZipBytes(zip);
      expect(parsed.sqliteBytes, sqlite);
      expect(parsed.manifest.stationId, 'posto-lab');
      expect(parsed.manifest.schemaVersion, 20);
      expect(parsed.prefs['mqtt_host'], 'mqtt.example');
      expect(parsed.prefs['mqtt_port'], 1883);
    });

    test('ZIP sem manifest falha', () {
      expect(
        () => parseBackupZipBytes(utf8.encode('not-a-zip')),
        throwsA(anything),
      );
    });
  });

  group('prefs collect/apply', () {
    test('collectBackupPrefs só inclui chaves conhecidas', () async {
      SharedPreferences.setMockInitialValues({
        'mqtt_host': 'broker',
        'active_operator_id': 7,
        'station_id': 'posto-02',
      });
      final prefs = await SharedPreferences.getInstance();
      final collected = collectBackupPrefs(prefs);
      expect(collected.containsKey('mqtt_host'), isTrue);
      expect(collected.containsKey('station_id'), isTrue);
      expect(collected.containsKey('active_operator_id'), isFalse);
    });

    test('applyBackupPrefs grava subset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await applyBackupPrefs(prefs, {
        'mqtt_host': 'restored-broker',
        'mqtt_port': 443,
        'laser_tcp_port': 9101,
        'active_operator_id': 99,
      });
      expect(prefs.getString('mqtt_host'), 'restored-broker');
      expect(prefs.getInt('mqtt_port'), 443);
      expect(prefs.getInt('laser_tcp_port'), 9101);
      expect(prefs.containsKey('active_operator_id'), isFalse);
    });
  });

  group('defaultBackupFileName', () {
    test('formato sirene_backup_YYYYMMDD_HHMMSS.zip', () {
      final name = defaultBackupFileName(now: DateTime(2026, 8, 27, 10, 5, 9));
      expect(name, 'sirene_backup_20260827_100509.zip');
    });
  });

  group('restore validation on parsed zip', () {
    test('schema maior rejeitado após parse', () {
      final zip = buildBackupZipBytes(
        sqliteBytes: [1, 2, 3],
        manifest: BackupManifest(
          formatVersion: 1,
          schemaVersion: 50,
          stationId: 'x',
          appVersion: '9.0.0',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        prefs: {},
      );
      final parsed = parseBackupZipBytes(zip);
      expect(
        () => validateBackupManifest(parsed.manifest, appSchemaVersion: 20),
        throwsA(isA<BackupException>()),
      );
    });
  });

  test('escreve e lê ZIP em disco temporário', () async {
    final dir = await Directory.systemTemp.createTemp('sirene_backup_test_');
    try {
      final zipPath = '${dir.path}/t.zip';
      final bytes = buildBackupZipBytes(
        sqliteBytes: utf8.encode('db'),
        manifest: BackupManifest(
          formatVersion: 1,
          schemaVersion: 19,
          stationId: 'posto-tmp',
          appVersion: '1.0.1+2',
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        prefs: {'station_id': 'posto-tmp'},
      );
      await File(zipPath).writeAsBytes(bytes);
      final parsed = parseBackupZipBytes(await File(zipPath).readAsBytes());
      expect(utf8.decode(parsed.sqliteBytes), 'db');
      expect(parsed.manifest.stationId, 'posto-tmp');
      validateBackupManifest(parsed.manifest, appSchemaVersion: 20);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
