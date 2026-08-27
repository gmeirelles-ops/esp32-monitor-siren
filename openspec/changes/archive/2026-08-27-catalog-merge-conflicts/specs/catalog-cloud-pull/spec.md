## MODIFIED Requirements

### Requirement: Download do catálogo a partir do Firestore
Quando a sincronização estiver habilitada e o Firebase disponível, o app SHALL permitir baixar a coleção `products` do Firestore e fazer upsert dos produtos no SQLite local por `id_produto`, detectando conflitos com o catálogo local antes de sobrescrever campos críticos.

#### Scenario: Pull manual do catálogo
- **WHEN** o operador aciona "Baixar catálogo da nuvem" com sync habilitado
- **THEN** o app lê os documentos de `products`, compara com o SQLite local e aplica upsert apenas após resolver ou confirmar ausência de conflitos

#### Scenario: Pull automático ao habilitar sync
- **WHEN** o operador habilita a sincronização
- **THEN** o app envia o catálogo local pendente e, em seguida, baixa o catálogo da nuvem aplicando merge com resolução de conflitos quando necessário

#### Scenario: Firebase indisponível
- **WHEN** a plataforma não tem Firebase (ex.: Linux) ou o sync está desabilitado
- **THEN** a ação de pull fica indisponível e o catálogo local continua operando normalmente

#### Scenario: Conflito de calibração detectado
- **WHEN** um produto remoto difere do local em `potencia_min`, `potencia_max` ou metadados de calibração
- **THEN** o app apresenta o conflito ao operador antes de aplicar o valor remoto
