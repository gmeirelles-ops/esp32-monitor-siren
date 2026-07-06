import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../cloud/auth/auth_providers.dart';
import '../cloud/auth/login_screen.dart';
import '../cloud/firebase_bootstrap.dart';
import '../cloud/sync/station_heartbeat_service.dart';
import '../cloud/sync/sync_providers.dart';

/// Configuração obrigatória de nuvem em produção: posto + sync + login Firebase.
class CloudSetupScreen extends ConsumerStatefulWidget {
  const CloudSetupScreen({super.key});

  @override
  ConsumerState<CloudSetupScreen> createState() => _CloudSetupScreenState();
}

class _CloudSetupScreenState extends ConsumerState<CloudSetupScreen> {
  final _stationController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stationController.text = ref.read(appConfigProvider).stationId;
      if (isFirebaseAvailable) {
        unawaited(ensureFirebaseReady(ref));
      }
    });
  }

  @override
  void dispose() {
    _stationController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final stationId = _stationController.text.trim();
    if (stationId.isEmpty) {
      _snack('Informe o ID do posto (ex.: posto-01)');
      return;
    }
    if (!isFirebaseAvailable) {
      await _finishWithoutCloud(stationId);
      return;
    }
    if (!ref.read(isAuthenticatedProvider)) {
      _snack('Faça login na nuvem antes de continuar (botão Entrar)');
      await _login();
      return;
    }

    setState(() => _saving = true);
    try {
      final config = ref.read(appConfigProvider);
      await config.setStationId(stationId);
      await config.setSyncEnabled(true);
      ref.read(syncEnabledProvider.notifier).state = true;
      ref.read(syncQueueProcessorProvider).start();
      await config.setCloudSetupComplete(true);
      ref.invalidate(appConfigProvider);
      ref.invalidate(cloudSetupCompleteProvider);
      unawaited(_syncCatalogInBackground());
      unawaited(_recordStationHeartbeat());
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('permission-denied')) {
        _snack(
          'Permissão negada no Firestore. Verifique login e regras da nuvem. '
          'O posto foi configurado localmente; tente baixar o catálogo em Configurações.',
        );
        // Permite seguir mesmo com falha de permissão na nuvem.
        final config = ref.read(appConfigProvider);
        if (!config.cloudSetupComplete) {
          await config.setCloudSetupComplete(true);
          ref.invalidate(appConfigProvider);
          ref.invalidate(cloudSetupCompleteProvider);
        }
      } else {
        _snack('Erro ao concluir: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncCatalogInBackground() async {
    try {
      // Posto baixa catálogo da nuvem; envio manual fica em Configurações.
      await pullCatalogFromCloud(ref);
      await ref.read(syncQueueProcessorProvider).processQueue();
    } catch (_) {
      // Catálogo pode ser sincronizado depois em Configurações.
    }
  }

  Future<void> _recordStationHeartbeat() async {
    try {
      if (!isFirebaseAvailable) return;
      final config = ref.read(appConfigProvider);
      await StationHeartbeatService().recordHeartbeat(
        stationId: config.stationId,
        pendingQueue: await ref.read(databaseProvider).countPending(),
        failedQueue: await ref.read(databaseProvider).countFailed(),
      );
    } catch (_) {}
  }

  Future<void> _finishWithoutCloud(String stationId) async {
    setState(() => _saving = true);
    try {
      final config = ref.read(appConfigProvider);
      await config.setStationId(stationId);
      await config.setCloudSetupComplete(true);
      ref.invalidate(appConfigProvider);
      ref.invalidate(cloudSetupCompleteProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
    );
    if (ok == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(isAuthenticatedProvider);
    final firebaseOk = isFirebaseAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar nuvem')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Identificação do posto na fábrica',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            firebaseOk
                ? 'Para visão consolidada da fábrica, cada PC deve ter um ID único '
                    'e sincronizar com o Firestore.'
                : 'Firebase não está configurado neste build. Informe o ID do posto '
                    'para uso local; a sincronização ficará desativada.',
            style: const TextStyle(color: DipontoColors.primaryLight),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _stationController,
            decoration: const InputDecoration(
              labelText: 'ID do posto (station_id)',
              hintText: 'posto-01',
              border: OutlineInputBorder(),
            ),
          ),
          if (firebaseOk) ...[
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(
                  authenticated ? Icons.cloud_done : Icons.cloud_off,
                  color: authenticated ? DipontoColors.success : DipontoColors.error,
                ),
                title: Text(authenticated ? 'Conectado à nuvem' : 'Login necessário'),
                subtitle: const Text(
                  'Use a conta de supervisor para habilitar o sync automático.',
                ),
                trailing: OutlinedButton(
                  onPressed: _login,
                  child: Text(authenticated ? 'Trocar' : 'Entrar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'O sync com Firestore será ativado automaticamente. '
              'Operadores e produtos podem ser baixados em Configurações.',
              style: TextStyle(fontSize: 13, color: DipontoColors.primaryLight),
            ),
          ],
          const SizedBox(height: 32),
          if (firebaseOk && !authenticated)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Toque em Entrar, faça login Firebase e depois em Concluir configuração.',
                style: TextStyle(color: DipontoColors.error, fontSize: 13),
              ),
            ),
          FilledButton(
            onPressed: (_saving || (firebaseOk && !authenticated)) ? null : _complete,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Concluir configuração'),
          ),
        ],
      ),
    );
  }
}
