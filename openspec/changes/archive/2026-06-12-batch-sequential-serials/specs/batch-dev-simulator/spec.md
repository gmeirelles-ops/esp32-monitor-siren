## MODIFIED Requirements

### Requirement: Geração de resultado fictício
O simulador SHALL gerar payload de teste equivalente ao publicado pelo firmware (`tipo: teste`, `numero_op`, `id_produto`, `ano`, `veredito`, `potencia_media`, `sequencial`, `aprovados_no_lote`), com `potencia_media` fictícia, veredito coerente com os limites do produto e **`sequencial` incremental por aprovação no lote** (não reutilizar o valor inicial fixo do `SET_BATCH`).

#### Scenario: Simulação com potência dentro dos limites
- **WHEN** o operador aciona "Simular teste" e a potência gerada está entre `potencia_min` e `potencia_max`
- **THEN** o app processa o resultado como APROVADO, persiste no SQLite, atualiza contadores do dashboard e emite serial com o próximo sequencial disponível do lote

#### Scenario: Simulação com potência fora dos limites
- **WHEN** o operador aciona "Simular teste" e a potência gerada está fora dos limites
- **THEN** o app processa o resultado como REPROVADO sem consumir sequencial de aprovação nem adicionar serial ao buffer

#### Scenario: Quatro simulações aprovadas consecutivas
- **WHEN** o operador simula quatro aprovações seguidas no mesmo lote com `proximo_sequencial: 1`
- **THEN** cada simulação usa sequencial 1, 2, 3 e 4 respectivamente e quatro seriais distintos entram no buffer
