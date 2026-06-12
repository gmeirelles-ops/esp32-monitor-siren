## Context

O firmware `sirene-validator` (ESP-IDF) já implementa provisionamento, fluxo de lote, medição PZEM, MQTT, fila offline e monitoramento de hardware. Esta change adiciona uma camada de hardening para operação não-assistida em produção: atualização remota, telemetria de saúde, resiliência de rede/tarefas, provisionamento validado e testes automatizados.

Restrições herdadas do projeto:
- Broker MQTT hardcoded via `#define`; apenas credenciais Wi-Fi são dinâmicas.
- `device_id` derivado do MAC; tópicos no padrão `sirene/<device_id>/...`.
- Operação offline não pode ser interrompida; relé sempre em estado seguro no boot.
- Segurança de transporte (TLS/HTTPS) permanece como risco aceito (fora desta change).

## Goals / Non-Goals

**Goals:**
- OTA via `esp_https_ota` disparado por `OTA_UPDATE` (URL no payload), com verificação e rollback.
- Presença (LWT) e heartbeat periódico com métricas de saúde.
- Watchdog de tarefas e reconexão automática Wi-Fi/MQTT com backoff, sem parar testes.
- Captive portal com scan de redes e validação da conexão antes de persistir.
- Testes de host (CI) para lógica pura: veredito, fila FIFO, FSM e estrutura do serial.

**Non-Goals:**
- TLS/credenciais MQTT e HTTPS no portal (segurança de transporte) — risco aceito.
- Assinatura criptográfica de imagem (Secure Boot / flash encryption) — fora de escopo.
- Testes on-target/HIL automatizados — apenas testes de host nesta change.

## Decisions

- **Decisão: Particionamento OTA.** Migrar de `factory` única para `ota_0` + `ota_1` + `otadata`, mantendo `nvs`, `phy_init` e `storage` (SPIFFS). Requer flash de 4 MB (já configurado).
  - *Alternativa considerada*: manter `factory` e gravar OTA em partição única — descartada por impedir rollback seguro.

- **Decisão: OTA por pull HTTPS de URL recebida via MQTT.** O comando `OTA_UPDATE` traz a `url`; o firmware usa `esp_https_ota`. Confirmação com `esp_ota_mark_app_valid_cancel_rollback()` após boot saudável; caso contrário, rollback automático.
  - *Alternativa considerada*: push do binário via MQTT — descartada por payload grande e ausência de retomada.

- **Decisão: OTA só fora de `TESTING`.** Comando rejeitado durante teste; relé garantido desligado durante o processo. Reaproveita a política de conflito de estado já existente na FSM.

- **Decisão: Telemetria com LWT + heartbeat.** Na conexão MQTT, configurar LWT `offline` retido no tópico `presenca` e publicar `online` ao conectar. Uma task periódica publica `heartbeat` (uptime, RSSI, estado FSM, profundidade da fila, versão de firmware). Intervalo parametrizável via `#define`.
  - *Alternativa considerada*: somente heartbeat sem LWT — descartada por não detectar quedas abruptas em tempo hábil.

- **Decisão: Robustez via TWDT + camada de reconexão.** Registrar tarefas críticas no Task Watchdog. Wi-Fi/MQTT com reconexão por backoff exponencial limitado, dirigida por eventos (handlers já existentes em `wifi_prov`/`mqtt_bridge`), sem bloquear o fluxo de teste.
  - *Alternativa considerada*: reconexão por polling fixo — descartada por reconectar mais lento e gastar mais rádio.

- **Decisão: Provisionamento validado.** O portal faz `esp_wifi_scan` e lista SSIDs; ao submeter, tenta conectar em STA com timeout antes de persistir na NVS. Só grava em caso de sucesso.
  - *Alternativa considerada*: salvar e reiniciar sem validar (comportamento atual) — descartada por permitir credenciais inválidas que exigem reprovisionamento manual.

- **Decisão: Testes de host com lógica pura desacoplada.** Extrair a lógica testável (veredito a partir de média e limites, anel FIFO da fila, transições da FSM, montagem/validação da estrutura do serial) em funções puras sem dependência de ESP-IDF, exercitadas por um build de host (Unity/CMake `linux`).
  - *Alternativa considerada*: testes on-target — descartada nesta change por exigir hardware/QEMU em CI; pode ser uma change futura.

- **Decisão: Worker task para comandos MQTT e botão.** Payloads MQTT e eventos de botão são enfileirados e processados em uma task dedicada (`worker_task`), evitando operações longas (teste, calibração, OTA) no callback do cliente MQTT. O botão usa fila separada com ISR mínima (sem callback direto da ISR).

## Risks / Trade-offs

- **[OTA interrompido por queda de rede deixa imagem parcial]** → `esp_https_ota` grava na partição inativa; só troca o ponteiro de boot após imagem completa e válida; falha mantém a imagem atual.
- **[Boot novo falha silenciosamente]** → Marca de validação só após inicialização saudável; sem confirmação, rollback automático no próximo boot.
- **[Migração de partição quebra dispositivos já gravados com `factory`]** → Primeira gravação com novo layout deve ser por cabo (full flash); documentar no README; OTAs subsequentes ficam disponíveis.
- **[Watchdog reiniciar durante um teste legítimo e longo]** → Alimentar o TWDT na malha de medição; dimensionar timeout acima do maior `tempo_teste` esperado.
- **[Heartbeat/telemetria aumentando tráfego e ruído no broker]** → Intervalo de heartbeat configurável e payload enxuto; presença retida para leitura sob demanda.
- **[Backoff agressivo demais atrasar recuperação / suave demais inundar o rádio]** → Backoff exponencial com teto e jitter.
