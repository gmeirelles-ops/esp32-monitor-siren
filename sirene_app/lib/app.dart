import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/layout.dart';
import 'core/providers/core_providers.dart';
import 'core/services/app_log.dart';
import 'core/theme/diponto_theme.dart';
import 'features/cloud/firebase_bootstrap.dart';
import 'features/cloud/sync/sync_providers.dart';
import 'features/demo/demo_constants.dart';
import 'features/demo/demo_providers.dart';
import 'features/ensaio/ensaio_screen.dart';
import 'features/batch/batch_screen.dart';
import 'features/cadastros/cadastros_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/lookup/lookup_screen.dart';
import 'features/labels/labels_screen.dart';
import 'features/labels/marking_providers.dart';
import 'features/mqtt/mqtt_providers.dart';
import 'features/operators/operator_login_screen.dart';
import 'features/operators/operators_provider.dart';
import 'features/provisioning/provisioning_wizard.dart';
import 'features/settings/settings_navigation.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/cloud_setup_screen.dart';
import 'features/setup/posto_setup_screen.dart';
import 'features/traceability/traceability_report_screen.dart';
import 'shared/widgets/app_splash_screen.dart';
import 'shared/widgets/diponto_app_bar.dart';
import 'shared/widgets/demo_mode_banner.dart';
import 'shared/widgets/operational_status_shell.dart';
import 'shared/widgets/operator_switch_button.dart';
import 'shared/widgets/print_failure_shell.dart';

class SireneApp extends ConsumerWidget {
  const SireneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Diponto Validador de Sirenes',
      theme: buildDipontoTheme(),
      builder: (context, child) => OperationalStatusShell(
        child: PrintFailureShell(child: child ?? const SizedBox.shrink()),
      ),
      home: const AppGate(),
    );
  }
}

