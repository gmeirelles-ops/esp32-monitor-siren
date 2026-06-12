## MODIFIED Requirements

### Requirement: Geração de serial após aprovação
O app SHALL gerar automaticamente um serial completo e distinto para cada aprovação no lote, usando o `sequencial` informado no resultado do teste (MQTT ou simulador), de modo que múltiplas aprovações na mesma OP produzam múltiplos seriais no buffer.

#### Scenario: Serial gerado em aprovação
- **WHEN** chega `status` com `tipo: "teste"` e `veredito: "APROVADO"` com `sequencial` N
- **THEN** o app gera o serial de 10 dígitos com sequencial N e o adiciona ao buffer se inédito

#### Scenario: Várias aprovações no mesmo lote
- **WHEN** quatro aprovações ocorrem na mesma OP
- **THEN** o buffer contém quatro entradas com seriais diferentes e sequenciais crescentes

## ADDED Requirements

### Requirement: Visibilidade de seriais pendentes por OP
A tela Etiquetas SHALL listar todos os seriais no buffer com OP associada, permitindo ao operador verificar que múltiplas aprovações geraram múltiplas etiquetas pendentes.

#### Scenario: Buffer com quatro seriais
- **WHEN** quatro seriais da mesma OP estão no buffer
- **THEN** a tela Etiquetas exibe quatro itens distintos com seus respectivos códigos
