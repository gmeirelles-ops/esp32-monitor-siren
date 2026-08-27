## ADDED Requirements

### Requirement: Pipeline de testes Flutter em CI
O repositório SHALL executar `flutter test` no diretório `sirene_app` em cada push e pull request para a branch principal.

#### Scenario: PR com testes passando
- **WHEN** um pull request é aberto e todos os testes Flutter passam
- **THEN** o job de CI reporta status de sucesso

#### Scenario: PR com teste falhando
- **WHEN** um pull request introduz uma regressão que quebra um teste unitário
- **THEN** o job de CI reporta falha e o merge deve ser bloqueado pela política do repositório

### Requirement: Pipeline de host tests do firmware em CI
O repositório SHALL compilar e executar os host tests em `sirene-validator/host_tests` em cada push e pull request para a branch principal.

#### Scenario: Host tests passando
- **WHEN** o código em `pure_logic` ou nos testes host não introduz regressão
- **THEN** o job `ctest` completa com sucesso

#### Scenario: Host test falhando
- **WHEN** uma alteração em `pure_logic` quebra FSM, fila FIFO ou cota de lote
- **THEN** o job de CI reporta falha

### Requirement: Comando local espelhando CI
O repositório SHALL fornecer um script documentado que executa os mesmos passos de teste do CI localmente.

#### Scenario: Desenvolvedor valida antes do push
- **WHEN** o desenvolvedor executa o script local de CI
- **THEN** os mesmos testes Flutter e host tests do pipeline são executados com código de saída não-zero em caso de falha
