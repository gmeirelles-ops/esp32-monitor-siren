## MODIFIED Requirements

### Requirement: Campos relacionados na mesma linha em desktop
Em desktop, campos logicamente pareados SHALL compartilhar a mesma linha horizontal para reduzir rolagem.

#### Scenario: Host e porta do broker
- **WHEN** o operador edita broker MQTT em viewport ≥ 900 px
- **THEN** os campos Host e Porta aparecem na mesma linha, com Host ocupando aproximadamente 70% da largura e Porta 30%

#### Scenario: Host e porta da impressora em modo rede
- **WHEN** o operador edita impressora Zebra em modo Rede em desktop
- **THEN** IP e Porta aparecem na mesma linha com proporção 70/30

#### Scenario: Seletor de impressora em modo USB
- **WHEN** o operador edita impressora Zebra em modo USB em desktop
- **THEN** o seletor de modo (USB/Rede) e o dropdown de impressoras Windows aparecem no card Impressora, com ação de teste de impressão visível

#### Scenario: Campos empilhados em mobile
- **WHEN** o operador edita Configurações em viewport < 900 px
- **THEN** Host e Porta são exibidos em linhas separadas (layout vertical)

## ADDED Requirements

### Requirement: Seletor de modo de impressora no card Zebra
O card Impressora Zebra em Configurações SHALL exibir controle segmentado ou equivalente para alternar entre **USB (local)** e **Rede**, mostrando apenas os campos relevantes ao modo selecionado.

#### Scenario: Alternância para USB
- **WHEN** o operador seleciona modo USB
- **THEN** campos de IP e porta são ocultados e o dropdown de impressoras Windows é exibido

#### Scenario: Alternância para Rede
- **WHEN** o operador seleciona modo Rede
- **THEN** o dropdown de impressoras Windows é ocultado e IP/porta são exibidos
