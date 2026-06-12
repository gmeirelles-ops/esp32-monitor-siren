## Why

MQTT hoje trafega em texto claro na LAN (`mqtt://host:1883`) sem autenticação. Em rede de fábrica compartilhada, qualquer host pode publicar comandos (`SET_BATCH`, `OTA_UPDATE`) ou escutar resultados de teste. Várias changes arquivadas deferiram TLS/auth para change futura.

## What Changes

- Suporte a `mqtts://` com CA embutida ou configurável no firmware (NVS) e no app Flutter.
- Autenticação username/password opcional via NVS (firmware) e Configurações (app).
- Portal de provisionamento Wi-Fi estendido para credenciais MQTT (TLS + user/pass).
- Documentação Mosquitto: listener TLS, `password_file`, ACL por `device_id`.
- **BREAKING** opcional: broker de produção exige TLS — fallback `mqtt://` apenas em dev/Kconfig.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `mqtt-messaging`: URI `mqtts://`, credenciais NVS, validação de certificado
- `mqtt-client`: conexão segura e credenciais no app Flutter
- `wifi-provisioning`: campos TLS/user/pass no portal
- `system-robustness`: reconexão preservando config TLS

## Impact

- **Firmware**: `mqtt_bridge`, `mqtt_config`, portal `wifi_prov`, `board_config.h`
- **App**: `mqtt_service.dart`, `app_config.dart`, Configurações
- **Infra**: Mosquitto, certificados, `docs/PRODUCAO.md`
