## ADDED Requirements

### Requirement: Glossário de termos em português
O app SHALL utilizar nomenclatura em português brasileiro nas telas operacionais, evitando termos em inglês desnecessários para o operador de chão de fábrica.

#### Scenario: Métricas de produção
- **WHEN** o painel exibe percentual de aprovação
- **THEN** o rótulo exibido é "Rendimento" e não "Yield"

#### Scenario: Presença da bancada
- **WHEN** o detalhe da bancada indica conectividade
- **THEN** os valores exibidos são "Conectada" ou "Desconectada" e não "Online" ou "Offline"

### Requirement: Navegação Bancadas
A seção de equipamentos na navegação principal SHALL ser rotulada "Bancadas" em vez de "Dispositivos".

#### Scenario: Barra de navegação
- **WHEN** o operador visualiza o menu principal
- **THEN** o destino de monitoramento de equipamentos aparece como "Bancadas"

### Requirement: Exportações em português
Exportações CSV e mensagens de confirmação SHALL usar cabeçalhos e textos em português alinhados ao glossário (ex.: coluna "Rendimento", "Bancada", "Potência média (W)").

#### Scenario: CSV de detalhe de lote
- **WHEN** o operador exporta o detalhe de um lote
- **THEN** os cabeçalhos das colunas estão em português sem termos em inglês
