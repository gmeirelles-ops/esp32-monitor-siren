## Context

O app atua como servidor TCP; o DiatuCAD conecta a cada objeto variável no F2. Hoje:

```
serve serial → in_progress (ainda na UI)
serve model  → delivered só se product.manual vazio
serve manual → delivered se product.manual preenchido
```

Isso acopla limpeza da UI a um job DiatuCAD completo e ao cadastro opcional `manual`.

## Goals / Non-Goals

**Goals**

- Serial some da fila assim que o laser puxa o valor (F2 / DataMatrix).
- Remover complexidade do terceiro canal TCP (manual).
- Manter resposta de modelo para jobs que ainda gravam o nome do produto.

**Non-Goals**

- Remover “Gerar serial manualmente” / regravação.
- Remover coluna SQLite `products.manual` nesta entrega (evita churn de migration/schema gen).
- Reativar modo Zebra ou mudar `MarkingMode`.

## Decisions

### 1. Confirmar no serve do serial

Em `_serveNextSerial`, após `markQueueInProgress` (ou em sequência imediata), chamar `markQueueDelivered` e limpar `_activeMarkId`.

**Por quê:** a gravação física ocorre quando o DiatuCAD obtém o serial; a UI deve refletir isso. Timeout/`in_progress` deixa de ser necessário para o ciclo feliz.

**Alternativa descartada:** confirmar no modelo — ainda falha se o job tiver só DataMatrix.

### 2. Modelo só resolve nome

`_serveModel` usa `_lastDeliveredSerial` / eventual peek, devolve `Products.nome`, **sem** `_confirmActiveMark`.

Ordem DiatuCAD (model antes de serial) permanece um edge case: modelo pode cair em `ERROR:EMPTY` ou nome do último serial — aceitável e já existia parcialmente.

### 3. Remover manual do runtime, manter coluna vazia

| Camada | Ação |
|--------|------|
| TCP server | Remover `DiatuTcpRoute.manual`, `onRequestManual`, `manualCommandPrefix` |
| AppConfig | Remover `laserManualCommand` / prefs / default |
| Settings UI | Remover campo e validações do comando manual |
| Product form | Remover TextField e parâmetros de save |
| upsert/sync | Sempre persistir `manual: ''` (ou omitir e default) |
| DB schema | Manter coluna com default `''` |

### 4. Estado `in_progress`

Com confirmação imediata, `in_progress` fica raro (só se entre peek e deliver falhar, ou recovery legado). Manter `requeueAllInProgressMarks` no start por segurança; timeout de 5 min pode permanecer como no-op benigno ou ser simplificado depois.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Laser puxa serial e aborta job sem gravar | Serial some da fila mesmo assim — operador usa regravação / + manual se necessário (já existe) |
| Produtos com `manual` preenchido no Firestore | Sync passa a gravar `''` ou ignora UI; texto antigo no banco não é enviado ao laser |
| Jobs DiatuCAD ainda com objeto `TCP: manual` | App responde `ERROR:BADCMD` — documentar remoção do objeto no job |

## Migration Plan

1. Deploy app novo.
2. No DiatuCAD: remover objeto de texto do manual do job (se existir).
3. Não exige wipe de DB.

## Open Questions

_(nenhuma — decisão B confirmada pelo usuário)_
