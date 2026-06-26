# batch-test-execution Specification

## Purpose
Execução de testes de sirene no firmware ESP32: configuração de lote via MQTT, ciclo botão–relé–PZEM, veredito de potência e publicação de resultados.
## Requirements
### Requirement: Configuração de lote via MQTT
O dispositivo SHALL armazenar os parâmetros de lote recebidos no comando MQTT `SET_BATCH` de forma persistente (NVS) e aguardar o acionamento do botão físico para executar testes.

#### Scenario: Recebimento de SET_BATCH
- **WHEN** o dispositivo recebe no tópico `sirene/<device_id>/comando` um payload com `cmd` igual a `SET_BATCH`
- **THEN** o dispositivo armazena `numero_op`, `id_produto`, `ano`, `tempo_teste`, `potencia_min`, `potencia_max`, `quantidade_total` e `proximo_sequencial`, persiste o contexto do lote em NVS e fica pronto (`BATCH_READY`) para iniciar o teste

### Requirement: Retomada de lote após reboot
O dispositivo SHALL restaurar o lote ativo a partir do contexto persistido em NVS após um reinício, sem perder OP, identidade do produto, limites ou sequencial corrente.

#### Scenario: Reboot com lote ativo
- **WHEN** o dispositivo reinicia e existe um lote ativo persistido em NVS (não encerrado por `END_BATCH`)
- **THEN** o dispositivo restaura todos os parâmetros do lote e o sequencial corrente e retorna ao estado `BATCH_READY`

#### Scenario: Reboot sem lote ativo
- **WHEN** o dispositivo reinicia e não há lote ativo persistido
- **THEN** o dispositivo inicia no estado `IDLE` sem configuração de lote

### Requirement: Encerramento e controle de quantidade do lote
O dispositivo SHALL contabilizar as sirenes aprovadas no lote, SHALL impedir novos testes quando `aprovados >= quantidade_total` com `quantidade_total > 0`, e SHALL encerrar o lote ao receber `END_BATCH`, limpando o contexto persistido.

#### Scenario: Contagem de aprovados
- **WHEN** uma sirene é aprovada
- **THEN** o dispositivo incrementa o contador de aprovados do lote e o disponibiliza nas publicações de `status`

#### Scenario: Encerramento de lote
- **WHEN** o dispositivo recebe `END_BATCH` e nenhum teste está em andamento
- **THEN** o dispositivo limpa o contexto do lote em NVS e retorna ao estado `IDLE`

#### Scenario: Meta de quantidade atingida
- **WHEN** o operador pressiona o botão físico, existe lote ativo e `aprovados >= quantidade_total` com `quantidade_total > 0`
- **THEN** o dispositivo não inicia novo ciclo de teste, sinaliza localmente a condição e publica rejeição identificável quando MQTT estiver disponível

#### Scenario: Quantidade zero ou não limitante
- **WHEN** `quantidade_total` é zero
- **THEN** o dispositivo não aplica bloqueio por cota (comportamento de lote sem meta numérica)

### Requirement: Disparo do teste por botão físico
O dispositivo SHALL iniciar o ciclo de teste somente quando o botão físico for pressionado, e SHALL ignorar acionamentos adicionais enquanto um teste estiver em andamento.

#### Scenario: Início do teste pelo botão
- **WHEN** existe um lote configurado e o operador pressiona o botão físico
- **THEN** o dispositivo ativa o relé pelo tempo definido em `tempo_teste`

#### Scenario: Cliques ignorados durante o teste
- **WHEN** o botão é pressionado novamente enquanto um teste está em andamento
- **THEN** o dispositivo ignora o acionamento e mantém o ciclo de teste corrente

#### Scenario: Botão sem lote configurado
- **WHEN** o botão é pressionado e nenhum lote foi configurado via `SET_BATCH`
- **THEN** o dispositivo não aciona o relé e não inicia teste

### Requirement: Medição de potência e cálculo da média
O dispositivo SHALL ler continuamente os dados do PZEM-004T durante a janela de teste e calcular a potência média do ciclo, descartando uma janela inicial de estabilização (inrush) antes de iniciar a média. Falhas transitórias de leitura UART SHALL ser retentadas por amostra antes de descartar aquela amostra; o ciclo só falha por UART se nenhuma amostra válida for obtida após o descarte de inrush.

#### Scenario: Descarte da janela de inrush
- **WHEN** o relé é acionado e o ciclo de teste inicia
- **THEN** o dispositivo descarta as leituras coletadas durante a janela de estabilização inicial (padrão 500 ms) e não as inclui no cálculo da média

#### Scenario: Coleta durante o ciclo
- **WHEN** a janela de estabilização termina e o relé permanece acionado
- **THEN** o dispositivo realiza leituras contínuas do PZEM-004T e acumula os valores para o cálculo da média

#### Scenario: Encerramento do ciclo
- **WHEN** o tempo `tempo_teste` (em segundos) se esgota
- **THEN** o dispositivo desliga o relé e calcula a potência média das leituras válidas do ciclo

#### Scenario: Falha UART transitória
- **WHEN** uma leitura PZEM falha temporariamente durante o ciclo mas leituras subsequentes na mesma janela de amostra ou em amostras posteriores obtêm sucesso
- **THEN** o dispositivo continua o ciclo e inclui apenas amostras válidas na média

#### Scenario: Falha UART persistente
- **WHEN** o ciclo termina sem nenhuma amostra válida após o descarte de inrush
- **THEN** o dispositivo registra falha de hardware UART, entra em estado de falha e publica alerta conforme contrato existente

