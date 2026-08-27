## ADDED Requirements

### Requirement: Exportar CSV do Painel
O app SHALL permitir exportar o conteúdo do Painel de produção em CSV UTF-8 com BOM e separador `;`, respeitando os filtros de período/OP/produto/dispositivo ativos na tela.

#### Scenario: CSV resumo
- **WHEN** o gestor escolhe exportar CSV resumo
- **THEN** o arquivo contém métricas (testado, aprovados, reprovados, rendimento), throughput diário e falhas de hardware do filtro atual

#### Scenario: CSV lista de testes
- **WHEN** o gestor escolhe exportar CSV de testes
- **THEN** o arquivo lista os testes do filtro com serial, OP, veredito, potência, operador e timestamp

#### Scenario: Destino escolhido
- **WHEN** a exportação CSV é confirmada
- **THEN** o app abre diálogo para salvar o arquivo no destino escolhido pelo usuário

#### Scenario: Excel PT-BR
- **WHEN** o arquivo é aberto no Excel brasileiro
- **THEN** colunas separam corretamente (`;`) e acentos exibem corretamente (UTF-8 BOM)
