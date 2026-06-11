## Why

O firmware `sirene-validator` cobre o fluxo funcional de teste e rastreabilidade, mas ainda não está endurecido para operação contínua em chão de fábrica: não há atualização remota, visibilidade de saúde do dispositivo, reconexão resiliente, validação do provisionamento nem testes automatizados que previnam regressões. Esta change prepara o dispositivo para produção com foco em confiabilidade e operação não-assistida.

## What Changes

- Atualização de firmware OTA acionada por comando MQTT `OTA_UPDATE` (URL no payload), aplicada via `esp_https_ota`, com verificação de imagem e rollback automático em falha.
- Telemetria de presença e saúde: Last Will/Testament MQTT (online/offline) e heartbeat periódico com `uptime`, `rssi`, estado da FSM, profundidade da fila offline e versão de firmware.
- Robustez de sistema: Task Watchdog (TWDT) nas tarefas críticas, reconexão automática de Wi-Fi e MQTT com backoff exponencial e recuperação de falhas sem travar testes.
- Provisionamento aprimorado: o captive portal lista as redes disponíveis (scan) e valida a conexão STA antes de persistir as credenciais na NVS.
- Testes automatizados host-based (CI, sem hardware) para a lógica pura: cálculo de veredito, fila FIFO, máquina de estados e estrutura do número de série.

## Capabilities

### New Capabilities
- `ota-update`: Atualização remota de firmware via URL recebida por MQTT, com validação de imagem e rollback.
- `device-telemetry`: Presença online/offline (LWT) e heartbeat periódico com métricas de saúde do dispositivo.
- `system-robustness`: Watchdog de tarefas, reconexão automática Wi-Fi/MQTT com backoff e recuperação de falhas.

### Modified Capabilities
- `wifi-provisioning`: O portal passa a oferecer scan de redes e a validar a conexão STA antes de salvar as credenciais.
- `mqtt-messaging`: Adiciona o comando `OTA_UPDATE` e os tópicos de telemetria (`presenca`, `heartbeat`).

## Impact

- **Firmware**: Novos componentes (`ota_update`, `telemetry`, robustez em `wifi_prov`/`mqtt_bridge`), uso de `esp_https_ota`, `esp_task_wdt` e partições OTA.
- **Particionamento**: Mudança de `factory` única para esquema OTA (`ota_0`/`ota_1` + `otadata`); requer flash de 4 MB.
- **Contratos MQTT**: Novo comando `OTA_UPDATE`; novos tópicos `sirene/<device_id>/presenca` e `sirene/<device_id>/heartbeat`.
- **Integrações**: App Web/broker passam a consumir presença e heartbeat e a disparar OTA; servidor HTTPS hospedando o binário.
- **CI/Build**: Adição de um alvo de testes de host (build linux/Unity) executável sem o ESP32.
- **Segurança**: Fora de escopo nesta change (MQTT TLS/credenciais e HTTPS do portal seguem como risco aceito, conforme design original).
