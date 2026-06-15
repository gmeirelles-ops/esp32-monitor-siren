import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/config/app_config.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/operators/operator_login_screen.dart';
import 'package:sqlite3/open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('libsqlite3.so.0'),
      );
    }
  });

  Future<ProviderContainer> buildContainer(AppDatabase db) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
  }

  testWidgets('login com PIN correto estabelece sessão', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertOperator(codigo: '4321', nome: 'Maria');

    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OperatorLoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Maria'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '4321');
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final config = container.read(appConfigProvider);
    expect(config.activeOperatorId, isNotNull);
  });

  testWidgets('PIN incorreto exibe erro', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.insertOperator(codigo: '1111', nome: 'João');

    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OperatorLoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('João'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '0000');
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.textContaining('PIN incorreto'), findsOneWidget);
    expect(container.read(appConfigProvider).activeOperatorId, isNull);
  });
}
