## MODIFIED Requirements

### Requirement: Regras de segurança Firestore
O projeto SHALL definir regras Firestore que restringem operações por coleção: usuários autenticados podem ler dados operacionais; `test_results` não pode ser apagado por operadores; writes devem incluir campos de rastreabilidade obrigatórios (`station_id` em testes e lotes).

#### Scenario: Operador autenticado lê dispositivos
- **WHEN** um usuário autenticado consulta `devices/{deviceId}`
- **THEN** a leitura é permitida

#### Scenario: Tentativa de apagar resultado de teste
- **WHEN** um usuário autenticado tenta `delete` em `test_results/{resultId}`
- **THEN** a operação é negada pelas regras

#### Scenario: Gravação de teste sem station_id
- **WHEN** um write em `test_results` não contém `station_id` ou o campo está vazio
- **THEN** a operação é negada pelas regras

#### Scenario: Upsert idempotente de teste
- **WHEN** o app grava `test_results/{numero_op}_{sequencial}` com os campos obrigatórios e mesma chave composta
- **THEN** a operação de create ou merge é permitida
