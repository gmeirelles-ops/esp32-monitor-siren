import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/layout.dart';
import 'core/theme/diponto_theme.dart';
import 'features/cadastros/cadastros_screen.dart';
import 'features/cloud/sync/sync_providers.dart';
import 'features/batch/batch_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/labels/labels_screen.dart';
import 'features/mqtt/mqtt_providers.dart';
import 'features/provisioning/provisioning_wizard.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/diponto_app_bar.dart';
import 'shared/widgets/print_failure_shell.dart';

class SireneApp extends ConsumerStatefulWidget {
  const SireneApp({super.key});

  @override
  ConsumerState<SireneApp> createState() => _SireneAppState();
}

class _SireneAppState extends ConsumerState<SireneApp> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncQueueProcessorProvider);
      ref.read(devicesProvider);
      if (ref.read(syncEnabledProvider)) {
        ref.read(syncQueueProcessorProvider).start();
      }
    });
  }

  static const _destinations = [
    (icon: Icons.playlist_add_check, label: 'Lote'),
    (icon: Icons.insights, label: 'Painel'),
    (icon: Icons.label, label: 'Etiquetas'),
    (icon: Icons.folder_copy_outlined, label: 'Cadastros'),
    (icon: Icons.settings, label: 'Configurações'),
  ];

  static const _screens = [
    BatchScreen(),
    DashboardScreen(),
    LabelsScreen(),
    CadastrosScreen(),
    SettingsScreen(),
  ];

  void _openProvisioning(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProvisioningWizard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diponto Sirene Validator',
      theme: buildDipontoTheme(),
      builder: (context, child) => PrintFailureShell(child: child ?? const SizedBox.shrink()),
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

          if (isDesktop) {
            return Scaffold(
              appBar: DipontoAppBar(
                title: _destinations[_index].label,
                actions: [
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
                    selectedIndex: _index,
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
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _screens[_index]),
                ],
              ),
            );
          }

          return Scaffold(
            body: _screens[_index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
          );
        },
      ),
    );
  }
}
