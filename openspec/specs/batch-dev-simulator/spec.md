# batch-dev-simulator Specification

## Purpose
TBD - created by archiving change batch-live-dashboard. Update Purpose after archive.
## Requirements
### Requirement: Simulador de teste apenas em desenvolvimento
O app SHALL oferecer ação "Simular teste" somente em builds de desenvolvimento (`kDebugMode` ou flag explícita de dev), ausente em builds de release.

#### Scenario: Botão visível em debug
- **WHEN** o app roda em modo debug e o Batch Live Dashboard está aberto com lote ativo
- **THEN** o app exibe botão "Simular teste"

#### Scenario: Botão ausente em release
- **WHEN** o app roda em modo release
- **THEN** nenhuma ação de simulação de teste é exibida

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

### Requirement: Indicação visual de modo simulado
O dashboard SHALL exibir banner ou badge "MODO DEV — simulação" enquanto o simulador estiver disponível ou tiver sido usado na sessão.

#### Scenario: Banner após simulação
- **WHEN** pelo menos um teste foi simulado na sessão corrente do dashboard
- **THEN** o app mantém indicação visível de que resultados simulados estão presentes

### Requirement: Rastreabilidade de testes simulados
Testes simulados SHALL ser gravados com `operador` identificável como simulação (ex.: `dev-simulator`) para distinção em consultas futuras.

#### Scenario: Operador de simulação no SQLite
- **WHEN** um teste simulado é persistido
- **THEN** o campo `operador` registra identificador de simulação de desenvolvimento