/// Gate de entrada: exige operador autenticado antes do shell principal.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> with WidgetsBindingObserver {
  String? _bootstrapError;
  bool _bootstrapDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap(ref));
  }

  @override
  void dispose() {
    unawaited(clearOperatorSession(ref));
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(AppLog.write('Lifecycle: $state'));
    if (state == AppLifecycleState.detached) {
      unawaited(clearOperatorSession(ref));
    }
  }

  Future<void> _bootstrap(WidgetRef ref) async {
    final splashStarted = DateTime.now();
    try {
      await AppLog.write('Bootstrap: início');
      await clearOperatorSessionOnStartup(ref);
      await AppLog.write('Bootstrap: sessão ok');

      ref.read(syncQueueProcessorProvider);

      if (ref.read(syncEnabledProvider)) {
        if (isFirebaseAvailable) {
          await ensureFirebaseReady(ref);
          ref.invalidate(syncQueueProcessorProvider);
        }
        ref.read(syncQueueProcessorProvider).start();
      }

      if (ref.read(demoModeProvider)) {
        ref.read(devicesProvider.notifier).ensureDemoDevice(kDemoDeviceId);
      }

      await AppLog.write('Bootstrap: MQTT/devices...');
      ref.read(devicesProvider);
      await AppLog.write('Bootstrap: MQTT/devices ok');

      try {
        final processor = ref.read(markQueueProcessorProvider);
        await processor.ensureRunning();
        processor.start();
        if (processor.lastError != null) {
          await AppLog.write('Bootstrap: laser indisponível', error: processor.lastError);
        }
      } catch (e, st) {
        await AppLog.write('Bootstrap: laser TCP indisponível', error: e, stack: st);
      }
      await AppLog.write('Bootstrap: concluído');
      final elapsed = DateTime.now().difference(splashStarted);
      if (elapsed < AppSplashScreen.minVisibleDuration) {
        await Future<void>.delayed(AppSplashScreen.minVisibleDuration - elapsed);
      }
      if (mounted) {
        setState(() {
          _bootstrapError = null;
          _bootstrapDone = true;
        });
      }
    } catch (e, st) {
      await AppLog.write('Bootstrap: erro', error: e, stack: st);
      if (mounted) {
        setState(() => _bootstrapError = 'Falha ao iniciar serviços: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: DipontoColors.error),
                const SizedBox(height: 16),
                Text(_bootstrapError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _bootstrapError = null);
                    _bootstrap(ref);
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_bootstrapDone) {
      return const AppSplashScreen();
    }

    final activeAsync = ref.watch(activeOperatorProvider);
    final bancadaReady = ref.watch(bancadaSetupCompleteProvider);
    final cloudReady = ref.watch(cloudSetupCompleteProvider);

    return activeAsync.when(
      loading: () => const AppSplashScreen(),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: DipontoColors.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar sessão: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(activeOperatorProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (op) {
        if (op == null) return const OperatorLoginScreen();
        final demoMode = ref.watch(demoModeProvider);
        if (!demoMode && !bancadaReady) return const PostoSetupScreen();
        if (!demoMode && !cloudReady) return const CloudSetupScreen();
        return const SireneAppShell();
      },
    );
  }
}

class SireneAppShell extends ConsumerStatefulWidget {
  const SireneAppShell({super.key});

  @override
  ConsumerState<SireneAppShell> createState() => _SireneAppShellState();
}

class _SireneAppShellState extends ConsumerState<SireneAppShell> {
  int _index = 0;

  List<({Widget screen, IconData icon, String label})> _navEntries(bool isGestor) {
    const labelsEntry = (
      screen: LabelsScreen(),
      icon: Icons.precision_manufacturing,
      label: 'Gravação',
    );

    if (!isGestor) {
      return [
        (screen: const BatchScreen(), icon: Icons.playlist_add_check, label: 'Lote'),
        labelsEntry,
      ];
    }

    return [
      (screen: const BatchScreen(), icon: Icons.playlist_add_check, label: 'Lote'),
      (screen: const DashboardScreen(), icon: Icons.insights, label: 'Painel'),
      (
        screen: const TraceabilityReportScreen(),
        icon: Icons.fact_check_outlined,
        label: 'Relatório',
      ),
      (
        screen: const LookupScreen(),
        icon: Icons.search,
        label: 'Consulta',
      ),
      labelsEntry,
      (
        screen: const CadastrosScreen(),
        icon: Icons.folder_copy_outlined,
        label: 'Cadastros',
      ),
      (
        screen: const EnsaioScreen(),
        icon: Icons.science_outlined,
        label: 'Ensaio',
      ),
      (
        screen: const SettingsScreen(),
        icon: Icons.settings,
        label: 'Configurações',
      ),
    ];
  }

  void _openProvisioning(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProvisioningWizard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGestor = ref.watch(activeOperatorIsGestorProvider);
    final demoMode = ref.watch(demoModeProvider);
    final navEntries = _navEntries(isGestor);
    final safeIndex = _index >= navEntries.length ? 0 : _index;

    ref.listen<String?>(appShellTabRequestProvider, (prev, next) {
      if (next == null) return;
      final idx = navEntries.indexWhere((e) => e.label == next);
      if (idx >= 0) {
        setState(() => _index = idx);
      }
      ref.read(appShellTabRequestProvider.notifier).state = null;
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

        if (isDesktop) {
          return Scaffold(
            appBar: DipontoAppBar(
              title: navEntries[safeIndex].label,
              actions: [
                if (isGestor)
                  IconButton(
                    tooltip: 'Provisionamento Wi-Fi',
                    onPressed: () => _openProvisioning(context),
                    icon: const Icon(Icons.wifi),
                  ),
                const OperatorSwitchButton(),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (demoMode) const DemoModeBanner(compact: true),
                Expanded(
                  child: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: safeIndex,
                        onDestinationSelected: (i) => setState(() => _index = i),
                        labelType: NavigationRailLabelType.all,
                        minWidth: 88,
                        backgroundColor: DipontoColors.surfaceVariant,
                        indicatorShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorColor: DipontoColors.primary.withValues(alpha: 0.15),
                        selectedIconTheme: const IconThemeData(color: DipontoColors.primary),
                        selectedLabelTextStyle: const TextStyle(
                          color: DipontoColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        destinations: [
                          for (final d in navEntries)
                            NavigationRailDestination(
                              icon: Icon(d.icon),
                              label: Text(d.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: navEntries[safeIndex].screen),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (demoMode) const DemoModeBanner(compact: true),
              Expanded(child: navEntries[safeIndex].screen),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final d in navEntries)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
            ],
          ),
        );
      },
    );
  }
}
