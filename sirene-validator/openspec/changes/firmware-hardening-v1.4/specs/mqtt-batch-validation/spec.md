## ADDED Requirements

### Requirement: SET_BATCH copia strings com terminador nulo

O firmware SHALL copiar `numero_op`, `id_produto` e `ano` de `SET_BATCH` com função segura que garanta `\0` no final do buffer.

#### Scenario: String no limite do buffer

- **WHEN** `numero_op` no JSON tem 15 caracteres (máximo do buffer de 16)
- **THEN** o valor é armazenado completo e terminado em `\0` sem corrupção de memória

### Requirement: SET_BATCH valida campos obrigatórios e ranges

O firmware SHALL rejeitar `SET_BATCH` com motivo `set_batch_campos_invalidos` quando:

- `tempo_teste` for 0 ou maior que 120 segundos
- `potencia_min` >= `potencia_max`
- `potencia_min` ou `potencia_max` forem negativos
- `quantidade_total` for 0
- `proximo_sequencial` for 0
- `id_produto` não tiver exatamente 3 dígitos
- `ano` não tiver exatamente 2 dígitos

#### Scenario: Limites de potência invertidos

- **WHEN** `potencia_min` é 22.0 e `potencia_max` é 18.0
- **THEN** o firmware publica rejeição `set_batch_campos_invalidos` e não altera o lote

#### Scenario: tempo_teste zero

- **WHEN** `tempo_teste` é 0
- **THEN** o firmware rejeita o comando sem energizar relé em testes subsequentes
