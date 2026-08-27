## MODIFIED Requirements

### Requirement: Processamento sequencial de testes MQTT
O app SHALL processar mensagens de teste de forma a concluir verificação de duplicidade, incremento de serial e enfileiramento laser do primeiro antes do segundo.

#### Scenario: Dois aprovados em sequência
- **WHEN** dois `tipo:teste` APROVADO chegam em sequência rápida
- **THEN** duplicidade, contador e `mark_queue` do primeiro concluem antes do processamento do segundo
