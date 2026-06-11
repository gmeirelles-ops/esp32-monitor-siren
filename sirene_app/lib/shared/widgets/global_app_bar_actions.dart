import 'package:flutter/material.dart';

import 'connection_status.dart';

/// Ações padrão da AppBar, incluindo status MQTT.
List<Widget> globalAppBarActions([List<Widget>? extra]) {
  return [
    const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Center(child: ConnectionStatusBadge()),
    ),
    ...?extra,
  ];
}
