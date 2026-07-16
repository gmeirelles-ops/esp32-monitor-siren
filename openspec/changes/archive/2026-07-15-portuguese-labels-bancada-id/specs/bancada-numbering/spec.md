## ADDED Requirements

### Requirement: Numeração sequencial de bancadas
O app SHALL atribuir a cada `device_id` MQTT (MAC) um número inteiro sequencial de bancada começando em 1, persistido localmente, atribuído na primeira detecção do dispositivo e estável entre reinicializações.

#### Scenario: Primeira detecção de nova bancada
- **WHEN** o app recebe a primeira mensagem de um `device_id` ainda não cadastrado
- **THEN** o app cria registro com o próximo número disponível (1 para a primeira bancada da instalação)

#### Scenario: Bancada já cadastrada
- **WHEN** o app recebe mensagens de um `device_id` já cadastrado
- **THEN** o número da bancada permanece o mesmo atribuído anteriormente

### Requirement: Rótulo principal Bancada N
O app SHALL exibir nas telas operacionais, relatórios e exportações CSV o rótulo `Bancada {numero}` em vez do MAC ou `device_id` cru.

#### Scenario: Lista de bancadas
- **WHEN** o operador visualiza a lista de equipamentos
- **THEN** cada item exibe título `Bancada 1`, `Bancada 2`, etc., sem expor o MAC no título

#### Scenario: Relatório de lote
- **WHEN** um teste é listado no relatório por OP
- **THEN** a coluna de bancada exibe `Bancada N` correspondente ao `device_id` gravado

### Requirement: Identificador técnico secundário
O app SHALL disponibilizar o `device_id` (MAC) apenas em tela de detalhe da bancada ou seção técnica, rotulado como identificador técnico, não como nome principal.

#### Scenario: Detalhe da bancada
- **WHEN** o operador abre o detalhe de uma bancada
- **THEN** o app exibe `Bancada N` no título e o MAC em campo secundário identificado como técnico

### Requirement: Backfill de bancadas existentes
Na migração ou primeira execução pós-update, o app SHALL criar registros em `bancadas` para todos os `device_id` já presentes em `test_results`, preservando ordem cronológica aproximada de primeiro uso.

#### Scenario: Histórico com três MAC distintos
- **WHEN** o app migra e existem testes de três `device_id` diferentes
- **THEN** são criadas três bancadas numeradas 1, 2 e 3 conforme ordem do primeiro teste de cada MAC
