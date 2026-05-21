import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'connectivity_service.dart';
import 'database_service.dart';

/// Estado visual da sincronização Hive ↔ Firestore.
enum SyncState {
  /// Online e sem pendências no cache.
  synced,

  /// Sem rede — gravações vão para o Hive.
  offline,

  /// Upload dos registros pendentes em andamento.
  syncing,

  /// Online, porém ainda há itens no cache aguardando envio.
  pending,
}

/// Orquestra conectividade, contagem de pendências e sincronização.
class SyncService extends ChangeNotifier {
  SyncService._();

  static final SyncService instance = SyncService._();

  final ValueNotifier<SyncState> state =
      ValueNotifier<SyncState>(SyncState.synced);

  final ValueNotifier<int> pendentesCount = ValueNotifier<int>(0);

  bool _inicializado = false;
  bool _sincronizando = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Inicializa listeners de rede e do box Hive.
  Future<void> init() async {
    if (_inicializado) return;
    _inicializado = true;

    _connectivitySub =
        ConnectivityService.instance.onConnectivityChanged.listen(
      (_) => unawaited(atualizarEstado(sincronizarSePossivel: true)),
    );

    Hive.box<dynamic>(DatabaseService.boxHistoricoPendentes)
        .listenable()
        .addListener(_onHiveAlterado);

    await atualizarEstado(sincronizarSePossivel: true);
  }

  void _onHiveAlterado() {
    unawaited(atualizarEstado(sincronizarSePossivel: true));
  }

  /// Recalcula estado; opcionalmente dispara upload dos pendentes.
  Future<void> atualizarEstado({bool sincronizarSePossivel = false}) async {
    final int pendentes = DatabaseService.instance.contarPendentes();
    pendentesCount.value = pendentes;

    final bool online = await ConnectivityService.instance.hasConnection;

    if (!online) {
      state.value = SyncState.offline;
      notifyListeners();
      return;
    }

    if (_sincronizando) {
      return;
    }

    if (pendentes == 0) {
      state.value = SyncState.synced;
      notifyListeners();
      return;
    }

    state.value = SyncState.pending;
    notifyListeners();

    if (sincronizarSePossivel) {
      await sincronizar();
    }
  }

  /// Sobe registros pendentes do Hive para o Firestore.
  Future<int> sincronizar() async {
    if (_sincronizando) return 0;

    final bool online = await ConnectivityService.instance.hasConnection;
    if (!online) {
      state.value = SyncState.offline;
      notifyListeners();
      return 0;
    }

    if (DatabaseService.instance.contarPendentes() == 0) {
      state.value = SyncState.synced;
      notifyListeners();
      return 0;
    }

    _sincronizando = true;
    state.value = SyncState.syncing;
    notifyListeners();

    try {
      final int enviados =
          await DatabaseService.instance.sincronizarPendentes();
      debugPrint('SyncService: $enviados registro(s) sincronizado(s).');
      return enviados;
    } finally {
      _sincronizando = false;
      final int restantes = DatabaseService.instance.contarPendentes();
      pendentesCount.value = restantes;

      final bool aindaOnline =
          await ConnectivityService.instance.hasConnection;
      if (!aindaOnline) {
        state.value = SyncState.offline;
      } else if (restantes == 0) {
        state.value = SyncState.synced;
      } else {
        state.value = SyncState.pending;
      }
      notifyListeners();
    }
  }

  /// Chamado após gravar no cache offline.
  void notificarCacheAlterado() {
    unawaited(atualizarEstado(sincronizarSePossivel: true));
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    state.dispose();
    pendentesCount.dispose();
    super.dispose();
  }
}
