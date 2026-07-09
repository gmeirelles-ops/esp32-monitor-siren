import 'package:flutter/material.dart';

enum SettingsCategory {
  posto,
  manutencao,
  rede,
  marcacao,
  nuvem,
  produtividade,
}

extension SettingsCategoryMeta on SettingsCategory {
  String get title => switch (this) {
        SettingsCategory.posto => 'Posto',
        SettingsCategory.manutencao => 'Manutenção',
        SettingsCategory.rede => 'Rede',
        SettingsCategory.marcacao => 'Marcação',
        SettingsCategory.nuvem => 'Nuvem',
        SettingsCategory.produtividade => 'Produtividade',
      };

  String get subtitle => switch (this) {
        SettingsCategory.posto => 'Operador e bancadas',
        SettingsCategory.manutencao => 'Wi-Fi, série e reset',
        SettingsCategory.rede => 'Broker MQTT',
        SettingsCategory.marcacao => 'Gravação laser Diatu',
        SettingsCategory.nuvem => 'Firestore e sync',
        SettingsCategory.produtividade => 'Metas e paradas',
      };

  IconData get icon => switch (this) {
        SettingsCategory.posto => Icons.factory_outlined,
        SettingsCategory.manutencao => Icons.build_circle_outlined,
        SettingsCategory.rede => Icons.hub_outlined,
        SettingsCategory.marcacao => Icons.qr_code_2_outlined,
        SettingsCategory.nuvem => Icons.cloud_outlined,
        SettingsCategory.produtividade => Icons.speed_outlined,
      };
}
