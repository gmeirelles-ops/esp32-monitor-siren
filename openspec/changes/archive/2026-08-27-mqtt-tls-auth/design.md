## Context

Firmware resolve broker via NVS `mqtt_cfg` com fallback `MQTT_BROKER_URI`. App usa `MqttServerClient` com host/porta em SharedPreferences.

Mosquitto em fábrica tipicamente roda em VM Linux na LAN.

## Goals / Non-Goals

**Goals:**
- TLS 1.2+ com verificação de servidor (CA).
- User/pass por dispositivo ou por posto.
- Compatibilidade: modo legado `mqtt://` para bancada de dev.

**Non-Goals:**
- mTLS com certificado por dispositivo (fase 2).
- Integração com cloud MQTT (AWS IoT).
- Criptografia de payload além do TLS.

## Decisions

### 1. NVS mqtt_cfg v2

**Decisão:** estender struct NVS com `use_tls`, `username`, `password`, `ca_pem` (ou thumbprint). Migration: campos ausentes = comportamento legado.

### 2. ESP-TLS no firmware

**Decisão:** `esp_mqtt_client` com `mqtts://` e `cert_pem` da NVS ou cert embutido de fábrica.

### 3. Flutter mqtt_client

**Decisão:** `SecurityContext` com CA em arquivo ou string; campos em Configurações.

### 4. Mosquitto ACL

**Decisão:** cada `device_id` só publica em `sirene/<own_id>/#` e assina `sirene/<own_id>/comando`; app assina `sirene/+/+#` com credencial de posto.

### 5. Rollout

**Decisão:** feature flag Kconfig `CONFIG_MQTT_TLS_REQUIRED` desligado por padrão até broker estar pronto.

## Risks / Trade-offs

- **[Cert expiry]** → documentar renovação anual; alerta em logs 30 dias antes.
- **[Provisionamento mais complexo]** → defaults de fábrica para bancada sem TLS.
- **[OTA URL ainda HTTP]** → change separada de OTA assinado.

## Migration Plan

1. Configurar Mosquitto TLS em staging.
2. Atualizar firmware + app com campos opcionais.
3. Re-provisionar dispositivos ou push OTA de config.
4. Habilitar `TLS_REQUIRED` no broker e depois no firmware.

## Open Questions

- CA interna autoassinada vs Let's Encrypt na VPN?
