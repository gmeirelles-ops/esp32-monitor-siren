import 'package:flutter/material.dart';

import '../../core/theme/sirene_colors.dart';
import 'cloud_auth_service.dart';
import 'login_screen.dart';

/// Seção Configurações → Nuvem com card de login / conta conectada.
class CloudSettingsSection extends StatelessWidget {
  const CloudSettingsSection({
    super.key,
    required this.authService,
    required this.syncEnabled,
    required this.stationId,
    required this.onSyncToggle,
    required this.onStationIdChanged,
    required this.onLoginSuccess,
  });

  final CloudAuthService authService;
  final bool syncEnabled;
  final String stationId;
  final ValueChanged<bool> onSyncToggle;
  final ValueChanged<String> onStationIdChanged;
  final VoidCallback onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    return Card(
      color: SireneColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuvem (Firestore)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SireneColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sincronize lotes, testes e cadastros quando houver internet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SireneColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            if (user == null) ...[
              FilledButton.icon(
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(
                        authService: authService,
                        initialStationId: stationId,
                        onStationIdSaved: onStationIdChanged,
                        onSuccess: onLoginSuccess,
                      ),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    onSyncToggle(true);
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Entrar na nuvem'),
                style: FilledButton.styleFrom(
                  backgroundColor: SireneColors.primary,
                  foregroundColor: SireneColors.onPrimary,
                ),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: SireneColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.person, color: SireneColors.primary),
                ),
                title: Text(
                  user.email ?? 'Conta conectada',
                  style: const TextStyle(color: SireneColors.textPrimary),
                ),
                subtitle: Text(
                  stationId.isNotEmpty ? 'Posto: $stationId' : 'Defina o station_id',
                  style: const TextStyle(color: SireneColors.textSecondary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.logout, color: SireneColors.textSecondary),
                  tooltip: 'Sair',
                  onPressed: () async {
                    await authService.signOut();
                    onSyncToggle(false);
                  },
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Sincronização automática',
                  style: TextStyle(color: SireneColors.textPrimary),
                ),
                subtitle: const Text(
                  'Envia fila local ao Firestore quando online',
                  style: TextStyle(color: SireneColors.textSecondary),
                ),
                value: syncEnabled,
                activeThumbColor: SireneColors.primary,
                onChanged: (v) => onSyncToggle(v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
