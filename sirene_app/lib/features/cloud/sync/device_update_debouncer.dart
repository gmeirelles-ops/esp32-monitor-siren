class DeviceUpdateDebouncer {
  DeviceUpdateDebouncer({this.interval = const Duration(seconds: 60)});

  final Duration interval;
  final Map<String, DateTime> _lastSent = {};

  bool shouldSendNow(String deviceId, {bool force = false}) {
    if (force) return true;
    final last = _lastSent[deviceId];
    if (last == null) return true;
    return DateTime.now().difference(last) >= interval;
  }

  void recordSent(String deviceId) {
    _lastSent[deviceId] = DateTime.now();
  }

  void reset(String deviceId) => _lastSent.remove(deviceId);
}
