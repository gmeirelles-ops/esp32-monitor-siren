## MODIFIED Requirements

### Requirement: Fila local FIFO com limite
O dispositivo SHALL manter os resultados não sincronizados em uma fila FIFO persistente com tamanho máximo definido, aplicando política de retenção ao atingir o limite. A lógica de enfileiramento e drenagem SHALL ser coberta por host tests executáveis sem hardware ESP32.

#### Scenario: Enfileiramento em ordem
- **WHEN** múltiplos resultados são gerados offline
- **THEN** o dispositivo os enfileira em ordem cronológica (FIFO) na flash local

#### Scenario: Limite da fila atingido
- **WHEN** a fila local atinge o tamanho máximo configurado e um novo resultado precisa ser gravado
- **THEN** o dispositivo sinaliza a condição (LED/alerta) e aplica a política de retenção definida, preservando os vereditos essenciais mais antigos ainda não sincronizados

#### Scenario: Host test de sufixo de tópico
- **WHEN** os host tests de fila offline são executados
- **THEN** verificam que mensagens são republicadas no sufixo `status`, `alerta` ou `calibracao` correto ao drenar