### Requirement: Veredito de aprovação ou reprovação
O dispositivo SHALL determinar aprovação ou reprovação comparando a potência média obtida com os limites `potencia_min` e `potencia_max`.

#### Scenario: Sirene aprovada
- **WHEN** a potência média está entre `potencia_min` e `potencia_max` (inclusive)
- **THEN** o dispositivo registra o resultado como APROVADO

#### Scenario: Sirene reprovada
- **WHEN** a potência média está abaixo de `potencia_min` ou acima de `potencia_max`
- **THEN** o dispositivo registra o resultado como REPROVADO

### Requirement: Feedback local ao operador
O dispositivo SHALL sinalizar localmente, via LED/buzzer, o resultado de cada teste e os estados relevantes, independentemente de conexão de rede.

#### Scenario: Sinalização de aprovado/reprovado
- **WHEN** um teste é concluído
- **THEN** o dispositivo aciona o sinal local correspondente (aprovado ou reprovado) mesmo se estiver offline

#### Scenario: Sinalização de falha de hardware
- **WHEN** o dispositivo entra no estado `HARDWARE_FAULT`
- **THEN** o dispositivo apresenta um sinal local distinto indicando falha

### Requirement: Estado seguro do relé
O dispositivo SHALL inicializar o relé desligado no boot e SHALL garantir que nenhum reset deixe a sirene energizada.

#### Scenario: Relé desligado no boot
- **WHEN** o dispositivo é ligado ou reiniciado
- **THEN** o GPIO do relé é inicializado no estado desligado antes de qualquer lógica de teste

#### Scenario: Reset durante teste
- **WHEN** ocorre um reset enquanto o relé estava acionado em um teste
- **THEN** após o boot o relé permanece desligado e nenhum teste é retomado automaticamente sem novo acionamento do botão

### Requirement: Medição PZEM simulada em build de desenvolvimento
O firmware SHALL suportar, quando `CONFIG_DEV_MOCK_PZEM` estiver habilitado em build de desenvolvimento, substituir leituras do PZEM-004T por valores sintéticos configuráveis, mantendo o ciclo completo botão–relé–veredito–publicação MQTT.

#### Scenario: Ciclo com PZEM simulado
- **WHEN** `CONFIG_DEV_MOCK_PZEM` está ativo, existe lote configurado e o operador pressiona o botão físico
- **THEN** o dispositivo executa o ciclo de teste com potência média sintética, calcula veredito e publica resultado em `status` como em produção

#### Scenario: Build de produção sem simulação
- **WHEN** `CONFIG_DEV_MOCK_PZEM` está desabilitado (padrão)
- **THEN** o dispositivo usa exclusivamente leituras reais do PZEM-004T

#### Scenario: Potência sintética variável
- **WHEN** o mock PZEM está ativo
- **THEN** o firmware gera amostras com média pseudoaleatória dentro ou fora dos limites do lote para exercitar aprovados e reprovados

### Requirement: Modo reteste no firmware
O dispositivo SHALL aceitar flag `modo_reteste` na configuração de lote (`SET_BATCH`). Quando `modo_reteste` é verdadeiro, aprovações SHALL NOT incrementar `aprovados` nem `proximo_sequencial`, e SHALL NOT disparar encerramento por cota atingida.

#### Scenario: Aprovação em modo reteste
- **WHEN** `modo_reteste` é true e uma sirene é aprovada
- **THEN** o dispositivo publica resultado MQTT com veredito e potência, mantém `aprovados` e `proximo_sequencial` inalterados e não envia `END_BATCH` por cota

#### Scenario: Reprovação em modo reteste
- **WHEN** `modo_reteste` é true e uma sirene é reprovada
- **THEN** o dispositivo publica resultado MQTT sem alterar contadores do lote

#### Scenario: Modo reteste desativado
- **WHEN** `modo_reteste` é false ou ausente e uma sirene é aprovada
- **THEN** o dispositivo incrementa `aprovados` e `proximo_sequencial` conforme comportamento existente

### Requirement: Persistência de modo reteste
O dispositivo SHALL persistir o valor de `modo_reteste` no contexto de lote em NVS junto aos demais parâmetros até `END_BATCH`.

#### Scenario: Reboot com reteste ativo
- **WHEN** o dispositivo reinicia com lote ativo e `modo_reteste` true em NVS
- **THEN** o modo reteste permanece ativo após restauração do lote

### Requirement: Derivação automática de ano e sequencial no app
O app Flutter SHALL calcular `ano` e `proximo_sequencial` automaticamente antes de enviar `SET_BATCH`, sem entrada manual do operador.

#### Scenario: Ano a partir da data local
- **WHEN** o app prepara um comando `SET_BATCH`
- **THEN** o campo `ano` é definido como os dois últimos dígitos do ano civil local (`DateTime.now().year % 100`, formatado com 2 dígitos)

#### Scenario: Sequencial a partir do contador local
- **WHEN** o app prepara `SET_BATCH` para um `id_produto` e ano derivado
- **THEN** o app consulta `SerialCounters` (ou reconciliação existente) e define `proximo_sequencial` como `(último_sequencial + 1)` para o par `(id_produto, ano)`

#### Scenario: Payload MQTT inalterado
- **WHEN** o app envia `SET_BATCH` após derivação automática
- **THEN** o payload MQTT continua incluindo `ano` e `proximo_sequencial` conforme contrato do firmware

