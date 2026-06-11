# offline-resilience Specification

## Purpose
TBD - created by archiving change validacao-sirenes. Update Purpose after archive.
## Requirements
### Requirement: Continuidade dos testes em modo offline
O dispositivo SHALL continuar executando os testes de sirene normalmente mesmo quando a conexão Wi-Fi ou com o broker MQTT estiver indisponível durante um lote.

#### Scenario: Queda de rede durante o lote
- **WHEN** a conexão Wi-Fi ou com o broker MQTT falha no andamento de um lote
- **THEN** o dispositivo mantém o fluxo de teste (botão, relé, leitura PZEM, veredito) operando normalmente

### Requirement: Persistência local dos resultados
O dispositivo SHALL gravar os resultados dos testes de forma persistente na memória flash local (NVS ou SPIFFS) enquanto estiver offline.

#### Scenario: Resultado gravado offline
- **WHEN** um teste é concluído enquanto o dispositivo está sem conexão
- **THEN** o resultado é gravado de forma persistente na flash local para sincronização posterior

### Requirement: Fila local FIFO com limite
O dispositivo SHALL manter os resultados não sincronizados em uma fila FIFO persistente com tamanho máximo definido, aplicando política de retenção ao atingir o limite.

#### Scenario: Enfileiramento em ordem
- **WHEN** múltiplos resultados são gerados offline
- **THEN** o dispositivo os enfileira em ordem cronológica (FIFO) na flash local

#### Scenario: Limite da fila atingido
- **WHEN** a fila local atinge o tamanho máximo configurado e um novo resultado precisa ser gravado
- **THEN** o dispositivo sinaliza a condição (LED/alerta) e aplica a política de retenção definida, preservando os vereditos essenciais mais antigos ainda não sincronizados

### Requirement: Persistência do contexto de lote para retomada
O dispositivo SHALL persistir o contexto do lote ativo (OP, identidade do produto, limites, sequencial corrente e aprovados) de forma que um reboot durante o lote não perca o lote em andamento.

#### Scenario: Queda de energia durante o lote
- **WHEN** o dispositivo perde energia e reinicia durante um lote em andamento
- **THEN** ao voltar, o dispositivo restaura o lote a partir da NVS sem duplicar nem saltar o sequencial

### Requirement: Sincronização em segundo plano após reconexão
O dispositivo SHALL realizar, por meio de um módulo em segundo plano, o dump de todas as mensagens acumuladas assim que a conexão de rede retornar, republicando cada mensagem no **mesmo sufixo de tópico MQTT** (`status`, `alerta` ou `calibracao`) usado no momento em que foi enfileirada.

#### Scenario: Reconexão de rede
- **WHEN** a conexão Wi-Fi e com o broker MQTT é restabelecida
- **THEN** o módulo de sincronização envia as mensagens persistidas em ordem FIFO, cada uma no tópico de origem correto, e as remove da fila local após confirmação de publicação

#### Scenario: Mensagem de alerta enfileirada offline
- **WHEN** um alerta de hardware é gerado sem conexão MQTT e posteriormente a rede retorna
- **THEN** o alerta é publicado em `sirene/<device_id>/alerta`, não em `status`

#### Scenario: Resultado de calibração enfileirado offline
- **WHEN** um ciclo de calibração conclui sem conexão MQTT e a rede retorna
- **THEN** o JSON de calibração é publicado em `sirene/<device_id>/calibracao`

#### Scenario: Entrada legada sem metadado de tópico
- **WHEN** a fila contém uma entrada persistida antes da atualização (somente corpo JSON, sem sufixo de tópico)
- **THEN** o dispositivo trata essa entrada como pertencente ao tópico `status` ao drenar

