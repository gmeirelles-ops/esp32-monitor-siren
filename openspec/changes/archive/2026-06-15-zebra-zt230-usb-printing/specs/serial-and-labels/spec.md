## MODIFIED Requirements

### Requirement: Impressão ZPL em múltiplos de 3
O app SHALL enviar comandos ZPL à impressora Zebra somente quando o buffer atinge múltiplo de 3 etiquetas, pelo transporte configurado (USB Windows ou rede TCP).

#### Scenario: Impressão automática em 3
- **WHEN** o buffer atinge 3 seriais
- **THEN** o app gera e envia o comando ZPL para a impressora configurada pelo transporte ativo e remove os 3 seriais do buffer

### Requirement: Configuração da impressora
O app SHALL permitir configurar o modo de impressão **USB (impressora Windows)** ou **Rede (IP e porta)**, persistindo nome da impressora Windows no modo USB ou host/porta no modo rede (padrão porta 9100).

#### Scenario: Impressora USB configurada
- **WHEN** o operador seleciona modo USB e escolhe a impressora `ZDesigner ZT230-203dpi ZPL`
- **THEN** o app persiste o modo e o nome e utiliza envio RAW para essa impressora

#### Scenario: Impressora de rede configurada
- **WHEN** o operador seleciona modo Rede e informa IP `192.168.1.50` e porta `9100`
- **THEN** o app persiste a configuração e utiliza TCP para envio ZPL
