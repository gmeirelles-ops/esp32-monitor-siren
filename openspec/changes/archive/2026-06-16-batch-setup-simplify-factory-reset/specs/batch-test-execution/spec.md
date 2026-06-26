## ADDED Requirements

### Requirement: Derivação automática de ano e sequencial no app
O app Flutter SHALL calcular `ano` e `proximo_sequencial` automaticamente antes de enviar `SET_BATCH`, sem entrada manual do operador.

#### Scenario: Ano a partir da data local
- **WHEN** o app prepara um comando `SET_BATCH`
- **THEN** o campo `ano` é definido como os dois últimos dígitos do ano civil local (`DateTime.now().year % 100`, formatado com 2 dígitos)

#### Scenario: Sequencial a partir do contador local
- **WHEN** o app prepara `SET_BATCH` para um `id_produto` e ano derivado
- **THEN** o app consulta `SerialCounters` (ou reconciliação existente) e define `proximo_sequencial` como `(último_sequencial + 1)` para o par `(id_produto, ano)`

#### Scenario: Payload MQTT inalterado
- **WHEN** o app envia `SET_BATCH` após derivação automática
- **THEN** o payload MQTT continua incluindo `ano` e `proximo_sequencial` conforme contrato do firmware
