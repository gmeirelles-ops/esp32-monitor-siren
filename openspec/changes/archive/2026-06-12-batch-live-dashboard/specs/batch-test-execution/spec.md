## ADDED Requirements

### Requirement: Medição PZEM simulada em build de desenvolvimento
O firmware SHALL suportar, quando `CONFIG_DEV_MOCK_PZEM` estiver habilitado em build de desenvolvimento, substituir leituras do PZEM-004T por valores sintéticos configuráveis, mantendo o ciclo completo botão–relé–veredito–publicação MQTT.

#### Scenario: Ciclo com PZEM simulado
- **WHEN** `CONFIG_DEV_MOCK_PZEM` está ativo, existe lote configurado e o operador pressiona o botão físico
- **THEN** o dispositivo executa o ciclo de teste com potência média sintética, calcula veredito e publica resultado em `status` como em produção

#### Scenario: Build de produção sem simulação
- **WHEN** `CONFIG_DEV_MOCK_PZEM` está desabilitado (padrão)
- **THEN** o dispositivo usa exclusivamente leituras reais do PZEM-004T

#### Scenario: Potência sintética variável
- **WHEN** o mock PZEM está ativo
- **THEN** o firmware gera amostras com média pseudoaleatória dentro ou fora dos limites do lote para exercitar aprovados e reprovados
