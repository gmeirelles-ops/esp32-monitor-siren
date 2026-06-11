## Context

Serial = `produto(3)+ano(2)+seq(4)+ITF`. Unicidade real = `(produto, ano, seq)`. O firmware recebe `proximo_sequencial` no `SET_BATCH`, incrementa só em aprovação e persiste em NVS — mas só dentro de um lote/OP. A tabela `test_results` (SQLite) guarda `numeroOp`, `sequencial`, `serial`, mas não `id_produto`/`ano` em colunas próprias (eles estão embutidos no serial).

## Goals / Non-Goals

**Goals:**

- Eliminar seriais duplicados entre OPs diferentes do mesmo produto/ano.
- Pré-preencher `proximo_sequencial` sem intervenção manual.
- Detectar gaps/duplicatas para auditoria de lote.

**Non-Goals:**

- Contador atômico multi-posto (decisão: local + guarda agora; nuvem fica para mudança futura).
- Alterar o layout do serial / código de barras.
- Alterar firmware.

## Decisions

### 1. Tabela `SerialCounters`

```
SerialCounters
  idProduto      TEXT
  ano            TEXT
  lastSequencial INT
  updatedAt      DateTime
  primaryKey (idProduto, ano)
```

Atualizada via `bumpSerialCounter(idProduto, ano, sequencial)` que faz `lastSequencial = max(atual, sequencial)`. Idempotente sob reprocessamento.

**Alternativa considerada:** derivar o último sequencial parseando a coluna `serial` de `test_results`. Rejeitada — frágil (depende de parse), mais lenta, e não cobre o caso de migrar entre anos.

### 2. Migração schema v3 → v4

`onUpgrade`: `if (from < 4) await m.createTable(serialCounters);`. Backfill opcional: varrer `test_results` aprovados, extrair produto/ano/seq do serial e popular o contador (executado uma vez na migração).

### 3. Hook na geração de serial (`mqtt_providers._handleMessage`)

Fluxo no teste APROVADO:

```
test aprovado
   │
   ▼
serial = generateFullSerial(produto, ano, seq)
   │
   ▼
serialExists(serial)? ──sim──► NÃO imprime, NÃO bufferiza
   │                            emite alerta "serial duplicado"
   não
   ▼
addLabelToBuffer + bumpSerialCounter(produto, ano, seq)
```

### 4. Pré-preenchimento no formulário de lote

Ao escolher produto **ou** alterar o ano, consultar `getLastSequencial(idProduto, ano)` e setar o campo `proximo_sequencial = last + 1` (ou `1` se não houver). Campo continua editável (operador pode sobrescrever em casos excepcionais), com texto de ajuda mostrando o último usado.

### 5. Reconciliação

`reconcileSerials(idProduto, ano)` → retorna `{esperado, encontrados[], gaps[], duplicados[]}` a partir de `test_results` aprovados. Exibido num painel/disclosure na tela de Lote para o produto-ano selecionado.

## Risks / Trade-offs

- **[Risco] Dois postos validam o mesmo produto/ano em paralelo** → contadores locais divergem e podem colidir. Mitigação: documentar limitação; mudança futura usa contador atômico no Firestore.
- **[Risco] Operador sobrescreve o sugerido para valor já usado** → trava anti-duplicado barra na emissão; reconciliação evidencia.
- **[Trade-off] Backfill na migração** custa uma varredura única de `test_results`; aceitável (volume por posto é baixo).

## Migration Plan

1. Adicionar tabela + migração v4 com backfill.
2. Métodos de banco + testes unitários.
3. Hook anti-duplicado + bump.
4. UI: pré-preencher + painel de reconciliação.
5. `flutter analyze`/`test`.

Rollback: schema novo é aditivo; reverter código não corrompe dados existentes.
