# product-catalog Specification

## Purpose
Catálogo local de produtos no app Flutter: cadastro de SKUs com limites de potência, tempo de teste e metadados de calibração usados nos lotes.
## Requirements
### Requirement: Cadastro local de produtos
O app SHALL persistir um catálogo de produtos em SQLite contendo, no mínimo: `id_produto` (3 dígitos), `nome`, `potencia_ref`, `potencia_min`, `potencia_max`, `tolerancia_pct`, `tempo_teste_sec`, `calibrado_em` e `calibrado_device_id`.

#### Scenario: Novo produto cadastrado
- **WHEN** o operador preenche os dados do produto, conclui a autocalibração e confirma o cadastro
- **THEN** o app grava o produto no SQLite e o exibe na lista de produtos cadastrados

#### Scenario: Produto com id duplicado
- **WHEN** o operador tenta cadastrar um `id_produto` que já existe
- **THEN** o app impede a criação e oferece editar ou recalibrar o produto existente

### Requirement: Autocalibração no cadastro de produto
O app SHALL oferecer fluxo de autocalibração integrado ao cadastro, enviando `START_CALIBRATION` ao dispositivo selecionado quando este estiver em estado `IDLE`.

#### Scenario: Medição iniciada no cadastro
- **WHEN** o operador aciona "Medir peça padrão" com dispositivo em `IDLE` e peça padrão posicionada na bancada
- **THEN** o app envia `{"cmd": "START_CALIBRATION"}`, exibe indicador de medição em andamento e painel de leituras ao vivo

#### Scenario: Leituras ao vivo durante calibração
- **WHEN** o firmware publica mensagens `tipo: "calibracao_amostra"` durante o ciclo
- **THEN** o app atualiza o painel com a potência instantânea e histórico visual das amostras recebidas

#### Scenario: Resultado final preenche limites
- **WHEN** o app recebe `tipo: "calibracao"` com `potencia_media` ao final do ciclo
- **THEN** o app define `potencia_ref` com a média, calcula `potencia_min` e `potencia_max` pela tolerância configurada e exibe os valores para confirmação do operador

#### Scenario: Calibração rejeitada no cadastro
- **WHEN** o dispositivo não está em `IDLE` ou retorna rejeição `calibracao_estado_invalido`
- **THEN** o app exibe o motivo e não altera os limites do produto em edição

### Requirement: Cálculo automático de limites de potência
O app SHALL calcular `potencia_min` e `potencia_max` a partir de `potencia_ref` e `tolerancia_pct` usando a fórmula: `ref × (1 ± tolerancia_pct/100)`, arredondando para 2 casas decimais.

#### Scenario: Cálculo com tolerância padrão
- **WHEN** a autocalibração retorna `potencia_media` de 20,0 W e a tolerância é 10%
- **THEN** o app propõe `potencia_min` = 18,00 W e `potencia_max` = 22,00 W

#### Scenario: Operador ajusta limites antes de salvar
- **WHEN** o operador edita manualmente `potencia_min` ou `potencia_max` após o cálculo automático
- **THEN** o app persiste os valores ajustados no cadastro do produto

### Requirement: Recalibração de produto existente
O app SHALL permitir recalibrar um produto já cadastrado, sobrescrevendo `potencia_ref`, limites e metadados de calibração após confirmação.

#### Scenario: Recalibração bem-sucedida
- **WHEN** o operador aciona "Recalibrar" em um produto existente e conclui nova medição
- **THEN** o app atualiza `potencia_ref`, `potencia_min`, `potencia_max`, `calibrado_em` e `calibrado_device_id`

### Requirement: Listagem e edição de produtos
O app SHALL exibir lista de produtos cadastrados com nome, id, limites e data da última calibração, permitindo editar nome, tolerância e tempo de teste sem obrigar nova calibração.

#### Scenario: Edição de metadados sem recalibração
- **WHEN** o operador altera apenas o nome ou a tolerância de um produto já calibrado
- **THEN** o app recalcula min/max a partir da `potencia_ref` existente e salva as alterações

### Requirement: Upload do catálogo para Firestore
Quando a sincronização estiver habilitada, o app SHALL enfileirar upsert em `products/{id_produto}` após cada criação, edição ou recalibração de produto no SQLite local.

#### Scenario: Novo produto sincronizado
- **WHEN** o operador conclui cadastro de produto com autocalibração e sync está habilitado
- **THEN** o sync service enfileira documento com `id_produto`, `nome`, limites de potência, tolerância, tempo de teste e metadados de calibração

#### Scenario: Recalibração sincronizada
- **WHEN** o operador recalibra produto existente com sync habilitado
- **THEN** o sync service enfileira atualização com novos limites e `calibrado_em` / `calibrado_device_id` atualizados

### Requirement: Catálogo local independente da nuvem na v1
O app SHALL NOT exigir leitura do Firestore para operar o catálogo — SQLite permanece a fonte de verdade no posto. O app MAY, de forma opt-in, baixar o catálogo da nuvem para semear ou atualizar o SQLite local.

#### Scenario: Primeiro uso sem internet
- **WHEN** o operador cadastra produtos com sync desabilitado ou sem conectividade
- **THEN** o catálogo funciona integralmente via SQLite e lotes podem ser configurados normalmente

#### Scenario: Semear catálogo a partir da nuvem
- **WHEN** o operador habilita o sync ou aciona o pull manual com Firebase disponível
- **THEN** o app baixa o catálogo da nuvem e faz upsert no SQLite, sem passar a depender da nuvem para a operação subsequente

