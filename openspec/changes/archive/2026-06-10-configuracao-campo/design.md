## Context

Hoje o broker MQTT está hardcoded em `board_config.h` (`MQTT_BROKER_URI`). O app Flutter usa defaults em `SharedPreferences` (`192.168.1.100`), enquanto a fábrica Diponto usa outro segmento (`192.168.51.x`). O portal Wi-Fi (`wifi_prov`) persiste SSID/senha em NVS mas não o broker. Dispositivos já provisionados exigem reflash para mudar o broker.

## Goals / Non-Goals

**Goals:**
- Persistir host e porta do broker em NVS, configurável no captive portal
- Usar `#define` apenas como fallback de fábrica
- Reiniciar cliente MQTT após provisionamento com novo broker
- Alinhar documentação e defaults de referência

**Non-Goals:**
- MQTT TLS/autenticação (change futura)
- mDNS / descoberta automática de broker
- Configuração de GPIO via portal (fora de escopo)
- Alterar contratos de tópicos ou payloads

## Decisions

### 1. NVS namespace dedicado para broker

**Decisão:** Novo namespace `mqtt_cfg` com chaves `host` (string, max 64) e `port` (u32).

**Alternativa rejeitada:** Reutilizar `wifi_cfg` — mistura concerns e complica migração.

### 2. Portal HTML estendido

**Decisão:** Adicionar campos opcionais `mqtt_host` e `mqtt_port` ao formulário existente. Se vazios, usar fallback de `board_config.h`.

**Alternativa rejeitada:** Segundo formulário separado — mais cliques para o operador.

### 3. Resolução da URI em runtime

**Decisão:** Função `mqtt_config_get_uri(char *buf, size_t len)` lê NVS → monta `mqtt://host:port` → fallback para `MQTT_BROKER_URI`.

**Alternativa rejeitada:** Reinit completo do `esp_mqtt_client` com URI dinâmica no boot apenas — não cobre re-provisionamento sem reboot (aceitável: reboot após portal já é o fluxo atual).

### 4. Fluxo pós-provisionamento

```
Portal submit → validar STA → gravar wifi_cfg + mqtt_cfg → reboot
     → app_main → mqtt_config_get_uri → mqtt_bridge_init
```

### 5. Defaults documentados

**Decisão:** Manter `board_config.h` como fonte de fallback compile-time; documentar que app e firmware devem ser alinhados manualmente na primeira implantação de rede. Portal elimina divergência futura.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Broker inválido salvo no portal | Validar formato host/porta; opcionalmente testar TCP connect antes de persistir |
| Dispositivos já em campo sem `mqtt_cfg` | Fallback transparente para `#define` — zero breaking change |
| URI malformada | Sanitizar host (sem `://`); porta default 1883 |
| Reboot necessário após mudança | Documentar no portal; mesmo comportamento do Wi-Fi hoje |

## Migration Plan

1. Gravar firmware 1.3.0 — dispositivos existentes continuam com broker de `#define`
2. Re-provisionar via portal apenas se IP do broker mudar
3. Alinhar `PRODUCAO.md` e `app_config.dart` com IP real da fábrica
4. Smoke test: `bench_mqtt_telemetry.sh` após provisionamento

## Open Questions

- Validar conectividade TCP ao broker no portal antes de salvar? (recomendado, pode ser fase 1.1)
- App Flutter deve enviar broker no wizard de provisionamento? (opcional — portal web basta na v1)
