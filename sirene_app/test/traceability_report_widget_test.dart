import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/traceability/batch_report_detail_screen.dart';
import 'package:sirene_app/features/traceability/report_filters.dart';
import 'package:sirene_app/features/traceability/traceability_report_screen.dart';
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

  testWidgets('lista lotes e abre detalhe com sirenes testadas', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-99',
      veredito: 'REPROVADO',
      potenciaMedia: 14,
      sequencial: 3,
      aprovadosNoLote: 0,
      serial: '12326000099',
      operador: '02 — Pedro',
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-99',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 3,
      aprovadosNoLote: 1,
      serial: '12326000099',
      operador: '02 — Pedro',
    );

    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TraceabilityReportScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('OP OP-99'), findsOneWidget);
    await tester.tap(find.textContaining('OP OP-99'));
    await tester.pumpAndSettle();

    expect(find.text('Sirenes testadas (2)'), findsOneWidget);
    expect(find.textContaining('REPROVADO'), findsOneWidget);
    expect(find.textContaining('APROVADO'), findsOneWidget);
  });

  testWidgets('filtro aprovados no detalhe do lote', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-1',
      veredito: 'REPROVADO',
      potenciaMedia: 14,
      sequencial: 1,
      aprovadosNoLote: 0,
    );
    await db.insertTestResult(
      deviceId: 'dev1',
      numeroOp: 'OP-1',
      veredito: 'APROVADO',
      potenciaMedia: 20,
      sequencial: 2,
      aprovadosNoLote: 1,
      serial: '12326000002',
    );

    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: BatchReportDetailScreen(
            numeroOp: 'OP-1',
            filters: const ReportFilters(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sirenes testadas (2)'), findsOneWidget);

    await tester.tap(find.text('Aprovados'));
    await tester.pumpAndSettle();

    expect(find.text('Sirenes testadas (1)'), findsOneWidget);
    expect(find.text('12326000002'), findsOneWidget);
    expect(find.textContaining('REPROVADO'), findsNothing);
  });
}
