import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/firmware/ota_assist_logic.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

void main() {
  group('buildOtaFirmwareUrl', () {
    test('monta URL padrão', () {
      expect(
        buildOtaFirmwareUrl('192.168.51.70', 8080),
        'http://192.168.51.70:8080/sirene-validator.bin',
      );
    });
  });

  group('pickLanIPv4', () {
    test('prefere mesma faixa do broker', () {
      final ip = pickLanIPv4(
        ['10.0.0.5', '192.168.51.70', '192.168.1.10'],
        mqttBrokerHost: '192.168.51.87',
      );
      expect(ip, '192.168.51.70');
    });

    test('fallback para primeiro IP utilizável', () {
      final ip = pickLanIPv4(['10.0.0.5', '172.16.0.2'], mqttBrokerHost: '8.8.8.8');
      expect(ip, '10.0.0.5');
    });

    test('ignora IP WSL 172.20.0.1 e prefere 192.168.x', () {
      final ip = pickLanIPv4(
        ['172.20.0.1', '192.168.51.50'],
        mqttBrokerHost: 'mqtt.diponto.com',
      );
      expect(ip, '192.168.51.50');
    });

    test('isVirtualNetworkInterface detecta WSL/Hyper-V', () {
      expect(isVirtualNetworkInterface('vEthernet (WSL (Hyper-V firewall))'), isTrue);
      expect(isVirtualNetworkInterface('Ethernet'), isFalse);
    });
  });

  group('otaPrecheckError', () {
    test('bloqueia offline', () {
      final d = DeviceInfo(deviceId: 'abc')..isOnline = false;
      expect(otaPrecheckError(d), isNotNull);
    });

    test('bloqueia testing', () {
      final d = DeviceInfo(deviceId: 'abc')
        ..isOnline = true
        ..estado = DeviceFsmState.testing;
      expect(otaPrecheckError(d), contains('Teste'));
    });

    test('permite batch ready', () {
      final d = DeviceInfo(deviceId: 'abc')
        ..isOnline = true
        ..estado = DeviceFsmState.batchReady;
      expect(otaPrecheckError(d), isNull);
    });
  });

  group('isFirmwareBinSizeValid', () {
    test('rejeita arquivo pequeno', () {
      expect(isFirmwareBinSizeValid(1024), isFalse);
    });

    test('aceita binário realista', () {
      expect(isFirmwareBinSizeValid(900000), isTrue);
    });
  });
}
