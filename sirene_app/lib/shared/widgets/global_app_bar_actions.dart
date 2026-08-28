import 'package:flutter/material.dart';

import 'connection_status.dart';
import 'sync_status_badge.dart';

/// Ações padrão da AppBar, incluindo status MQTT e fila Firestore (gestor).
List<Widget> globalAppBarActions([List<Widget>? extra]) {
  return [
    const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Center(child: SyncStatusBadge()),
    ),
    const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Center(child: ConnectionStatusBadge()),
    ),
    ...?extra,
  ];
}
