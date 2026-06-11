## Why

O firmware grava o endereço do broker MQTT em compile-time (`MQTT_BROKER_URI` em `board_config.h`), enquanto o app Flutter usa defaults diferentes (`192.168.1.100` vs `192.168.51.87` na fábrica). Na bancada, Wi-Fi conecta mas MQTT nunca estabelece sessão — bloqueando lote, telemetria e monitoramento. Trocar de rede ou IP do Mosquitto exige recompilar e regravar cada ESP32, o que é inviável em produção.

## What Changes

- Persistir **host e porta do broker MQTT** em NVS, configurável via portal de provisionamento Wi-Fi (sem reflash).
- Manter `MQTT_BROKER_URI` em `board_config.h` apenas como **fallback de fábrica** quando NVS estiver vazio.
- Estender o portal captive (`wifi_prov`) com campos opcionais de broker (host + porta).
- Alinhar defaults de documentação (`PRODUCAO.md`, `GUIA_COMPLETO.md`, `app_config.dart`) para um único valor de referência documentado.
- Adicionar script/checklist de smoke test de conectividade MQTT pós-provisionamento.
- Bump de versão de firmware para **1.3.0** após implementação.

## Capabilities

### New Capabilities

_(nenhuma — extensão de capacidades existentes)_

### Modified Capabilities

- `wifi-provisioning`: Portal SHALL aceitar e persistir host/porta do broker MQTT junto com credenciais Wi-Fi.
- `mqtt-messaging`: Dispositivo SHALL usar broker de NVS com fallback para `board_config.h`.
- `system-robustness`: Documentar e validar reconexão MQTT após alteração de broker em campo.

## Impact

- **Firmware**: `wifi_prov/`, novo módulo ou extensão de `mqtt_bridge/`, `board_config.h`, portal HTML em `wifi_prov.c`.
- **App Flutter**: Wizard de provisionamento pode enviar broker junto ao formulário Wi-Fi (opcional na fase 1 — portal web basta).
- **Operação**: Primeiro provisionamento define Wi-Fi + broker; mudanças futuras via portal sem cabo USB.
- **Documentação**: `docs/PRODUCAO.md`, `GUIA_COMPLETO.md`, READMEs.
- **Sem breaking change MQTT**: Tópicos e payloads permanecem iguais; apenas origem da URI muda.
