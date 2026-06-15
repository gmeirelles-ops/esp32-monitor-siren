## ADDED Requirements

### Requirement: Tela de relatório de rastreabilidade
O app SHALL oferecer tela "Relatório" na navegação principal para consulta de rastreabilidade de sirenes.

#### Scenario: Acesso à tela
- **WHEN** o operador autenticado seleciona "Relatório" na navegação principal
- **THEN** o app exibe campo de busca por número de série e área de resultado

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
Para um serial selecionado, o relatório SHALL apresentar: produto (derivado do serial), número OP, veredito final, potência média, dispositivo, operador, data/hora de cada tentativa de teste, status de etiqueta e sequência cronológica de tentativas.

#### Scenario: Sirene com tentativas múltiplas
- **WHEN** o serial possui mais de um registro em `test_results` (ex.: reprovação seguida de aprovação)
- **THEN** o relatório exibe timeline ordenada por data com veredito e potência de cada tentativa

#### Scenario: Dados de etiqueta
- **WHEN** o serial possui entrada no buffer de etiquetas
- **THEN** o relatório indica que a etiqueta foi gerada e exibe data da geração

#### Scenario: Produto identificado
- **WHEN** os 3 primeiros dígitos do serial correspondem a produto cadastrado
- **THEN** o relatório exibe nome e código do produto

### Requirement: Reimpressão a partir do relatório
O app SHALL permitir reimprimir etiqueta ZPL para serial com veredito aprovado a partir do relatório.

#### Scenario: Reimpressão de serial aprovado
- **WHEN** o operador aciona reimpressão em serial com último veredito aprovado
- **THEN** o app envia ZPL para a impressora configurada

#### Scenario: Reimpressão bloqueada
- **WHEN** o serial não possui registro aprovado ou não possui serial válido
- **THEN** o app não permite reimpressão e informa o motivo

### Requirement: Performance da busca
A busca por serial SHALL utilizar debounce de 300 ms e limitar resultados de prefixo a no máximo 50 registros.

#### Scenario: Digitação rápida
- **WHEN** o operador digita o serial caractere a caractere
- **THEN** a consulta ao banco só é executada após 300 ms sem nova digitação
