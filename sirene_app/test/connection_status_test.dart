import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';
import 'package:sirene_app/features/mqtt/mqtt_providers.dart';

void main() {
  group('resolveMqttConnectionDisplayState', () {
    test('uses service state while stream is loading', () {
      expect(
        resolveMqttConnectionDisplayState(
          const AsyncLoading(),
          AppMqttConnectionState.connected,
        ),
        AppMqttConnectionState.connected,
      );
    });

    test('uses stream data when available', () {
      expect(
        resolveMqttConnectionDisplayState(
          const AsyncData(AppMqttConnectionState.reconnecting),
          AppMqttConnectionState.connected,
        ),
        AppMqttConnectionState.reconnecting,
      );
    });

    test('disconnected on stream error', () {
      expect(
        resolveMqttConnectionDisplayState(
          AsyncError(Exception('x'), StackTrace.empty),
          AppMqttConnectionState.connected,
        ),
        AppMqttConnectionState.disconnected,
      );
    });
  });
}
