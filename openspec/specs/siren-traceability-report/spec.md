# siren-traceability-report Specification

## Purpose
Tela de relatório / consulta de rastreabilidade por número de série: busca local, timeline de tentativas e Regravar (fila laser) para seriais aprovados.

## Requirements

### Requirement: Tela de relatório de rastreabilidade
O app SHALL oferecer tela de consulta/relatório na navegação para rastreabilidade de sirenes.

#### Scenario: Acesso à tela
- **WHEN** o gestor autenticado seleciona Consulta ou Relatório na navegação
- **THEN** o app exibe campo de busca por número de série (ou OP) e área de resultado

### Requirement: Busca por número de série
O app SHALL permitir buscar rastreabilidade por serial completo (10 dígitos) ou prefixo no SQLite local.

#### Scenario: Serial completo encontrado
- **WHEN** o operador informa um serial de 10 dígitos existente no histórico
- **THEN** o app exibe o relatório consolidado dessa sirene

#### Scenario: Prefixo com múltiplos resultados
- **WHEN** o operador informa prefixo que corresponde a mais de um serial
- **THEN** o app lista os seriais correspondentes (até 50) para seleção

#### Scenario: Serial não encontrado
- **WHEN** não há registros para o termo buscado
- **THEN** o app informa que nenhuma sirene foi encontrada

### Requirement: Conteúdo do relatório consolidado
Para um serial selecionado, o relatório SHALL apresentar: produto (derivado do serial), número OP, veredito final, potência média, dispositivo, operador, data/hora de cada tentativa de teste e sequência cronológica de tentativas. O app SHALL NOT depender de status de “etiqueta gerada” baseado em buffer ZPL.

#### Scenario: Sirene com tentativas múltiplas
- **WHEN** o serial possui mais de um registro em `test_results` (ex.: reprovação seguida de aprovação)
- **THEN** o relatório exibe timeline ordenada por data com veredito e potência de cada tentativa

#### Scenario: Produto identificado
- **WHEN** os 3 primeiros dígitos do serial correspondem a produto cadastrado
- **THEN** o relatório exibe nome e código do produto

### Requirement: Regravar a partir do relatório
O app SHALL permitir Regravar (enfileirar na `mark_queue`, pinned) para serial com veredito aprovado a partir do relatório/consulta. O app SHALL NOT oferecer reimpressão ZPL.

#### Scenario: Remark laser
- **WHEN** o gestor aciona Regravar em serial aprovado
- **THEN** o app enfileira na `mark_queue` (pinned) e orienta F2 no DiatuCAD

#### Scenario: Remark bloqueado
- **WHEN** o serial não possui registro aprovado ou não possui serial válido
- **THEN** o app não permite remark e informa o motivo

### Requirement: Performance da busca
A busca por serial SHALL utilizar debounce de 300 ms e limitar resultados de prefixo a no máximo 50 registros.

#### Scenario: Digitação rápida
- **WHEN** o operador digita o serial caractere a caractere
- **THEN** a consulta ao banco só é executada após 300 ms sem nova digitação
