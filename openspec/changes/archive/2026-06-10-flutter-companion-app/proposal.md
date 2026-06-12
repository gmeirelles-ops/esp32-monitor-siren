## Why

O firmware `sirene-validator` (v1.1.0) já cobre o ciclo completo de validação de potência, rastreabilidade offline e contratos MQTT estáveis, mas a camada de operação — hoje prevista como **App Web** — ainda não existe. Sem um aplicativo móvel, o operador não consegue configurar lotes, acompanhar testes em tempo real, gerar seriais ITF 2 de 5, imprimir etiquetas Zebra nem monitorar a saúde dos dispositivos na linha de produção. Um app Flutter com identidade visual Diponto (amber) preenche essa lacuna e substitui/complementa o App Web planejado na arquitetura original.

## What Changes

- Criar projeto Flutter (`sirene_app/`) como companion do firmware ESP32, consumindo o broker MQTT existente.
- Implementar tema visual Diponto com paleta **amber** (primária `#FFB300`, secundária `#FF8F00`, fundo escuro `#1A1A1A`, texto `#FFFFFF`) alinhada ao site e merchandising da marca.
- Dashboard de dispositivos: presença (`presenca`), heartbeat (estado FSM, RSSI, fila offline, versão), alertas de hardware e resultados de teste.
- Fluxo de operador: configurar lote (`SET_BATCH`), encerrar lote (`END_BATCH`), acompanhar progresso via `aprovados_no_lote`, aguardar botão físico para teste.
- Geração de serial 10 dígitos (3+2+4+1 ITF 2 de 5) no app ao receber aprovação — responsabilidade que o firmware delega ao App.
- Buffer de impressão ZPL para Zebra ZT230 (múltiplos de 3 + gatilho manual para órfãs).
- Assistente de provisionamento Wi-Fi (guia para AP `SireneValidator` + portal `192.168.4.1`).
- Modo calibração (`START_CALIBRATION`) e painel admin OTA (`OTA_UPDATE`).
- Descoberta de dispositivos via wildcard `sirene/+/heartbeat` e `sirene/+/presenca`.
- Persistência local (SQLite/Hive) para histórico de testes e configuração do broker; Firebase como fase 2 opcional.

## Capabilities

### New Capabilities

- `flutter-app-shell`: Estrutura do app, navegação, tema Diponto amber, configurações globais (broker MQTT, dispositivos favoritos).
- `mqtt-client`: Cliente MQTT Flutter com subscribe/publish nos tópicos `sirene/<device_id>/*`, parsing JSON dos contratos existentes e reconexão automática.
- `device-monitoring`: Dashboard de presença, heartbeat, alertas de hardware, estado FSM e fila offline por dispositivo.
- `batch-operator-ui`: Formulário de lote, envio de `SET_BATCH`/`END_BATCH`, acompanhamento de progresso e indicação "pressione o botão" durante `BATCH_READY`.
- `serial-and-labels`: Cálculo ITF 2 de 5, buffer de seriais aprovados, geração ZPL e impressão em múltiplos de 3 com fechamento manual de órfãs.
- `wifi-provisioning-wizard`: Fluxo guiado para conectar o dispositivo à rede de fábrica via captive portal.
- `calibration-and-ota`: Telas de calibração (`START_CALIBRATION`) e atualização remota (`OTA_UPDATE`) para administradores.

### Modified Capabilities

- `serial-traceability`: O responsável pelo cálculo do dígito verificador passa de "App Web" para "App Flutter" (mesma regra, novo implementador).
- `label-printing`: O responsável pelo buffer ZPL e impressão passa de "App Web" para "App Flutter" (mesma regra, novo implementador).

## Impact

- **Novo repositório/pasta**: `sirene_app/` com projeto Flutter (Android + iOS + opcional desktop/web para posto fixo).
- **Dependências Flutter**: `mqtt_client`, gerenciamento de estado (Riverpod/Bloc), persistência local, `webview_flutter` (portal de provisionamento).
- **Infraestrutura**: Broker MQTT acessível na mesma VLAN/VPN do dispositivo móvel; servidor HTTP/HTTPS para binários OTA.
- **Firmware**: Nenhuma alteração obrigatória — o app consome os contratos MQTT existentes. Lacunas identificadas (sem ACK de `SET_BATCH`, sem `GET_BATCH`, broker hardcoded, sem TLS) são contornadas no app ou tratadas em change futura de firmware.
- **Impressora**: Zebra ZT230 via rede (socket TCP) ou compartilhamento do posto; fora do ESP32.
- **Firebase**: Fora de escopo desta change (fase 2); persistência inicial é local.
