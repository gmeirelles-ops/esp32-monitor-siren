# catalog-cloud-pull Specification

## Purpose
Sincronização do catálogo de produtos da nuvem para o SQLite local no app Flutter, via pull manual ou automático ao habilitar sync Firestore.
## Requirements
### Requirement: Download do catálogo a partir do Firestore
Quando a sincronização estiver habilitada e o Firebase disponível, o app SHALL permitir baixar a coleção `products` do Firestore e fazer upsert dos produtos no SQLite local por `id_produto`.

#### Scenario: Pull manual do catálogo
- **WHEN** o operador aciona "Baixar catálogo da nuvem" com sync habilitado
- **THEN** o app lê os documentos de `products`, faz upsert de cada produto no SQLite e atualiza a lista exibida

#### Scenario: Pull automático ao habilitar sync
- **WHEN** o operador habilita a sincronização
- **THEN** o app envia o catálogo local pendente e, em seguida, baixa o catálogo da nuvem aplicando os produtos remotos

#### Scenario: Firebase indisponível
- **WHEN** a plataforma não tem Firebase (ex.: Linux) ou o sync está desabilitado
- **THEN** a ação de pull fica indisponível e o catálogo local continua operando normalmente

### Requirement: Download unificado de catálogo
Quando a sincronização estiver habilitada, a ação "Baixar catálogo" SHALL baixar produtos (`products`) e operadores (`operators`) do Firestore e aplicar ambos no SQLite local.

#### Scenario: Pull com produtos e operadores
- **WHEN** o operador aciona "Baixar catálogo" com sync habilitado e existem documentos em `products` e `operators`
- **THEN** o app aplica upsert de produtos e operadores e informa quantos de cada foram baixados

### Requirement: Mapeamento de produto da nuvem
O app SHALL converter um documento de `products` do Firestore em produto local, preservando `id_produto`, `nome`, `potencia_ref`, `potencia_min`, `potencia_max`, `tolerancia_pct`, `tempo_teste_sec` e metadados de calibração quando presentes.

#### Scenario: Documento completo convertido
- **WHEN** um documento de `products` contém todos os campos do produto
- **THEN** o app cria/atualiza o produto local com os mesmos valores, incluindo `calibrado_em` e `calibrado_device_id`

#### Scenario: Documento sem id é ignorado
- **WHEN** um documento não possui `id_produto`
- **THEN** o app ignora esse documento sem abortar o pull dos demais

