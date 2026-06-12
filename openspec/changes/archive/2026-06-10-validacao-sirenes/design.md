## Context

A linha de produção precisa validar a potência de sirenes e emitir etiquetas de rastreabilidade sem digitação manual. O dispositivo é um ESP32 com firmware em C nativo (ESP-IDF v5.3.2) integrado a:

- **PZEM-004T** via UART para medição de potência ativa.
- **Módulo relé** (GPIO de saída) para acionar a sirene sob teste.
- **Botão push-button** (GPIO com pull-up) para disparar o ciclo de teste.
- **LED/buzzer de status** (GPIO de saída) para feedback local imediato ao operador.
- **Broker MQTT** (endereço hardcoded via `#define`) para comando/status em tempo real.
- **Firebase** + **App Web** para configuração de lote, persistência do histórico e cálculo do dígito verificador.
- **Impressora Zebra ZT230** (ZPL), acionada pelo App Web a partir do buffer de seriais aprovados.

O firmware deve operar de forma resiliente: testes não podem parar por queda de rede, e a integridade do número de série (consumo do sequencial) é crítica para a rastreabilidade.

## Goals / Non-Goals

**Goals:**
- Provisionar Wi-Fi via Captive Portal (SoftAP) e persistir credenciais em NVS.
- Executar o ciclo de teste de forma determinística: botão → relé ON por `tempo_teste` → leitura PZEM → média → veredito.
- Garantir que o sequencial só seja consumido/incrementado quando a sirene for APROVADA.
- Persistir resultados localmente quando offline e sincronizar ao reconectar.
- Bloquear novos testes e alertar quando a UART do PZEM-004T falhar.
- Definir contratos MQTT estáveis para comando, status e calibração.

**Non-Goals:**
- Implementação do App Web e da lógica do dígito verificador ITF 2 de 5 (responsabilidade do App Web).
- Geração/renderização final do ZPL e fila de impressão (responsabilidade do App Web).
- Esquema de coleções/documentos do Firebase (consumido pelo App Web).
- OTA/atualização remota de firmware (fora de escopo desta change).

## Decisions

- **Decisão: Máquina de estados central no firmware.** Estados: `PROVISIONING`, `IDLE`, `BATCH_READY`, `TESTING`, `HARDWARE_FAULT`. A transição `BATCH_READY → TESTING` só ocorre com o botão; cliques durante `TESTING` são ignorados (debounce + flag de teste em andamento).
  - *Alternativa considerada*: tratar comandos MQTT e botão como eventos soltos sem FSM explícita — descartada por dificultar a regra de "ignorar cliques durante o teste" e o bloqueio em falha de hardware.

- **Decisão: Provisionamento via SoftAP + servidor HTTP embarcado em `192.168.4.1`.** Sem redes salvas em NVS, sobe SoftAP; formulário HTML coleta SSID/senha, grava em NVS e reinicia em STA.
  - *Alternativa considerada*: BLE provisioning do ESP-IDF — descartada por exigir app dedicado; o Captive Portal funciona em qualquer navegador do operador.

- **Decisão: Persistência de resultados offline.** Resultados de teste são gravados em armazenamento local (NVS para contadores/estado pequeno; SPIFFS para fila de mensagens acumuladas). Uma task de sincronização em segundo plano faz o dump quando Wi-Fi + MQTT voltam.
  - *Alternativa considerada*: manter apenas em RAM — descartada por perder dados em reboot/queda de energia durante o lote.

- **Decisão: Persistir o lote completo (não só o sequencial) em NVS.** Ao receber `SET_BATCH`, o ESP32 grava em NVS todo o contexto do lote (`numero_op`, `id_produto`, `ano`, `tempo_teste`, `potencia_min`, `potencia_max`, `quantidade_total`, sequencial corrente, aprovados). No boot, se houver lote ativo persistido, ele é restaurado para `BATCH_READY`. O `END_BATCH` limpa esse registro.
  - *Alternativa considerada*: manter apenas o contador em NVS e o resto em RAM — descartada porque um reboot no meio do lote recuperaria o número mas perderia OP/limites/produto, impossibilitando a retomada (exatamente o cenário que a resiliência offline promete cobrir).

- **Decisão: `SET_BATCH` carrega identidade do produto e data.** O payload inclui `id_produto` (3 dígitos) e `ano` (2 dígitos), além de `quantidade_total`. Assim o serial pode ser montado sem depender de RTC no ESP32 (que não tem bateria) nem de NTP em operação offline.
  - *Alternativa considerada*: ESP32 obter o ano via NTP — descartada por exigir rede no momento do teste, incompatível com operação offline; um RTC dedicado seria custo/HW extra desnecessário já que o app conhece a data.

