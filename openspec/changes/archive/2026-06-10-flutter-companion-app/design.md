## Context

O firmware `sirene-validator` (ESP-IDF v5.3+, v1.1.0) opera como validador de potência na linha de produção Diponto. Ele expõe uma API exclusivamente via MQTT (`sirene/<device_id>/...`), com provisionamento Wi-Fi por captive portal (`SireneValidator` AP → `192.168.4.1`) e teste disparado **somente pelo botão físico**. A arquitetura original previa um App Web para serial ITF 2 de 5, impressão ZPL e Firebase; esse papel será assumido por um app Flutter com identidade visual amber da Diponto.

### Estado atual do firmware (análise completa)

| Área | Implementado | Detalhe |
|------|-------------|---------|
| FSM | ✅ | `PROVISIONING` → `IDLE` → `BATCH_READY` ⇄ `TESTING` + `HARDWARE_FAULT` + `OTA_UPDATING` |
| MQTT comandos | ✅ | `SET_BATCH`, `END_BATCH`, `START_CALIBRATION`, `OTA_UPDATE` |
| MQTT publicações | ✅ | `status`, `calibracao`, `alerta`, `presenca` (LWT), `heartbeat` (30s) |
| Offline | ✅ | Fila SPIFFS (max 64), batch em NVS |
| OTA | ✅ | `esp_https_ota`, relay desligado durante update |
| Telemetria | ✅ | uptime, RSSI, estado, fila, firmware_version |
| Wi-Fi prov | ✅ | Scan + validação STA antes de salvar NVS |
| Testes host | ✅ | pure_logic (veredito, FIFO, FSM, serial validation) |

### Lacunas do firmware para o app (workarounds no Flutter)

| Lacuna | Impacto | Estratégia no app |
|--------|---------|-------------------|
| Sem ACK de `SET_BATCH` | Confirmação ambígua | Aguardar heartbeat `estado: "BATCH_READY"` (timeout 10s, retry) |
| Sem `GET_BATCH` / `GET_STATUS` | Não consulta lote ativo | Rastrear último `SET_BATCH` enviado + heartbeat; exibir dados locais |
| Sem trigger remoto de teste | App não inicia teste | UI "Pressione o botão no dispositivo" em `BATCH_READY` |
| Broker hardcoded (`mqtt://192.168.1.100:1883`) | IP fixo no firmware | Configurar mesmo broker no app; documentar por build |
| Sem TLS/auth MQTT | Qualquer cliente na LAN comanda | Rede isolada de fábrica; TLS em change futura |
| Portal HTML, não JSON | Integração nativa difícil | WebView em `192.168.4.1` ou guia passo-a-passo |
| `quantidade_total` não enforced | Lote não fecha automaticamente | App alerta quando `aprovados_no_lote >= quantidade_total` |
| Fila offline perde tópico original | Calibrações offline vão para `status` | Tratar mensagens `tipo` no stream de status |
| Rejeições não enfileiradas offline | Perda silenciosa | Aceitar; monitorar heartbeat |
| Sem Firebase no firmware | Persistência externa | SQLite local na fase 1; Firebase fase 2 |

## Goals / Non-Goals

**Goals:**
- App Flutter multi-plataforma (Android prioritário para chão de fábrica) com tema Diponto amber.
- Consumir 100% dos contratos MQTT existentes sem alterar firmware.
- Implementar serial ITF 2 de 5, buffer ZPL e fluxo de operador conforme specs OpenSpec.
- Descoberta automática de dispositivos na rede via wildcard MQTT.
- Persistência local de histórico, configuração de broker e dispositivos favoritos.
- Assistente de provisionamento Wi-Fi integrado.

**Non-Goals:**
- Alterações no firmware ESP32 (change separada se necessário).
- Firebase / backend cloud (fase 2).
- MQTT TLS e autenticação (depende de hardening futuro).
- Trigger remoto de teste (decisão de design do firmware: botão físico).
- Suporte a múltiplos brokers simultâneos.
- App para consumidor final — é ferramenta de operador de linha.

## Decisions

### Decisão: Estrutura do projeto `sirene_app/`

```
sirene_app/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # MaterialApp + tema Diponto
│   ├── core/
│   │   ├── theme/diponto_theme.dart
│   │   ├── config/app_config.dart
│   │   └── constants/mqtt_topics.dart
│   ├── features/
│   │   ├── mqtt/                   # Cliente, parser, reconexão
│   │   ├── devices/                # Lista, descoberta, detalhe
│   │   ├── batch/                  # SET_BATCH, progresso
│   │   ├── serial/                 # ITF 2 of 5
│   │   ├── labels/                 # Buffer ZPL, impressão
│   │   ├── provisioning/           # Wizard Wi-Fi
│   │   └── admin/                  # Calibração, OTA
│   └── shared/                     # Widgets, models, utils
├── pubspec.yaml
└── test/
```

