import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/devices/device_detail_screen.dart';
import 'package:sirene_app/features/devices/devices_screen.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/shared/portuguese_labels.dart';
import 'package:sqlite3/open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mac = 'AA:BB:CC:DD:EE:FF';

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  Future<ProviderContainer> buildContainer(
    AppDatabase db, {
    Map<String, DeviceInfo>? devices,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final deviceMap = devices ??
        {
          mac: DeviceInfo(deviceId: mac)
            ..isOnline = true
            ..estado = DeviceFsmState.idle
            ..rssi = -42,
        };
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        devicesProvider.overrideWith(
          (ref) => DevicesNotifier.forTesting(ref, deviceMap),
        ),
      ],
    );
  }

  testWidgets('lista de bancadas exibe Bancada 1 sem MAC no título', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureBancada(mac);

    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DevicesScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Bancada 1'), findsOneWidget);
    expect(find.text(mac), findsNothing);
    expect(find.text(PortugueseLabels.navBancadas), findsOneWidget);
  });

  testWidgets('detalhe da bancada mostra identificador técnico e presença PT', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureBancada(mac);

    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DeviceDetailScreen(deviceId: mac)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Bancada 1'), findsOneWidget);
    expect(find.text(PortugueseLabels.identificadorTecnico), findsOneWidget);
    expect(find.text(mac), findsOneWidget);
    expect(find.text(PortugueseLabels.conectada), findsOneWidget);
  });
}
