## MODIFIED Requirements

### Requirement: Configuração de rede do laser
O app SHALL persistir `laser_tcp_port` e `laser_tcp_command` para o backend TCP servidor. Ao salvar, o app SHALL rejeitar comando vazio e SHALL exibir o valor padrão recomendado `TCP: Give me string` como referência. A UI SHALL alertar que o comando deve ser **idêntico** ao configurado no DiatuCAD em Texto variável → Comunicação TCP/IP.

#### Scenario: Comando vazio ao salvar
- **WHEN** o operador tenta salvar modo laser com comando TCP em branco
- **THEN** o app impede o salvamento e solicita preenchimento

#### Scenario: Comando divergente do padrão
- **WHEN** o operador informa comando diferente de `TCP: Give me string`
- **THEN** o app permite salvar mas exibe aviso para confirmar que o mesmo texto está no DiatuCAD
