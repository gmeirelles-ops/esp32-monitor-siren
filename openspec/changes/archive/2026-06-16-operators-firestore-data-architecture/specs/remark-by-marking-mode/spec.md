## ADDED Requirements

### Requirement: Ação de remark conforme modo de marcação
O app SHALL oferecer uma ação de remark sobre serial aprovado que depende do `MarkingMode` ativo: em modo etiquetas executa reimpressão ZPL; em modo laser enfileira regravação na fila `mark_queue`.

#### Scenario: Modo etiquetas — reimprimir
- **WHEN** `marking_mode` é `labels` e o operador confirma remark de serial aprovado
- **THEN** o app envia ZPL de reimpressão para a impressora configurada e exibe confirmação com texto "Reimprimir"

#### Scenario: Modo laser — regravar
- **WHEN** `marking_mode` é `laser` e o operador confirma remark de serial aprovado
- **THEN** o serial é enfileirado com prioridade (`pinned`) na fila laser e a UI usa rótulo "Regravar" com instrução para acionar F2 no DiatuCAD

#### Scenario: Serial reprovado
- **WHEN** o operador tenta remark em serial sem aprovação válida
- **THEN** a ação permanece desabilitada ou exibe erro em português

### Requirement: Remark disponível nos pontos de busca por serial
A ação de remark SHALL estar disponível na busca por serial da tela de Etiquetas/Gravação e no detalhe do relatório de lote para seriais aprovados.

#### Scenario: Busca na tela de marcação
- **WHEN** o operador busca serial aprovado na tela de Etiquetas (modo labels) ou Gravação (modo laser)
- **THEN** o botão exibe "Reimprimir" ou "Regravar" conforme o modo

#### Scenario: Detalhe do lote no relatório
- **WHEN** o supervisor abre detalhe de lote e visualiza serial aprovado
- **THEN** a mesma ação de remark está disponível com rótulo coerente ao modo

### Requirement: Auditoria de remark local
O app SHALL registrar cada remark bem-sucedido na tabela `remark_log` com serial, modo (`label` | `laser`), operador e timestamp.

#### Scenario: Reimpressão auditada
- **WHEN** uma reimpressão de etiqueta é concluída com sucesso
- **THEN** existe registro em `remark_log` com `mode: label` e identificação do operador da sessão

#### Scenario: Regravação auditada
- **WHEN** um serial é enfileirado para regravação laser
- **THEN** existe registro em `remark_log` com `mode: laser` e identificação do operador da sessão

### Requirement: Confirmação antes de remark
O app SHALL solicitar confirmação do operador antes de executar remark, com texto específico para impressão ou gravação laser.

#### Scenario: Diálogo em modo laser
- **WHEN** o operador inicia regravação
- **THEN** o diálogo menciona enfileiramento e acionamento F2 no DiatuCAD, sem referência a etiqueta ou rolo de impressora

#### Scenario: Diálogo em modo etiquetas
- **WHEN** o operador inicia reimpressão
- **THEN** o diálogo menciona avanço de linha do rolo Zebra conforme comportamento existente
