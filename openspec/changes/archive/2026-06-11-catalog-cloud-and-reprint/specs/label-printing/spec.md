## ADDED Requirements

### Requirement: Busca e reimpressão de serial
O app SHALL permitir buscar um serial já validado no histórico local e reimprimir sua etiqueta individual, sem alterar o buffer de impressão corrente.

#### Scenario: Reimpressão de serial existente
- **WHEN** o operador busca um serial presente no histórico e aciona "Reimprimir"
- **THEN** o app envia à impressora o ZPL da etiqueta individual desse serial, sem mexer no buffer de etiquetas pendentes

#### Scenario: Serial inexistente
- **WHEN** o operador busca um serial que não consta no histórico local
- **THEN** o app informa que o serial não foi encontrado e não envia comando de impressão

#### Scenario: Busca parcial
- **WHEN** o operador digita parte de um serial
- **THEN** o app sugere seriais do histórico que contêm o trecho digitado
