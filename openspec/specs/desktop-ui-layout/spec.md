# desktop-ui-layout Specification

## Purpose
Layout desktop do app Flutter: formulários em largura fixa, seções em cards e campos responsivos otimizados para monitores no posto de produção.
## Requirements
### Requirement: Largura máxima de formulários em desktop
Em viewports com largura ≥ 900 px, telas com formulários (Lote, Configurações, Admin, cadastro de produto) SHALL limitar a largura do conteúdo do formulário a no máximo 600 px, centralizado horizontalmente, sem esticar campos de texto nem botões de ponta a ponta.

#### Scenario: Formulário em monitor wide
- **WHEN** o operador abre Configurações em janela de 1920 px de largura
- **THEN** os campos de texto e botões de ação ocupam no máximo 600 px centralizados, com margem livre nas laterais

#### Scenario: Formulário em mobile
- **WHEN** o operador abre Lote em viewport menor que 900 px
- **THEN** o formulário utiliza a largura útil com padding padrão, sem `ConstrainedBox` de 600 px

### Requirement: Agrupamento visual por cards de seção
A tela de Configurações SHALL agrupar cada domínio (Broker MQTT, Impressora Zebra, Nuvem/Firestore) em um `Card` distinto com fundo elevado mais claro que o scaffold (ex.: `#1E1E1E` sobre fundo `#121212` ou equivalente no tema).

#### Scenario: Seções separadas visualmente
- **WHEN** o operador visualiza Configurações em desktop
- **THEN** Broker MQTT, Impressora Zebra e Nuvem aparecem em cards separados com título de seção e padding interno consistente

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

### Requirement: Grid de campos na tela de Lote
A tela de Lote SHALL exibir os campos Ano, Quantidade Total e Próximo sequencial na mesma linha em desktop.

#### Scenario: Lote em desktop
- **WHEN** o operador configura um lote em viewport ≥ 900 px
- **THEN** Ano, Quantidade Total e Próximo sequencial aparecem lado a lado na mesma linha do formulário

#### Scenario: Lote em mobile
- **WHEN** o operador configura um lote em viewport < 900 px
- **THEN** os três campos são empilhados verticalmente

### Requirement: Empty states enriquecidos
Telas sem dados (Dispositivos, Etiquetas, Produtos) SHALL exibir empty state com ícone grande semi-transparente, título e subtítulo orientativo — não apenas texto pequeno centralizado.

#### Scenario: Aguardando dispositivos
- **WHEN** não há dispositivos na lista e o app está na tela Dispositivos
- **THEN** o empty state exibe ícone de conectividade, mensagem explicativa e indicador circular de progresso sutil indicando escuta ativa do broker MQTT

#### Scenario: Buffer de etiquetas vazio
- **WHEN** não há etiquetas pendentes na tela Etiquetas
- **THEN** o empty state exibe ícone de etiqueta e texto orientando que etiquetas aparecerão após testes aprovados

#### Scenario: Catálogo de produtos vazio
- **WHEN** não há produtos cadastrados
- **THEN** o empty state exibe ícone de inventário e orientação para cadastrar o primeiro produto

### Requirement: Botões de ação sem largura total em desktop
Em formulários desktop, botões de ação primária SHALL alinhar à esquerda (ou ao fluxo do formulário) com largura intrínseca ao conteúdo, não `double.infinity`.

#### Scenario: Salvar configurações
- **WHEN** o operador visualiza o botão Salvar em Configurações em desktop
- **THEN** o botão não se estende por toda a largura da janela

### Requirement: Seletor de modo de impressora no card Zebra
O card Impressora Zebra em Configurações SHALL exibir controle segmentado ou equivalente para alternar entre **USB (local)** e **Rede**, mostrando apenas os campos relevantes ao modo selecionado.

#### Scenario: Alternância para USB
- **WHEN** o operador seleciona modo USB
- **THEN** campos de IP e porta são ocultados e o dropdown de impressoras Windows é exibido

#### Scenario: Alternância para Rede
- **WHEN** o operador seleciona modo Rede
- **THEN** o dropdown de impressoras Windows é ocultado e IP/porta são exibidos

