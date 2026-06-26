import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/constants/layout.dart';
import 'core/providers/core_providers.dart';
import 'core/theme/diponto_theme.dart';
import 'features/cadastros/cadastros_screen.dart';
import 'features/cloud/sync/sync_providers.dart';
import 'features/batch/batch_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/labels/labels_screen.dart';
import 'features/labels/marking_providers.dart';
import 'features/mqtt/mqtt_providers.dart';
import 'features/operators/operator_login_screen.dart';
import 'features/operators/operators_provider.dart';
import 'features/provisioning/provisioning_wizard.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/posto_setup_screen.dart';
import 'features/traceability/traceability_report_screen.dart';
import 'shared/widgets/diponto_app_bar.dart';
import 'shared/widgets/print_failure_shell.dart';

class SireneApp extends ConsumerWidget {
  const SireneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Diponto Sirene Validator',
      theme: buildDipontoTheme(),
      builder: (context, child) => PrintFailureShell(child: child ?? const SizedBox.shrink()),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await resetOperatorSessionOnStartup(ref);
      ref.read(syncQueueProcessorProvider);
      ref.read(devicesProvider);
      if (ref.read(syncEnabledProvider)) {
        ref.read(syncQueueProcessorProvider).start();
      }
      if (ref.read(appConfigProvider).markingMode == MarkingMode.laser) {
        ref.read(markQueueProcessorProvider).start();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ref.read(sessionOperatorIdProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeOperatorProvider);
    final bancadaReady = ref.watch(bancadaSetupCompleteProvider);

    return activeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const OperatorLoginScreen(),
      data: (op) {
        if (op == null) return const OperatorLoginScreen();
        if (!bancadaReady) return const PostoSetupScreen();
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

  List<({Widget screen, IconData icon, String label})> _navEntries(bool isGestor, bool isLaser) {
    final labelsEntry = (
      screen: const LabelsScreen(),
      icon: isLaser ? Icons.precision_manufacturing : Icons.label,
      label: isLaser ? 'Gravação' : 'Etiquetas',
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
      labelsEntry,
      (
        screen: const CadastrosScreen(),
        icon: Icons.folder_copy_outlined,
        label: 'Cadastros',
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
    final isLaser = ref.watch(appConfigProvider).markingMode == MarkingMode.laser;
    final isGestor = ref.watch(activeOperatorIsGestorProvider);
    final navEntries = _navEntries(isGestor, isLaser);
    final safeIndex = _index >= navEntries.length ? 0 : _index;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

        if (isDesktop) {
          return Scaffold(
            appBar: DipontoAppBar(
              title: navEntries[safeIndex].label,
              actions: [
                if (!isGestor)
                  IconButton(
                    tooltip: 'Trocar operador',
                    onPressed: () => clearOperatorSession(ref),
                    icon: const Icon(Icons.logout),
                  ),
                if (isGestor)
                  IconButton(
                    tooltip: 'Provisionamento Wi-Fi',
                    onPressed: () => _openProvisioning(context),
                    icon: const Icon(Icons.wifi),
                  ),
              ],
            ),
            body: Row(
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
          );
        }

        return Scaffold(
          body: navEntries[safeIndex].screen,
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
