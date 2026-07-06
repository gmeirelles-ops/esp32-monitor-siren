import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene_app/core/database/batch_metrics.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/core/providers/core_providers.dart';
import 'package:sirene_app/shared/portuguese_labels.dart';
import 'package:sirene_app/shared/widgets/screen_page_layout.dart';
import 'package:sirene_app/features/bancadas/bancadas_provider.dart';
import 'package:sirene_app/features/batch/batch_live_providers.dart';
import 'package:sirene_app/features/batch/batch_live_screen.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';
import 'package:sirene_app/features/operators/operators_provider.dart';
import 'package:sirene_app/features/products/products_provider.dart';
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

  const deviceId = 'dev1';
  const numeroOp = '12345';

  const batch = BatchConfig(
    numeroOp: numeroOp,
    idProduto: '071',
    ano: '26',
    tempoTeste: 5,
    potenciaMin: 30.16,
    potenciaMax: 40.8,
    quantidadeTotal: 10,
    proximoSequencial: 1,
  );

  Future<ProviderContainer> buildContainer(
    AppDatabase db, {
    TestResultMessage? lastTestResult,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final device = DeviceInfo(deviceId: deviceId)
      ..estado = DeviceFsmState.batchReady
      ..isOnline = true
      ..activeBatch = batch
      ..lastTestResult = lastTestResult;

    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        devicesProvider.overrideWith(
          (ref) => DevicesNotifier.forTesting(ref, {deviceId: device}),
        ),
        batchLiveTestsProvider(numeroOp).overrideWith((ref) => Stream.value([])),
        batchLiveMetricsProvider(numeroOp).overrideWith(
          (ref) async => const BatchMetrics(total: 0, aprovados: 0, reprovados: 0),
        ),
        labelBufferCountProvider.overrideWith((ref) => Stream.value(0)),
        bancadasMapProvider.overrideWith((ref) => Stream.value({deviceId: 1})),
        productsStreamProvider.overrideWith((ref) => Stream.value([])),
        activeOperatorProvider.overrideWith((ref) => Future.value(null)),
      ],
    );
  }

  Future<void> pumpLiveScreen(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: BatchLiveScreen(deviceId: deviceId, numeroOp: numeroOp),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('hero orienta pressionar botão quando batchReady sem testes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await pumpLiveScreen(tester, container);

    expect(find.text('Pressione o botão no dispositivo'), findsOneWidget);
    expect(find.text(PortugueseLabels.encerrarLote), findsOneWidget);
  });

  testWidgets('hero exibe APROVADO quando lastTestResult presente', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await buildContainer(
      db,
      lastTestResult: const TestResultMessage(
        numeroOp: numeroOp,
        idProduto: '071',
        ano: '26',
        veredito: 'APROVADO',
        potenciaMedia: 37.14,
        sequencial: 17,
        aprovadosNoLote: 5,
      ),
    );
    addTearDown(container.dispose);

    await pumpLiveScreen(tester, container);

    expect(find.text('APROVADO'), findsWidgets);
    expect(find.textContaining('37.14 W'), findsOneWidget);
  });

  testWidgets('ScreenBottomBar contém Encerrar lote', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await buildContainer(db);
    addTearDown(container.dispose);

    await pumpLiveScreen(tester, container);

    expect(find.byType(ScreenBottomBar), findsOneWidget);
    expect(find.text(PortugueseLabels.encerrarLote), findsOneWidget);
  });
}
