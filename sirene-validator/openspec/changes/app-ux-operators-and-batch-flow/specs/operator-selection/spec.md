## ADDED Requirements

### Requirement: Posto exige operador ativo antes do lote

O sistema SHALL exigir seleção de um operador ativo antes de permitir `SET_BATCH` ou retomar lote em andamento.

#### Scenario: Primeiro acesso do turno

- **WHEN** o app abre e não há operador selecionado na sessão
- **THEN** o sistema exibe seletor de operador antes de habilitar ações de lote

#### Scenario: Tentativa sem operador

- **WHEN** o usuário tenta iniciar lote sem operador selecionado
- **THEN** o sistema bloqueia a ação e direciona para o seletor

### Requirement: Operador selecionado persiste na sessão

O sistema SHALL manter o operador ativo em memória e `SharedPreferences` até troca explícita ou logout administrativo.

#### Scenario: Reinício do app no mesmo turno

- **WHEN** o app é fechado e reaberto no mesmo dia com operador previamente selecionado
- **THEN** o operador permanece selecionado e visível no cabeçalho da tela de Lote

### Requirement: Lote e testes registram operador

O sistema SHALL associar `operador_id` e `operador_nome` a cada lote ativo e a cada resultado de teste persistido ou sincronizado.

#### Scenario: Aprovação com operador

- **WHEN** um teste é aprovado com operador "Maria" selecionado
- **THEN** o registro em SQLite e na fila Firestore inclui `operador_id` e `operador_nome`

### Requirement: Operador pode ser trocado entre lotes

O sistema SHALL permitir trocar operador quando não houver teste em andamento no dashboard ao vivo.

#### Scenario: Troca no meio do turno

- **WHEN** não há teste ativo e o usuário escolhe outro operador no cabeçalho
- **THEN** o novo operador passa a valer para lotes e testes subsequentes
