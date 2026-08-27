# serial-and-labels Specification

## Purpose
Geração de seriais ITF no app Flutter e disparo da marcação física via fila laser (DiatuCAD).

## Requirements

### Requirement: Cálculo do dígito verificador ITF 2 de 5
O app Flutter SHALL calcular o dígito verificador ITF 2 de 5 a partir dos 9 primeiros dígitos (id_produto + ano + sequencial).

#### Scenario: Dígito verificador calculado
- **WHEN** o app recebe aprovação com id_produto `123`, ano `26` e sequencial `1`
- **THEN** o app calcula o dígito verificador e monta o serial completo de 10 dígitos

#### Scenario: Serial com padding
- **WHEN** o sequencial tem menos de 4 dígitos
- **THEN** o app preenche com zeros à esquerda para compor exatamente 4 dígitos no serial

### Requirement: Geração de serial após aprovação
O app SHALL gerar automaticamente um serial completo e distinto para cada aprovação no lote, usando o `sequencial` informado no resultado do teste (MQTT ou simulador).

#### Scenario: Serial gerado em aprovação
- **WHEN** chega `status` com `tipo: "teste"` e `veredito: "APROVADO"` com `sequencial` N
- **THEN** o app gera o serial de 10 dígitos com sequencial N

### Requirement: Disparo físico somente via fila laser
Após gerar serial aprovado, o app SHALL enfileirar a gravação na `mark_queue` (laser DiatuCAD). O app SHALL NOT acumular buffer ZPL nem enviar comandos a impressora de etiquetas. Texto de UI e specs relacionadas SHALL usar “gravação” / “Regravar”, não “etiqueta” / “reimprimir”, para esse fluxo.

#### Scenario: Aprovação enfileira laser
- **WHEN** um serial aprovado inédito é gerado
- **THEN** existe entrada pendente na fila de gravação laser

#### Scenario: Copy operador
- **WHEN** o gestor consulta um serial aprovado
- **THEN** a ação oferecida é Regravar (fila laser), não reimprimir etiqueta
