## MODIFIED Requirements

### Requirement: Cadastros unificam produtos e operadores

O sistema SHALL apresentar uma tela "Cadastros" com abas ou segmento **Produtos** e **Operadores**, substituindo telas administrativas separadas.

#### Scenario: Acesso administrativo

- **WHEN** o usuário com perfil admin abre Cadastros
- **THEN** pode alternar entre listagem de produtos e listagem de operadores sem trocar de rota principal

#### Scenario: Operador comum

- **WHEN** o usuário sem perfil admin tenta acessar Cadastros
- **THEN** o sistema nega acesso ou exibe somente leitura conforme política existente

### Requirement: Produto mantém calibração e tolerância

O sistema SHALL preservar o fluxo atual de cadastro de produto, calibração MQTT e tolerância de potência dentro da aba Produtos.

#### Scenario: Recalibração

- **WHEN** o administrador recalibra um produto na aba Produtos
- **THEN** o comportamento MQTT `START_CALIBRATION` permanece inalterado

## ADDED Requirements

### Requirement: Busca e filtro em Cadastros

O sistema SHALL oferecer campo de busca por nome/código em ambas as abas de Cadastros.

#### Scenario: Buscar operador

- **WHEN** o administrador digita parte do nome na aba Operadores
- **THEN** a lista filtra em tempo real
