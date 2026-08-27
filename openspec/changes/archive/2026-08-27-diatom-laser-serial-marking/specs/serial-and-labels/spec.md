## MODIFIED Requirements

### Requirement: Buffer de seriais para impressão
O app SHALL acumular seriais aprovados em buffer local antes de emitir comandos de impressão **somente quando o modo de marcação for Etiquetas (Zebra)**. No modo Gravação laser, o app SHALL enfileirar gravação unitária por serial sem regra de múltiplos de 3.

#### Scenario: Serial adicionado ao buffer (etiquetas)
- **WHEN** o modo é Etiquetas e um serial completo é gerado após aprovação
- **THEN** o app adiciona o serial ao buffer de impressão e atualiza contador visível

#### Scenario: Serial enviado ao laser
- **WHEN** o modo é Gravação laser e um serial completo é gerado após aprovação
- **THEN** o app enfileira/envia gravação unitária ao laser Diatom sem exigir buffer de 3

### Requirement: Impressão ZPL em múltiplos de 3
O app SHALL enviar comandos ZPL à impressora Zebra somente quando o modo Etiquetas estiver ativo e o buffer atingir múltiplos de 3, pelo transporte configurado (USB Windows ou rede TCP).

#### Scenario: Impressão automática em 3 (modo etiquetas)
- **WHEN** o modo é Etiquetas e o buffer atinge 3 seriais
- **THEN** o app envia ZPL com os 3 seriais e esvazia entradas impressas do buffer

#### Scenario: Modo laser sem ZPL
- **WHEN** o modo é Gravação laser
- **THEN** o app não dispara impressão ZPL automática por múltiplos de 3
