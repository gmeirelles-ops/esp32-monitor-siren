## Why

A validação de potência e a rastreabilidade de sirenes na linha de produção dependem hoje de digitação manual e conferência humana, o que gera erros de série, retrabalho e desperdício de etiquetas. É preciso um dispositivo IoT baseado em ESP32 que automatize o teste de conformidade, controle o consumo de números de série, garanta continuidade operacional mesmo sem rede e otimize a impressão de etiquetas de código de barras.

## What Changes

- Novo firmware ESP32 (ESP-IDF v5.3.2) para automação completa do teste de sirenes.
- Provisionamento de Wi-Fi via Captive Portal (SoftAP + servidor HTTP embarcado) com persistência em NVS.
- Fluxo de lote acionado por MQTT (`SET_BATCH`, com `id_produto`, `ano` e `quantidade_total`) e encerrado por `END_BATCH`, com execução de teste disparada por botão físico e leitura contínua do PZEM-004T.
- Cálculo de aprovação/reprovação por potência média comparada a limites configuráveis, descartando uma janela inicial de estabilização (inrush).
- Rastreabilidade por número de série de 10 dígitos com consumo de sequencial condicionado à aprovação.
- Logística de impressão em lotes de 3 etiquetas (Zebra ZT230) com gatilho manual para etiquetas órfãs.
- Modo Aprendizado (`START_CALIBRATION`) para calibração automatizada de potência de referência.
- Resiliência offline: persistência local do lote completo e dos resultados (fila FIFO com limite) e sincronização em segundo plano ao retornar a rede, com retomada de lote após reboot.
- Monitoramento de hardware crítico: trava de testes e alerta MQTT em caso de falha de UART com o PZEM-004T; relé em estado seguro (desligado) no boot.
- Feedback local ao operador via LED/buzzer de status (aprovado/reprovado/falha), independente de conexão.
- Contratos de mensageria MQTT padronizados e endereçados por dispositivo (`sirene/<device_id>/...`) para comando, status, calibração e alerta.

## Capabilities

### New Capabilities
- `wifi-provisioning`: Provisionamento de credenciais Wi-Fi via SoftAP/Captive Portal e persistência em NVS, com transição para modo Station.
- `batch-test-execution`: Configuração e encerramento de lote por MQTT, acionamento por botão físico, controle do relé (estado seguro), feedback local ao operador e cálculo de aprovação/reprovação via PZEM-004T com janela de estabilização.
- `serial-traceability`: Estrutura do número de série de 10 dígitos e regras de consumo/incremento do sequencial conforme resultado do teste.
- `label-printing`: Acúmulo de seriais aprovados e emissão de comandos ZPL em múltiplos de 3 com gatilho de fechamento de lote (Zebra ZT230).
- `calibration-mode`: Modo Aprendizado para medição de potência média de referência e retorno automatizado via MQTT.
- `offline-resilience`: Persistência local de resultados e sincronização em segundo plano após reconexão de rede/broker.
- `hardware-monitoring`: Detecção de perda de comunicação UART com o PZEM-004T, bloqueio de testes e alerta de falha de hardware.
- `mqtt-messaging`: Definição dos contratos de payloads e tópicos MQTT endereçados por dispositivo (`sirene/<device_id>/...`) para comando, status, calibração e alerta de hardware.

### Modified Capabilities
<!-- Nenhuma capability existente; este é o primeiro conjunto de specs do projeto. -->

## Impact

- **Hardware**: ESP32, PZEM-004T (UART), módulo relé (GPIO de saída), botão push-button (GPIO com pull-up), LED/buzzer de status (GPIO de saída).
- **Firmware**: Novo projeto em C nativo sobre ESP-IDF v5.3.2 (Wi-Fi, NVS, HTTP server, UART, MQTT, SPIFFS/NVS para persistência).
- **Integrações**: Broker MQTT (hardcoded via `#define`), Firebase (histórico por lote/OP), App Web do operador, impressora Zebra ZT230 (ZPL).
- **Dados**: Tópicos MQTT endereçados por dispositivo (`sirene/<device_id>/comando`, `.../status`, `.../calibracao`, `.../alerta`) e estrutura do número de série de 10 dígitos com dígito verificador ITF 2 de 5.
