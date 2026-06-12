## ADDED Requirements

### Requirement: Listener único por conexão MQTT
O app SHALL manter no máximo uma assinatura ativa do stream de mensagens MQTT, cancelando a assinatura anterior e desregistrando callbacks do cliente antigo antes de estabelecer uma nova conexão.

#### Scenario: Reconexão não duplica processamento
- **WHEN** a conexão MQTT cai e o app reconecta (uma ou várias vezes)
- **THEN** cada mensagem recebida é processada exatamente uma vez, sem inserções duplicadas no banco

#### Scenario: Cliente antigo não dispara reconexão espúria
- **WHEN** o app descarta um cliente MQTT antigo durante a reconexão
- **THEN** os callbacks do cliente antigo não agendam novas tentativas de reconexão

### Requirement: Processamento serializado de mensagens
O app SHALL processar as mensagens MQTT recebidas em ordem de chegada, uma por vez, garantindo que o tratamento de um resultado de teste conclua antes do próximo iniciar.

#### Scenario: Aprovações em sequência rápida
- **WHEN** dois resultados de teste aprovados chegam em sequência imediata
- **THEN** a verificação de duplicidade, o incremento do contador de serial e o buffer de etiquetas do primeiro concluem antes do processamento do segundo

#### Scenario: Erro em uma mensagem não interrompe o fluxo
- **WHEN** o processamento de uma mensagem lança exceção
- **THEN** as mensagens seguintes continuam sendo processadas normalmente
