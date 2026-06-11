## 1. Particionamento OTA

- [x] 1.1 Atualizar `partitions.csv` para layout OTA (`ota_0`, `ota_1`, `otadata`) mantendo `nvs`, `phy_init` e `storage`
- [x] 1.2 Ajustar `sdkconfig.defaults` (bootloader com rollback / app rollback enable)
- [x] 1.3 Validar tamanhos das partições com flash de 4 MB e documentar no README a primeira gravação por cabo

## 2. Componente OTA

- [x] 2.1 Criar componente `ota_update` (wrapper sobre `esp_https_ota`)
- [x] 2.2 Implementar download/aplicação a partir da `url` recebida
- [x] 2.3 Garantir relé desligado e bloqueio de testes durante o OTA
- [x] 2.4 Marcar imagem válida após boot saudável e habilitar rollback automático
- [x] 2.5 Publicar progresso/falha de OTA via MQTT

## 3. Comando OTA_UPDATE no MQTT

- [x] 3.1 Adicionar parsing do `cmd: "OTA_UPDATE"` com validação da `url`
- [x] 3.2 Rejeitar OTA durante `TESTING` e publicar rejeição
- [x] 3.3 Acionar o componente `ota_update` para comandos válidos

## 4. Telemetria (presença + heartbeat)

- [x] 4.1 Configurar LWT `offline` retido em `sirene/<device_id>/presenca` na conexão MQTT
- [x] 4.2 Publicar `online` ao conectar ao broker
- [x] 4.3 Criar componente `telemetry` com task periódica de heartbeat
- [x] 4.4 Montar payload de heartbeat (`uptime`, `rssi`, `estado`, `fila`, `firmware_version`)
- [x] 4.5 Publicar heartbeat em `sirene/<device_id>/heartbeat` respeitando o estado de conexão

## 5. Robustez de sistema

- [x] 5.1 Registrar tarefas críticas no Task Watchdog (TWDT) e alimentá-lo na malha de medição
- [x] 5.2 Implementar reconexão automática de Wi-Fi com backoff exponencial limitado e jitter
- [x] 5.3 Implementar reconexão automática de MQTT com backoff, retomando publicações pendentes
- [x] 5.4 Garantir que reconexões e reinício por watchdog não interrompam o fluxo de teste nem energizem o relé

## 6. Provisionamento aprimorado

- [x] 6.1 Adicionar scan de redes (`esp_wifi_scan`) e expor a lista no captive portal
- [x] 6.2 Atualizar a página HTML para selecionar SSID da lista ou digitar manualmente
- [x] 6.3 Validar conexão STA com timeout antes de persistir credenciais na NVS
- [x] 6.4 Retornar ao portal com indicação de falha quando a validação não conectar

## 7. Testes de host (CI)

- [x] 7.1 Extrair lógica pura (veredito, anel FIFO, transições da FSM, estrutura do serial) sem dependência de ESP-IDF
- [x] 7.2 Criar projeto/alvo de teste de host (CMake `linux` + Unity)
- [x] 7.3 Escrever casos: veredito dentro/fora dos limites; FIFO cheio/retenção; transições inválidas da FSM; composição do serial de 10 dígitos
- [x] 7.4 Documentar como rodar os testes de host e (opcional) script de CI

## 8. Integração e validação

- [x] 8.1 Compilar firmware completo com novo particionamento OTA
- [x] 8.2 Testar OTA fim-a-fim (URL via MQTT, aplicação, rollback em imagem inválida)
- [x] 8.3 Validar presença (online/offline via LWT) e heartbeat no broker/App Web
- [x] 8.4 Testar reconexão Wi-Fi/MQTT com backoff e watchdog sem parar testes
- [x] 8.5 Testar provisionamento com scan e validação (credenciais válidas e inválidas)
- [x] 8.6 Rodar a suíte de testes de host e confirmar que passa
