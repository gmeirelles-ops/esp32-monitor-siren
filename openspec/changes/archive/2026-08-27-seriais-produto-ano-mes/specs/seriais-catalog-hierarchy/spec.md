## ADDED Requirements

### Requirement: Árvore de catálogo por produto, ano e mês
O Firestore SHALL armazenar cada serial ITF aprovado também em `seriais/{id_produto}/anos/{YYYY}/meses/{MM}/itens/{serial}`, onde `{YYYY}` e `{MM}` são derivados do timestamp do teste no fuso `America/Sao_Paulo`, e `{serial}` é o serial ITF completo.

#### Scenario: Aprovação espelhada no catálogo temporal
- **WHEN** um teste aprovado com serial `1232600018` do produto `123` em 15/07/2026 (SPT) é sincronizado
- **THEN** existe documento `seriais/123/anos/2026/meses/07/itens/1232600018` com os mesmos campos de prova do documento sob o lote (`numero_op`, `sequencial`, `veredito`, `potencia_media`, `operador`, `timestamp`, `device_id`, `station_id`, etc.)

#### Scenario: Mês no limite de UTC
- **WHEN** o teste ocorre em 01/07/2026 00:30 SPT (ainda 30/06 em UTC)
- **THEN** o path usa `anos/2026/meses/07` (dia do teste em SPT), não junho

#### Scenario: Navegação no Console por produto e mês
- **WHEN** um administrador abre `seriais/{id_produto}/anos/{YYYY}/meses/{MM}/itens` no Firebase Console
- **THEN** a coleção lista os seriais aprovados daquele produto naquele mês

### Requirement: Catálogo não substitui hierarquia por lote
O app SHALL continuar gravando o serial aprovado em `test_results/{numero_op}/seriais/{serial}` além do path de catálogo. A ausência do espelho no catálogo NÃO isenta a gravação por lote.

#### Scenario: Dupla gravação na sync
- **WHEN** a fila processa uma aprovação com serial
- **THEN** existem ambos os documentos: sob o lote e sob `seriais/.../itens/{serial}`

### Requirement: Escopo do catálogo
O catálogo temporal SHALL incluir apenas seriais de testes aprovados. Reprovações e retestes aprovados SHALL NOT criar documentos em `seriais/{id_produto}/anos/.../itens/`.

#### Scenario: Reprovado não entra no catálogo
- **WHEN** um teste é reprovado
- **THEN** nenhum documento é criado sob `seriais/{id_produto}/anos/.../itens/`

#### Scenario: Reteste aprovado não entra no catálogo
- **WHEN** um reteste aprovado é sincronizado
- **THEN** nenhum documento novo é criado no catálogo temporal (comportamento alinhado ao path por lote)
