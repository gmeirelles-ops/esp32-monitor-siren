## ADDED Requirements

### Requirement: Serial ITF após aprovação
O app SHALL gerar serial ITF de 10 dígitos (produto + ano + sequencial + DV) para cada aprovação MQTT, sem dependência de impressora.

#### Scenario: Aprovação gera serial
- **WHEN** chega `status` com `tipo: "teste"` e `veredito: "APROVADO"` com sequencial N
- **THEN** o app gera o serial completo e o persiste no histórico local

### Requirement: Disparo físico somente via fila laser
Após gerar serial aprovado, o app SHALL enfileirar a gravação na `mark_queue` (laser DiatuCAD). O app SHALL NOT acumular buffer ZPL nem enviar comandos a impressora de etiquetas.

#### Scenario: Aprovação enfileira laser
- **WHEN** um serial aprovado inédito é gerado
- **THEN** existe entrada pendente na fila de gravação laser

#### Scenario: Sem caminho Zebra
- **WHEN** o operador conclui um lote com aprovações
- **THEN** nenhum comando ZPL é gerado e nenhuma impressora de rede/USB de etiquetas é acionada
