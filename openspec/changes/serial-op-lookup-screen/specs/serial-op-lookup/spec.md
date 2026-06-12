## ADDED Requirements

### Requirement: Busca por serial
O app SHALL oferecer busca de resultados de teste por serial completo ou prefixo no SQLite local.

#### Scenario: Serial encontrado
- **WHEN** o operador digita um serial ou prefixo válido
- **THEN** o app lista os testes correspondentes com veredito, OP, potência, dispositivo, operador e data

#### Scenario: Serial não encontrado
- **WHEN** não há resultados para o termo buscado
- **THEN** o app informa que nenhum registro foi encontrado

### Requirement: Busca por número OP
O app SHALL permitir listar todos os testes de uma ordem de produção (`numero_op`).

#### Scenario: OP com testes
- **WHEN** o operador informa um `numero_op` existente
- **THEN** o app lista os testes dessa OP ordenados por sequencial ou data

### Requirement: Reimpressão a partir da consulta
O app SHALL permitir reimprimir etiqueta ZPL para um serial aprovado selecionado nos resultados da consulta.

#### Scenario: Reimprimir serial aprovado
- **WHEN** o operador seleciona um resultado aprovado com serial e aciona reimpressão
- **THEN** o app envia ZPL para a impressora configurada

#### Scenario: Reimpressão bloqueada para reprovado
- **WHEN** o resultado selecionado não é aprovado ou não possui serial
- **THEN** o app não oferece reimpressão ou exibe motivo do bloqueio
