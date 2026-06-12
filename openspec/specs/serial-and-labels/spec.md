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
O app SHALL gerar automaticamente o serial completo ao receber confirmação de aprovação via MQTT.

#### Scenario: Serial gerado em aprovação
- **WHEN** chega `status` com `tipo: "teste"` e `veredito: "APROVADO"`
- **THEN** o app gera o serial de 10 dígitos e o exibe ao operador

### Requirement: Buffer de seriais para impressão
O app SHALL acumular seriais aprovados em buffer local antes de enviar comandos de impressão.

#### Scenario: Serial adicionado ao buffer
- **WHEN** um serial completo é gerado após aprovação
- **THEN** o app adiciona o serial ao buffer de impressão e atualiza contador visível

### Requirement: Impressão ZPL em múltiplos de 3
O app SHALL enviar comandos ZPL à impressora Zebra somente quando o buffer atinge múltiplo de 3 etiquetas.

#### Scenario: Impressão automática em 3
- **WHEN** o buffer atinge 3 seriais
- **THEN** o app gera e envia o comando ZPL para a impressora configurada e remove os 3 seriais do buffer

### Requirement: Fechamento manual de etiquetas órfãs
O app SHALL oferecer botão de fechamento que imprime seriais restantes (1 ou 2) no buffer.

#### Scenario: Fechamento com órfãs
- **WHEN** o operador aciona "Imprimir pendentes" e há 1 ou 2 seriais no buffer
- **THEN** o app envia ZPL para as etiquetas restantes e esvazia o buffer

### Requirement: Configuração da impressora
O app SHALL permitir configurar IP e porta da impressora Zebra (padrão porta 9100).

#### Scenario: Impressora configurada
- **WHEN** o operador informa IP `192.168.1.50` e porta `9100`
- **THEN** o app persiste a configuração e utiliza esse endereço para envio ZPL

