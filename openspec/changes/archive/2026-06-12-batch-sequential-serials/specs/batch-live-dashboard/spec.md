## ADDED Requirements

### Requirement: Seriais emitidos no lote corrente
O Batch Live Dashboard SHALL exibir a lista de seriais já emitidos (aprovados com serial) para a OP em acompanhamento, em ordem de sequencial crescente.

#### Scenario: Quatro seriais após quatro aprovações
- **WHEN** quatro testes aprovados com serial foram gravados para a OP exibida
- **THEN** o dashboard lista os quatro seriais com seus sequenciais

#### Scenario: Serial pendente de impressão
- **WHEN** um serial está no buffer de etiquetas da OP
- **THEN** o dashboard indica que o serial aguarda impressão (ícone ou rótulo "pendente")
