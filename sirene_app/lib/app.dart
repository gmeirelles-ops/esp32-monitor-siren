import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/diponto_theme.dart';
import 'features/cloud/sync/sync_providers.dart';
import 'features/admin/admin_screen.dart';
import 'features/batch/batch_screen.dart';
import 'features/devices/devices_screen.dart';
import 'features/labels/labels_screen.dart';
import 'features/products/products_screen.dart';
import 'features/provisioning/provisioning_wizard.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/diponto_app_bar.dart';

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
      if (ref.read(syncEnabledProvider)) {
        ref.read(syncQueueProcessorProvider).start();
      }
    });
  }

  static const _destinations = [
    (icon: Icons.devices, label: 'Dispositivos'),
    (icon: Icons.playlist_add_check, label: 'Lote'),
    (icon: Icons.inventory_2, label: 'Produtos'),
    (icon: Icons.label, label: 'Etiquetas'),
    (icon: Icons.settings, label: 'Configurações'),
    (icon: Icons.admin_panel_settings, label: 'Admin'),
  ];

  static const _screens = [
    DevicesScreen(),
    BatchScreen(),
    ProductsScreen(),
    LabelsScreen(),
    SettingsScreen(),
    AdminScreen(),
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
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Scaffold(
              appBar: DipontoAppBar(
                title: _destinations[_index].label,
                actions: [
                  if (_index == 0)
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
                    backgroundColor: DipontoColors.surfaceVariant,
                    indicatorColor: DipontoColors.primary.withValues(alpha: 0.25),
                    selectedIconTheme: const IconThemeData(color: DipontoColors.primary),
                    selectedLabelTextStyle: const TextStyle(color: DipontoColors.primary),
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
            floatingActionButton: _index == 0
                ? FloatingActionButton(
                    onPressed: () => _openProvisioning(context),
                    child: const Icon(Icons.wifi),
                  )
                : null,
          );
        },
      ),
    );
  }
}
