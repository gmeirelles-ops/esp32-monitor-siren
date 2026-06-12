/// Returns true when [lastSeen] is older than [timeout] relative to [now].
bool isDeviceStale(DateTime? lastSeen, DateTime now, Duration timeout) {
  if (lastSeen == null) {
    return false;
  }
  return now.difference(lastSeen) > timeout;
}
