import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/layout.dart';
import 'core/theme/diponto_theme.dart';
import 'features/analytics/analytics_dashboard_screen.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/manager_login_screen.dart';

class ManagerApp extends ConsumerWidget {
  const ManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Diponto Analytics',
      theme: buildDipontoTheme(),
      home: const ManagerGate(),
    );
  }
}

class ManagerGate extends ConsumerWidget {
  const ManagerGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const ManagerLoginScreen(),
      data: (user) => user == null ? const ManagerLoginScreen() : const ManagerShell(),
    );
  }
}

class ManagerShell extends ConsumerWidget {
  const ManagerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Painel'),
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: Text(user.email ?? user.uid)),
                ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DipontoColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DipontoColors.success),
                ),
                child: const Text(
                  'Nuvem OK',
                  style: TextStyle(color: DipontoColors.success, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: () => ref.read(authServiceProvider)?.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1280 : double.infinity),
              child: const AnalyticsDashboardScreen(),
            ),
          ),
        );
      },
    );
  }
}
