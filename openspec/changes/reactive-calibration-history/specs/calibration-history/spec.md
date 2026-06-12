## MODIFIED Requirements

### Requirement: Histórico de calibração por produto
O app SHALL manter e exibir histórico de calibrações por `id_produto`, atualizando automaticamente a lista no formulário de produto quando uma nova calibração é registrada.

#### Scenario: Nova calibração via MQTT
- **WHEN** o app recebe resultado de calibração para um produto cujo formulário está aberto
- **THEN** o histórico exibido no formulário é atualizado sem fechar e reabrir a tela

#### Scenario: Histórico ordenado
- **WHEN** o operador visualiza o histórico de calibração de um produto
- **THEN** as entradas são exibidas da mais recente para a mais antiga
