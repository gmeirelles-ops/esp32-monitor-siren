import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mqtt/mqtt_providers.dart';
import 'demo_constants.dart';
import 'demo_providers.dart';

/// Reproduz testes simulados em intervalo fixo enquanto o lote estiver ativo.
class DemoPlaybackController {
  DemoPlaybackController(this._ref) {
    _ref.listen<bool>(demoAutoPlayProvider, (_, playing) {
      if (!playing) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  final Ref _ref;
  Timer? _timer;

  bool get isRunning => _timer != null;

  void start(String deviceId) {
    stop();
    _ref.read(demoAutoPlayProvider.notifier).state = true;
    _timer = Timer.periodic(kDemoAutoplayInterval, (_) => _tick(deviceId));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _ref.read(demoAutoPlayProvider.notifier).state = false;
  }

  Future<void> _tick(String deviceId) async {
    if (!_ref.read(demoModeProvider)) {
      stop();
      return;
    }
    final batch = _ref.read(devicesProvider)[deviceId]?.activeBatch;
    if (batch == null) {
      stop();
      return;
    }
    try {
      await _ref.read(devicesProvider.notifier).simulateTestResult(
            deviceId,
            approvalRate: kDemoDefaultApprovalRate,
          );
    } catch (_) {
      stop();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final demoPlaybackProvider = Provider<DemoPlaybackController>((ref) {
  final controller = DemoPlaybackController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
