import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/widgets/action_section_card.dart';
import '../../../shared/widgets/section_intro.dart';
import '../../cloud/firebase_bootstrap.dart';
import '../../cloud/sync/sync_providers.dart';
import '../settings_category.dart';
import '../widgets/settings_stat_pill.dart';

/// Painel Nuvem extraído de [SettingsScreen] para manutenção.
class SettingsNuvemPanel extends ConsumerWidget {
  const SettingsNuvemPanel({
    super.key,
    required this.category,
    required this.stationIdController,
    required this.syncStatus,
    required this.failedItems,
    required this.authenticated,
    required this.syncEnabled,
    required this.dateFmt,
    required this.onSyncToggle,
    required this.onLogin,
    required this.onLogout,
    required this.onSyncCatalog,
    required this.onPullCatalog,
    required this.onRetryFailed,
  });

  final SettingsCategory category;
  final TextEditingController stationIdController;
  final AsyncValue<SyncStatus> syncStatus;
  final AsyncValue<List<SyncQueueData>> failedItems;
  final bool authenticated;
  final bool syncEnabled;
  final DateFormat dateFmt;
  final ValueChanged<bool> onSyncToggle;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onSyncCatalog;
  final VoidCallback onPullCatalog;
  final void Function({int? itemId}) onRetryFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudNeedsAttention = ref.watch(appConfigProvider).cloudSyncNeedsAttention;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionIntro(
          title: category.title,
          subtitle: category.subtitle,
          icon: category.icon,
        ),
        if (cloudNeedsAttention)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MaterialBanner(
              content: const Text(
                'A nuvem precisa de atenção: faça login, baixe o catálogo ou reprocesse a fila em Configurações.',
              ),
              leading: const Icon(Icons.warning_amber_rounded),
              actions: [
                TextButton(onPressed: onPullCatalog, child: const Text('Baixar catálogo')),
              ],
            ),
          ),
        ActionSectionCard(
          icon: Icons.cloud_sync_outlined,
          title: 'Firestore',
          subtitle: 'Sincronização com a nuvem Diponto',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isFirebaseAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    firebaseUnavailableMessage,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                  ),
                ),
              TextField(
                controller: stationIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do posto (station_id)',
                  helperText: 'Identifica este PC na nuvem. Sync automático a cada 1 min.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sincronizar com Firestore'),
                subtitle: Text(
                  ref.watch(cloudSetupCompleteProvider)
                      ? (authenticated
                          ? 'Obrigatório em produção (não pode desativar)'
                          : 'Sync ativo — faça login na nuvem para enviar dados')
                      : authenticated
                          ? 'Operador autenticado'
                          : 'Login necessário para habilitar',
                ),
                value: syncEnabled,
                onChanged: isFirebaseAvailable ? onSyncToggle : null,
              ),
              if (isFirebaseAvailable && syncEnabled && !authenticated) ...[
                const SizedBox(height: 8),
                Text(
                  'O Firestore exige login Firebase. Sem conta, os envios ficam em '
                  'permission-denied na fila de falhas.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar na nuvem'),
                  ),
                ),
              ],
              syncStatus.when(
                data: (status) => Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    SettingsStatPill(label: 'Pendentes', value: '${status.pending}'),
                    SettingsStatPill(label: 'Falhas', value: '${status.failed}'),
                    SettingsStatPill(
                      label: 'Último sync',
                      value: status.lastSync != null
                          ? dateFmt.format(status.lastSync!.toLocal())
                          : '—',
                    ),
                  ],
                ),
                loading: () => const Text('Carregando status da fila...'),
                error: (e, _) => Text('Erro ao ler fila: $e'),
              ),
              failedItems.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text('Fila com falha', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (final item in items)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              item.documentPath ??
                                  '${item.collection}/${item.documentId}',
                            ),
                            subtitle: Text(
                              item.lastError ?? 'Erro desconhecido',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: TextButton(
                              onPressed: () => onRetryFailed(itemId: item.id),
                              child: const Text('Tentar novamente'),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () => onRetryFailed(),
                          child: const Text('Reprocessar todas as falhas'),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (isFirebaseAvailable && syncEnabled && authenticated) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(onPressed: onSyncCatalog, child: const Text('Enviar catálogo')),
                    OutlinedButton(onPressed: onPullCatalog, child: const Text('Baixar catálogo')),
                    OutlinedButton(
                      onPressed: () async {
                        await kickSyncQueue(ref);
                      },
                      child: const Text('Sincronizar agora'),
                    ),
                  ],
                ),
              ],
              if (authenticated) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(onPressed: onLogout, child: const Text('Sair da conta nuvem')),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
