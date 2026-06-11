## MODIFIED Requirements

### Requirement: Parsing de mensagens de status
O app SHALL parsear mensagens JSON de `status` distinguindo `tipo: "teste"`, `tipo: "rejeicao"` e `tipo: "ota"`, e SHALL exibir feedback imediato ao operador para rejeições.

#### Scenario: Resultado de teste parseado
- **WHEN** chega uma mensagem com `tipo: "teste"`
- **THEN** o app extrai numero_op, veredito, potencia_media, sequencial e aprovados_no_lote

#### Scenario: Rejeição de comando parseada
- **WHEN** chega uma mensagem com `tipo: "rejeicao"`
- **THEN** o app extrai o campo motivo, exibe snackbar com o motivo ao operador e registra a última rejeição no dispositivo correspondente

#### Scenario: Rejeição visível na tela de lote
- **WHEN** uma rejeição chega enquanto o operador está configurando um lote
- **THEN** o app exibe snackbar destacado indicando o motivo da rejeição
