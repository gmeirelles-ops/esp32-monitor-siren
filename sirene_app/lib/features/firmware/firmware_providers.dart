import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ota_assist_service.dart';
import 'usb_flash_service.dart';

final otaAssistServiceProvider = Provider<OtaAssistService>((ref) {
  final service = OtaAssistService();
  ref.onDispose(service.stop);
  return service;
});

final usbFlashServiceProvider = Provider<UsbFlashService>((ref) {
  final service = UsbFlashService();
  ref.onDispose(service.cancel);
  return service;
});
