import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/diponto_theme.dart';
import '../../features/cloud/sync/sync_providers.dart';
import '../../features/operators/operators_provider.dart';
import '../../features/settings/settings_category.dart';
import '../../features/settings/settings_navigation.dart';

/// Indicador discreto da fila Firestore para o gestor.
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(activeOperatorIsGestorProvider)) {
      return const SizedBox.shrink();
    }

    final statusAsync = ref.watch(syncStatusProvider);
    return statusAsync.when(
      loading: () => const _SyncChip(
        icon: Icons.cloud_queue,
        label: 'Nuvem…',
        color: DipontoColors.onSurface,
      ),
      error: (e, st) => const _SyncChip(
        icon: Icons.cloud_off,
        label: 'Nuvem',
        color: DipontoColors.error,
      ),
      data: (status) {
        final (icon, label, color) = _resolve(status);
        return Tooltip(
          message: _tooltip(status),
          child: InkWell(
            onTap: () => requestSettingsCategory(ref, SettingsCategory.nuvem),
            borderRadius: BorderRadius.circular(20),
            child: _SyncChip(icon: icon, label: label, color: color),
          ),
        );
      },
    );
  }

  (IconData, String, Color) _resolve(SyncStatus status) {
    if (!status.enabled) {
      return (Icons.cloud_off_outlined, 'Sync off', DipontoColors.onSurface.withValues(alpha: 0.55));
    }
    if (!status.firebaseAvailable) {
      return (Icons.cloud_off_outlined, 'Sem Firebase', DipontoColors.onSurface.withValues(alpha: 0.55));
    }
    if (!status.authenticated) {
      return (Icons.cloud_upload_outlined, 'Login nuvem', Colors.orange.shade700);
    }
    if (status.failed > 0) {
      return (Icons.cloud_off, '${status.failed} falha(s)', DipontoColors.error);
    }
    if (status.pending > 0) {
      return (Icons.cloud_sync, '${status.pending} pend.', Colors.orange.shade800);
    }
    return (Icons.cloud_done_outlined, 'Nuvem em dia', DipontoColors.success);
  }

  String _tooltip(SyncStatus status) {
    if (!status.enabled) return 'Sincronização desligada — toque para Configurações → Nuvem';
    if (!status.authenticated) return 'Faça login na nuvem para enviar dados';
    if (status.failed > 0) {
      return '${status.failed} item(ns) com falha na fila — toque para reprocessar';
    }
    if (status.pending > 0) {
      return '${status.pending} item(ns) aguardando envio';
    }
    if (status.lastSync != null) {
      return 'Última sync: ${DateFormat('dd/MM HH:mm').format(status.lastSync!.toLocal())}';
    }
    return 'Nuvem em dia';
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
