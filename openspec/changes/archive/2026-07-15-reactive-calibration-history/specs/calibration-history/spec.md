## MODIFIED Requirements

### Requirement: Visualização do histórico de calibração
O app SHALL exibir o histórico de calibrações de um produto ao editá-lo, em ordem cronológica decrescente, atualizando automaticamente a lista no formulário quando uma nova calibração é registrada.

#### Scenario: Histórico exibido na edição
- **WHEN** o operador abre um produto já calibrado para edição
- **THEN** o app lista as calibrações anteriores com potência de referência e data, da mais recente para a mais antiga

#### Scenario: Nova calibração via MQTT
- **WHEN** o app recebe resultado de calibração para um produto cujo formulário está aberto
- **THEN** o histórico exibido no formulário é atualizado sem fechar e reabrir a tela

#### Scenario: Histórico ordenado
- **WHEN** o operador visualiza o histórico de calibração de um produto
- **THEN** as entradas são exibidas da mais recente para a mais antiga
