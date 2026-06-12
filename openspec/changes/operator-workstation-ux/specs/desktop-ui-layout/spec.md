## MODIFIED Requirements

### Requirement: Layout desktop do posto de trabalho
O app SHALL apresentar layout desktop com hierarquia visual clara na tela Lote (operador → bancada → produto → OP), cards de seção consistentes (`FormSectionCard`), largura máxima controlada e indicadores de estado (MQTT, operador, dispositivo online) sempre acessíveis na shell.

#### Scenario: Seções do formulário de lote
- **WHEN** o operador visualiza a tela Lote em desktop
- **THEN** os campos estão agrupados em seções rotuladas (Turno, Bancada, Produto e OP, Ações) com espaçamento uniforme

#### Scenario: Indicadores na shell
- **WHEN** qualquer tela principal está visível
- **THEN** operador ativo e status MQTT aparecem na AppBar sem exigir troca de aba

### Requirement: Alerta global de falha de impressão
O app SHALL exibir falhas de impressão automática (`printFailureProvider`) em banner visível em qualquer tela até ser dispensado ou resolvido, não apenas na tela de Etiquetas.

#### Scenario: Falha de impressão durante lote
- **WHEN** a impressão automática ZPL falha enquanto o operador está na tela Lote
- **THEN** o app exibe banner de erro com mensagem e ação para ir a Etiquetas ou tentar novamente
