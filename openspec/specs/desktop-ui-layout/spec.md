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
A tela de Configurações SHALL agrupar cada domínio (Broker MQTT, Gravação laser / DiatuCAD, Nuvem/Firestore) em um `Card` distinto com fundo elevado mais claro que o scaffold (ex.: `#1E1E1E` sobre fundo `#121212` ou equivalente no tema).

#### Scenario: Seções separadas visualmente
- **WHEN** o operador visualiza Configurações em desktop
- **THEN** Broker MQTT, Gravação laser e Nuvem aparecem em cards separados com título de seção e padding interno consistente

### Requirement: Campos relacionados na mesma linha em desktop
Em desktop, campos logicamente pareados SHALL compartilhar a mesma linha horizontal para reduzir rolagem.

#### Scenario: Host e porta do broker
- **WHEN** o operador edita broker MQTT em viewport ≥ 900 px
- **THEN** os campos Host e Porta aparecem na mesma linha, com Host ocupando aproximadamente 70% da largura e Porta 30%

#### Scenario: Porta e comando laser
- **WHEN** o operador edita gravação laser em desktop
- **THEN** porta TCP e comando (ou campos pareados do laser) aparecem de forma compacta no card de gravação

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
Telas sem dados (Dispositivos, fila de gravação, Produtos) SHALL exibir empty state com ícone grande semi-transparente, título e subtítulo orientativo — não apenas texto pequeno centralizado.

#### Scenario: Aguardando dispositivos
- **WHEN** não há dispositivos na lista e o app está na tela Dispositivos
- **THEN** o empty state exibe ícone de conectividade, mensagem explicativa e indicador circular de progresso sutil indicando escuta ativa do broker MQTT

#### Scenario: Fila de gravação vazia
- **WHEN** não há seriais pendentes na fila laser
- **THEN** o empty state orienta que seriais aparecerão após testes aprovados

#### Scenario: Catálogo de produtos vazio
- **WHEN** não há produtos cadastrados
- **THEN** o empty state exibe ícone de inventário e orientação para cadastrar o primeiro produto

### Requirement: Botões de ação sem largura total em desktop
Em formulários desktop, botões de ação primária SHALL alinhar à esquerda (ou ao fluxo do formulário) com largura intrínseca ao conteúdo, não `double.infinity`.

#### Scenario: Salvar configurações
- **WHEN** o operador visualiza o botão Salvar em Configurações em desktop
- **THEN** o botão não se estende por toda a largura da janela

### Requirement: Métricas com rótulos em português
Telas de formulário e dashboard SHALL exibir rótulos de métricas em português (Rendimento, Total testadas, Aprovadas, Reprovadas, Pendentes).

#### Scenario: Painel de produção
- **WHEN** o operador visualiza o painel de produção
- **THEN** o percentual de aprovação é rotulado "Rendimento" e demais métricas usam termos em português

### Requirement: Layout desktop do posto de trabalho
O app SHALL apresentar layout desktop com hierarquia visual clara na tela Lote (operador → bancada → produto → OP), cards de seção consistentes (`FormSectionCard`), largura máxima controlada e indicadores de estado (MQTT, operador, dispositivo online) sempre acessíveis na shell.

#### Scenario: Seções do formulário de lote
- **WHEN** o operador visualiza a tela Lote em desktop
- **THEN** os campos estão agrupados em seções rotuladas (Turno, Bancada, Produto e OP, Ações) com espaçamento uniforme

#### Scenario: Indicadores na shell
- **WHEN** qualquer tela principal está visível
- **THEN** operador ativo e status MQTT aparecem na AppBar sem exigir troca de aba

### Requirement: Configurações laser-only
A tela de Configurações SHALL expor configuração de gravação laser e SHALL NOT oferecer seletor Etiquetas/Laser nem impressora Zebra/ZPL.

#### Scenario: Gestor abre Configurações
- **WHEN** o gestor abre Configurações em desktop
- **THEN** vê opções laser e não vê controles de impressora Zebra/ZPL

### Requirement: Tokens de largura desktop
O app SHALL definir e usar tokens em `layout.dart`: formulários ≤ `kFormMaxWidth` (600), páginas de conteúdo operacional ≤ `kPageContentMaxWidth` (900), breakpoint desktop 900.

#### Scenario: Lote em monitor wide
- **WHEN** o operador abre Lote em janela ≥ 900 px
- **THEN** o formulário não estica além de `kFormMaxWidth`