- **Decisão: Sequencial vive no ESP32 durante o lote.** O `proximo_sequencial` chega via `SET_BATCH`; o ESP32 incrementa localmente apenas em APROVAÇÃO e persiste a cada incremento. Em REPROVAÇÃO, o contador permanece idêntico e nenhuma etiqueta é gerada.
  - *Alternativa considerada*: o App Web controlar o sequencial a cada teste — descartada por exigir round-trip de rede por peça, incompatível com operação offline.

- **Decisão: Tópicos MQTT endereçados por dispositivo.** O `device_id` é derivado do MAC do ESP32. Tópicos: comando (sub) `sirene/<device_id>/comando`; publicações `sirene/<device_id>/status`, `sirene/<device_id>/calibracao`, `sirene/<device_id>/alerta`. Permite múltiplos dispositivos na mesma linha sem colisão.
  - *Alternativa considerada*: tópico único `sirene/dispositivo/...` — descartada por impedir roteamento com mais de um aparelho.

- **Decisão: Janela de estabilização (inrush) no cálculo da média.** As leituras dos primeiros instantes do ciclo (padrão sugerido 500 ms) são descartadas antes de calcular a média, para não contaminar o veredito com o pico de partida da sirene. A janela é parametrizável em compilação.
  - *Alternativa considerada*: média sobre todo o ciclo — descartada por sensibilidade ao transiente de arranque.

- **Decisão: Resolução de conflitos de estado.** `SET_BATCH` e `START_CALIBRATION` recebidos durante `TESTING` são rejeitados (o teste corrente prossegue). `START_CALIBRATION` só é aceito sem lote ativo (estado `IDLE`). Comandos rejeitados são reportados via `status`/`alerta`.
  - *Alternativa considerada*: enfileirar comandos — descartada por complexidade e risco de execução fora de contexto.

- **Decisão: Relé em estado seguro no boot.** O GPIO do relé é inicializado como desligado antes de qualquer outra lógica; um reset durante `TESTING` nunca deixa a sirene energizada.

- **Decisão: Cálculo da média de potência no ESP32.** O ESP32 lê continuamente o PZEM durante a janela `tempo_teste`, calcula a média e compara com `potencia_min`/`potencia_max`. O veredito (e a média no Modo Aprendizado) é publicado via MQTT.
  - *Alternativa considerada*: enviar amostras brutas para o App Web calcular — descartada por aumentar tráfego e quebrar em modo offline.

- **Decisão: Impressão em múltiplos de 3 controlada pelo App Web.** O firmware apenas reporta seriais aprovados; o App Web acumula em buffer e emite ZPL a cada 3 etiquetas (rolo 3 colunas, 10x30 mm), com gatilho manual para órfãs (1–2) no fechamento do lote.
  - *Alternativa considerada*: firmware acionar a impressora diretamente — descartada porque a impressora é de rede/USB ligada ao posto do operador, não ao ESP32.

- **Decisão: Broker MQTT hardcoded via `#define`.** Simplifica o provisionamento; apenas as credenciais Wi-Fi são dinâmicas.

## Risks / Trade-offs

- **[Perda do sequencial em reboot durante o lote]** → Persistir o contador atual em NVS a cada incremento (aprovação), não apenas em RAM, para retomar sem duplicar/saltar seriais.
- **[Falha intermitente da UART do PZEM gerar falsos vereditos]** → Em qualquer erro de leitura UART, entrar em `HARDWARE_FAULT`, bloquear novos testes e alertar via MQTT; não computar média parcial como válida.
- **[Acúmulo grande de mensagens offline estourar SPIFFS]** → Fila FIFO com limite máximo definido; ao atingir o limite, sinalizar via LED/alerta e aplicar política de retenção (preservar os vereditos mais antigos não sincronizados); priorizar campos essenciais (OP, série/sequencial, média, status).
- **[Segurança: MQTT sem TLS/credenciais e senha Wi-Fi em HTTP plano no captive portal]** → Risco aceito para rede industrial isolada de chão de fábrica; revisar se o ambiente exigir confidencialidade (TLS + credenciais MQTT, HTTPS no portal).
- **[Reentrância de cliques no botão]** → Debounce em hardware/software + flag de teste em andamento que ignora eventos durante `TESTING`.
- **[Etiquetas órfãs esquecidas no fim do lote]** → Gatilho manual explícito de fechamento que força impressão de 1–2 restantes; sinalizar no App Web quando houver buffer pendente.
- **[Dessincronização de seriais entre ESP32 e Firebase após reconexão]** → A sincronização envia os vereditos com seu sequencial/OP; o backend reconcilia por idempotência (chave OP+sequencial).
