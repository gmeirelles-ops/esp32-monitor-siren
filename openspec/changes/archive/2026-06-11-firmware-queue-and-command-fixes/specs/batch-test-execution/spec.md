## MODIFIED Requirements

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
