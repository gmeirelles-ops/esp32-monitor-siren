import 'package:flutter/material.dart';

import '../services/sync_service.dart';
import '../theme/app_colors.dart';

/// Ícone de nuvem no AppBar — reflete [SyncState] em tempo real.
class SyncStatusIcon extends StatefulWidget {
  const SyncStatusIcon({super.key});

  @override
  State<SyncStatusIcon> createState() => _SyncStatusIconState();
}

class _SyncStatusIconState extends State<SyncStatusIcon>
    with SingleTickerProviderStateMixin {
  final SyncService _sync = SyncService.instance;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _sync.state.addListener(_onSyncStateChanged);
    _onSyncStateChanged();
  }

  void _onSyncStateChanged() {
    if (_sync.state.value == SyncState.syncing) {
      if (!_spinController.isAnimating) _spinController.repeat();
    } else {
      _spinController.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sync.state.removeListener(_onSyncStateChanged);
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: _sync.state,
      builder: (BuildContext context, SyncState syncState, Widget? _) {
        return ValueListenableBuilder<int>(
          valueListenable: _sync.pendentesCount,
          builder: (BuildContext context, int pendentes, Widget? _) {
            return _buildIcon(syncState, pendentes);
          },
        );
      },
    );
  }

  Widget _buildIcon(SyncState syncState, int pendentes) {
    final ({IconData icon, Color color, String tooltip}) config =
        _configuracao(syncState, pendentes);

    Widget icon = Icon(config.icon, color: config.color);

    if (syncState == SyncState.syncing) {
      icon = RotationTransition(
        turns: _spinController,
        child: icon,
      );
    } else if (syncState == SyncState.pending) {
      icon = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double opacity, Widget? child) {
          return Opacity(opacity: opacity, child: child);
        },
        onEnd: () {
          if (mounted && _sync.state.value == SyncState.pending) {
            setState(() {});
          }
        },
        child: icon,
      );
    }

    return IconButton(
      icon: icon,
      tooltip: config.tooltip,
      onPressed: syncState == SyncState.syncing
          ? null
          : () => _sync.sincronizar(),
    );
  }

  ({IconData icon, Color color, String tooltip}) _configuracao(
    SyncState syncState,
    int pendentes,
  ) {
    switch (syncState) {
      case SyncState.synced:
        return (
          icon: Icons.cloud_done,
          color: Colors.green.shade700,
          tooltip: 'Online — sincronizado com a nuvem',
        );
      case SyncState.offline:
        final String extra = pendentes > 0 ? ' ($pendentes no cache)' : '';
        return (
          icon: Icons.cloud_off,
          color: Colors.grey.shade700,
          tooltip: 'Offline — testes salvos localmente$extra',
        );
      case SyncState.syncing:
        return (
          icon: Icons.sync,
          color: kDipontoAmber,
          tooltip: 'Sincronizando dados pendentes…',
        );
      case SyncState.pending:
        return (
          icon: Icons.cloud_upload,
          color: Colors.amber.shade800,
          tooltip: 'Online — $pendentes teste(s) aguardando envio',
        );
    }
  }
}
