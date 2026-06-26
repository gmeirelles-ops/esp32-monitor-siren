## MODIFIED Requirements

### Requirement: Servidor TCP para texto variável DiatuCAD
O app SHALL atuar como **servidor TCP** na porta configurada. Quando o DiatuCAD conecta e envia o comando configurado, o app SHALL responder com o próximo serial ITF pendente na fila `mark_queue`. Se o comando não corresponder ao configurado, o app SHALL responder `ERROR:BADCMD`. Se não houver serial pendente, SHALL responder `ERROR:EMPTY`. O matching de comando SHALL ignorar caracteres `\r` e `\n` e espaços nas extremidades.

#### Scenario: Comando correto com serial na fila
- **WHEN** DiatuCAD envia `TCP: Give me string` e o app espera o mesmo comando com serial pendente
- **THEN** o app responde com 10 dígitos ASCII do serial e marca o item como entregue

#### Scenario: Comando com CRLF
- **WHEN** DiatuCAD envia `TCP: Give me string\r\n`
- **THEN** o app trata como comando válido e responde com o serial

#### Scenario: Comando incorreto
- **WHEN** DiatuCAD envia comando diferente do configurado no app
- **THEN** o app responde `ERROR:BADCMD` sem consumir item da fila

#### Scenario: Fila vazia
- **WHEN** DiatuCAD envia comando válido mas não há serial pendente
- **THEN** o app responde `ERROR:EMPTY`

### Requirement: Observabilidade do servidor laser
O servidor TCP SHALL registrar cada conexão (endereço remoto, payload recebido, resposta enviada, erros) em buffer circular consultável pela UI de Configurações.

#### Scenario: Última conexão visível
- **WHEN** DiatuCAD conecta e solicita serial
- **THEN** Configurações exibe a última requisição e resposta nos últimos 60 segundos
