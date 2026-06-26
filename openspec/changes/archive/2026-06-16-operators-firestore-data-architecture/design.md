## Context

Estado atual (já implementado em changes anteriores):

```
App startup → AppGate → activeOperatorProvider
  ├─ sessão em SharedPreferences (active_operator_id) → shell direto
  └─ sem sessão → OperatorLoginScreen

Firestore:
  test_results/{numero_op}           ← metadados lote
  test_results/{numero_op}/seriais/{serial}  ← potencia_media, operador, ...
  products/{id_produto}              ← sync bidirecional
  operators                          ← NÃO EXISTE na nuvem

SQLite operators                     ← só local
MarkingMode.labels | .laser          ← reprint só ZPL hoje
```

O firmware envia resultado com `potencia_media`; os limites `tempo_teste`, `potencia_min`, `potencia_max` vivem no `BatchConfig` ativo no app no momento do teste — hoje não são persistidos em `test_results` nem espelhados na nuvem.

## Goals / Non-Goals

**Goals:**

- Cada turno começa com identificação explícita do operador (PIN).
- Operadores e produtos seguem o mesmo modelo de catálogo na nuvem.
- Consulta Firestore por serial revela **como** a sirene foi testada (tempo, faixa, média).
- Uma ação de remark coerente com impressora ou laser.

**Non-Goals:**

- Migrar documentos Firestore antigos sem os novos campos (campos opcionais; backfill manual se necessário).
- Alterar protocolo MQTT do firmware.
- Criptografar PIN neste ciclo.

## Decisions

### 1. Login em toda abertura — não persistir sessão de operador

**Decisão:** remover persistência de `active_operator_id` em `SharedPreferences` (ou chamar `clearActiveOperatorId()` no startup antes do primeiro frame).

```dart
// app.dart — AppGate.initState (primeiro callback)
WidgetsBinding.instance.addPostFrameCallback((_) async {
  await ref.read(appConfigProvider).clearActiveOperatorId();
  ...
});
```

**Alternativa:** flag `require_login_every_start` — rejeitada; requisito é sempre, sem configuração.

**Mantido:** logout/trocar operador em Configurações durante a sessão atual.

### 2. Coleção Firestore `operators/{codigo}`

| Campo | Tipo | Notas |
|-------|------|-------|
| `codigo` | string | Document ID = PIN (4 dígitos típico) |
| `nome` | string | Exibido na login |
| `ativo` | bool | Inativos não aparecem na login |
| `updated_at` | ISO8601 | Merge no pull |

- **Pull:** `CatalogCloudService` estendido ou `OperatorsCloudService` com mesmo padrão de `products` (last-write-wins por `updated_at`).
- **Push:** ao salvar operador local com sync habilitado, enfileirar upsert em `operators/{codigo}`.
- **Conflito:** nuvem vence no pull se `updated_at` remoto ≥ local; push sobrescreve nuvem ao editar no posto.

### 3. Parâmetros de teste na hierarquia Firestore

Estender mappers:

```dart
// mapSerialDocument — campos adicionais
'tempo_teste_sec': tempoTesteSec,
'potencia_min': potenciaMin,
'potencia_max': potenciaMax,
'potencia_media': test.potenciaMedia,
```

Fonte no app: `BatchConfig` do dispositivo no momento de `insertTestResult` (já disponível em `mqtt_providers`).

Documento lote (`mapLoteDocument`): adicionar os três campos do batch ativo no `SET_BATCH`.

### 4. Migração SQLite v14

```sql
ALTER TABLE test_results ADD COLUMN tempo_teste_sec INTEGER;
ALTER TABLE test_results ADD COLUMN potencia_min REAL;
ALTER TABLE test_results ADD COLUMN potencia_max REAL;
ALTER TABLE test_results ADD COLUMN operator_id INTEGER REFERENCES operators(id);
```

`operador` (texto) mantido para compatibilidade e export legado.

Nova tabela `remark_log`:
- `id`, `serial`, `numero_op`, `mode` (`label`|`laser`), `operator_id`, `created_at`

### 5. Remark unificado (`RemarkService`)

```dart
Future<void> remarkSerial({required String serial, required WidgetRef ref}) async {
  final mode = ref.read(appConfigProvider).markingMode;
  if (mode == MarkingMode.laser) {
    await ref.read(markQueueProcessorProvider).enqueuePinned(serial);
  } else {
    await _reprintZpl(serial, ref);
  }
  await db.insertRemarkLog(...);
}
```

UI:
- Modo etiquetas: "Reimprimir" + ícone `Icons.print`
- Modo laser: "Regravar" + ícone `Icons.precision_manufacturing`
- Diálogos de confirmação com texto adequado

Pontos de uso: `LabelsScreen` (busca), `BatchReportDetailScreen`, futura busca por serial se reativada.

### 6. Baixar catálogo unificado

`pullCatalogFromCloud` retorna `(products: n, operators: m)` e invalida ambos os providers.

Settings: mensagem "X produto(s) e Y operador(es) baixados".

### 7. `operator_id` em testes

No `insertTestResult`, gravar `activeOperatorProvider` → `operator_id` quando autenticado.
Sync Firestore: incluir `operator_codigo` (string) para consultas sem join.

## Risks / Trade-offs

- **[Operador precisa logar todo dia]** → fluxo rápido (lista + PIN); sem operadores na nuvem, cadastro local continua funcionando offline.
- **[PIN em texto na nuvem]** → aceito no chão de fábrica; documentar risco; hash em change futuro.
- **[Documentos antigos sem tempo/potência]** → campos nullable; UI mostra "—" quando ausente.
- **[Regravar duplica na fila]** → `enqueuePinned` já existe; deduplicar serial `pending` na fila.

## Migration Plan

1. Deploy regras Firestore `operators/`.
2. Release app com migração SQLite v14 (campos nullable).
3. Primeiro sync habilitado: push operadores locais + pull nuvem.
4. Novos testes passam a preencher campos; histórico antigo permanece parcial.
5. Comunicar postos: login obrigatório a cada abertura.

## Open Questions

- PIN na nuvem: equipe de TI aceita texto plano ou adia sync de `codigo` (só `nome`/`ativo` na nuvem)? **Default proposto:** sync completo como produtos.
- Regravar em lote (múltiplos seriais) — fora deste change; remark continua unitário.
