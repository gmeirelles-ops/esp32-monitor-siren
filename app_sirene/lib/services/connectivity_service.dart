import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitora conectividade de rede via [connectivity_plus].
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> get hasConnection async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    return _temConexaoUtil(results);
  }

  bool _temConexaoUtil(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (ConnectivityResult r) =>
          r != ConnectivityResult.none &&
          r != ConnectivityResult.bluetooth,
    );
  }
}