- *Alternativa*: monólito em `lib/main.dart` — descartada por complexidade do domínio.

### Decisão: Gerenciamento de estado com Riverpod

Providers para MQTT connection, device list, batch state e label buffer. Streams reativos para mensagens MQTT.

- *Alternativa*: Bloc — válida, mas Riverpod tem menos boilerplate para streams MQTT.

### Decisão: Cliente MQTT `mqtt_client` package

Conexão TCP plain (`mqtt://`) alinhada ao firmware. Subscribe wildcard `sirene/+/heartbeat`, `sirene/+/presenca`, `sirene/+/status`, `sirene/+/calibracao`, `sirene/+/alerta`. Publish em `sirene/<id>/comando`.

Reconexão automática com backoff (1s → 30s max).

- *Alternativa*: `flutter_mqtt_brk` — menos maduro.

### Decisão: Tema Diponto Amber

Paleta derivada da identidade visual do site e merchandising Diponto (camisetas/casacos "ícone amarelo"):

| Token | Hex | Uso |
|-------|-----|-----|
| `primary` | `#FFB300` | AppBar, botões primários, destaques |
| `primaryDark` | `#FF8F00` | Hover, FAB, badges ativos |
| `primaryLight` | `#FFD54F` | Chips, indicadores suaves |
| `surface` | `#1A1A1A` | Fundo principal (dark industrial) |
| `surfaceVariant` | `#2D2D2D` | Cards, painéis |
| `onPrimary` | `#000000` | Texto sobre amber |
| `onSurface` | `#FFFFFF` | Texto principal |
| `error` | `#FF5252` | Reprovações, alertas hardware |
| `success` | `#66BB6A` | Aprovações |

Material 3 `ColorScheme` com `Brightness.dark` e `primary: Color(0xFFFFB300)`.

Logo Diponto no AppBar (asset SVG/PNG).

### Decisão: Confirmação de SET_BATCH via heartbeat

Após enviar `SET_BATCH`, o app inicia timer de 10s aguardando heartbeat com `estado: "BATCH_READY"`. Se timeout, exibe erro e permite retry. Armazena localmente os parâmetros enviados como "lote ativo".

### Decisão: Serial ITF 2 de 5 no app

Algoritmo puro Dart (portável dos host tests do firmware `pure_logic`). Ao receber `status` com `tipo: "teste"` e `veredito: "APROVADO"`, compõe serial: `id_produto(3) + ano(2) + sequencial(4) + checkDigit(1)`.

### Decisão: Impressão ZPL via socket TCP

Zebra ZT230 na rede: envio ZPL direto via `Socket.connect(ip, 9100)`. Buffer local acumula seriais; imprime a cada 3; botão "Fechar lote" para órfãs.

- *Alternativa*: USB — complexo no mobile; reservado para desktop.

### Decisão: Provisionamento via WebView + guia

Tela com instruções numeradas + WebView opcional para `http://192.168.4.1`. Android: `wifi_iot` ou intent para configurações Wi-Fi. iOS: guia manual (restrições de API Wi-Fi).

### Decisão: Persistência local com drift + SQLite

Tabelas: `devices`, `test_results`, `batch_history`, `label_buffer`, `app_settings`. Sem dependência de rede para consultar histórico.

## Risks / Trade-offs

- **[Mobile fora da VLAN do broker]** → Documentar requisito de mesma rede; considerar VPN ou broker bridge em fase 2.
- **[iOS não conecta ao SoftAP programaticamente]** → Guia manual com screenshots; testar em Android primeiro.
- **[Sem ACK de comandos]** → Heartbeat como confirmação; pode haver falso negativo se heartbeat atrasar.
- **[Impressora inacessível do celular]** → Permitir IP configurável; fallback copiar ZPL para clipboard.
- **[Operador esquece órfãs no buffer]** → Badge persistente "N etiquetas pendentes" + alerta no `END_BATCH`.
- **[MQTT sem auth]** → Restringir à rede de fábrica; não expor broker à internet.
- **[Tema amber em ambientes claros]** → Dark theme por padrão (posto industrial); light theme opcional futuro.

## Migration Plan

1. Criar projeto Flutter em `sirene_app/` ao lado de `sirene-validator/`.
2. Implementar MQTT client e dashboard (MVP observável).
3. Adicionar fluxo de lote + serial + labels (MVP operável).
4. Provisionamento e admin (OTA/calibração).
5. Testes em bancada com firmware real + broker Mosquitto.
6. Deploy APK interno (sem store) para operadores.

Rollback: app é independente do firmware; desinstalar APK não afeta dispositivos.

## Open Questions

- IP/porta fixos da impressora Zebra no posto de trabalho?
- Firebase será necessário na fase 1 ou apenas histórico local basta?
- O app roda em tablet fixo no posto ou celular do operador?
- Necessidade de change futura no firmware para `GET_BATCH` e ACK de comandos?
