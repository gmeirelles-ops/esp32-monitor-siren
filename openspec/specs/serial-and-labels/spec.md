# serial-and-labels Specification

## Purpose
Geração de seriais e etiquetas no app Flutter: dígito verificador ITF, formato de código de barras e integração com fluxo de aprovação de testes.
## Requirements
### Requirement: Cálculo do dígito verificador ITF 2 de 5
O app Flutter SHALL calcular o dígito verificador ITF 2 de 5 a partir dos 9 primeiros dígitos (id_produto + ano + sequencial).

#### Scenario: Dígito verificador calculado
- **WHEN** o app recebe aprovação com id_produto `123`, ano `26` e sequencial `1`
- **THEN** o app calcula o dígito verificador e monta o serial completo de 10 dígitos

#### Scenario: Serial com padding
- **WHEN** o sequencial tem menos de 4 dígitos
- **THEN** o app preenche com zeros à esquerda para compor exatamente 4 dígitos no serial

### Requirement: Geração de serial após aprovação
O app SHALL gerar automaticamente um serial completo e distinto para cada aprovação no lote, usando o `sequencial` informado no resultado do teste (MQTT ou simulador), de modo que múltiplas aprovações na mesma OP produzam múltiplos seriais no buffer.

#### Scenario: Serial gerado em aprovação
- **WHEN** chega `status` com `tipo: "teste"` e `veredito: "APROVADO"` com `sequencial` N
- **THEN** o app gera o serial de 10 dígitos com sequencial N e o adiciona ao buffer se inédito

#### Scenario: Várias aprovações no mesmo lote
- **WHEN** quatro aprovações ocorrem na mesma OP
- **THEN** o buffer contém quatro entradas com seriais diferentes e sequenciais crescentes

### Requirement: Buffer de seriais para impressão
O app SHALL acumular seriais aprovados em buffer local antes de enviar comandos de impressão.

#### Scenario: Serial adicionado ao buffer
- **WHEN** um serial completo é gerado após aprovação
- **THEN** o app adiciona o serial ao buffer de impressão e atualiza contador visível

### Requirement: Impressão ZPL em múltiplos de 3
O app SHALL enviar comandos ZPL à impressora Zebra somente quando o buffer atinge múltiplo de 3 etiquetas, pelo transporte configurado (USB Windows ou rede TCP).

#### Scenario: Impressão automática em 3
- **WHEN** o buffer atinge 3 seriais
- **THEN** o app gera e envia o comando ZPL para a impressora configurada pelo transporte ativo e remove os 3 seriais do buffer

### Requirement: Fechamento manual de etiquetas órfãs
O app SHALL oferecer botão de fechamento que imprime seriais restantes (1 ou 2) no buffer.

#### Scenario: Fechamento com órfãs
- **WHEN** o operador aciona "Imprimir pendentes" e há 1 ou 2 seriais no buffer
- **THEN** o app envia ZPL para as etiquetas restantes e esvazia o buffer

### Requirement: Configuração da impressora
O app SHALL permitir configurar o modo de impressão **USB (impressora Windows)** ou **Rede (IP e porta)**, persistindo nome da impressora Windows no modo USB ou host/porta no modo rede (padrão porta 9100).

#### Scenario: Impressora USB configurada
- **WHEN** o operador seleciona modo USB e escolhe a impressora `ZDesigner ZT230-203dpi ZPL`
- **THEN** o app persiste o modo e o nome e utiliza envio RAW para essa impressora

#### Scenario: Impressora de rede configurada
- **WHEN** o operador seleciona modo Rede e informa IP `192.168.1.50` e porta `9100`
- **THEN** o app persiste a configuração e utiliza TCP para envio ZPL

### Requirement: Visibilidade de seriais pendentes por OP
A tela Etiquetas SHALL listar todos os seriais no buffer com OP associada, permitindo ao operador verificar que múltiplas aprovações geraram múltiplas etiquetas pendentes.

#### Scenario: Buffer com quatro seriais
- **WHEN** quatro seriais da mesma OP estão no buffer
- **THEN** a tela Etiquetas exibe quatro itens distintos com seus respectivos códigos

### Requirement: Serial não gerado em modo reteste
O app SHALL NOT gerar serial completo nem adicionar entrada ao buffer de impressão quando o resultado aprovado for processado em modo reteste.

#### Scenario: Aprovação em reteste sem serial
- **WHEN** chega `status` com `veredito: "APROVADO"` e modo reteste está ativo no app
- **THEN** nenhum serial de 10 dígitos é calculado e o buffer de etiquetas permanece inalterado

#### Scenario: Aprovação em produção gera serial
- **WHEN** chega `status` com `veredito: "APROVADO"` e modo reteste está inativo
- **THEN** o app gera serial e adiciona ao buffer conforme requisitos existentes

