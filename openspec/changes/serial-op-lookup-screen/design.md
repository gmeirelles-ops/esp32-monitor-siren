## Context

`test_results` já armazena `serial`, `numero_op`, `veredito`, `potencia_media`, `operador`, `device_id`, `created_at`. Índice em `serial` existe desde schema v8.

`label_print_logic.dart` e reprint já foram tratados em `catalog-cloud-and-reprint`.

## Goals / Non-Goals

**Goals:**
- Busca responsiva com debounce 300ms.
- Máximo 200 resultados por consulta com aviso.

**Non-Goals:**
- Busca na nuvem Firestore (somente SQLite local).
- Edição de resultados históricos.

## Decisions

### 1. UI desktop-first

**Decisão:** campo de busca + filtro OP/serial via `SegmentedButton`; `DataTable` ou `ListView` com colunas.

### 2. Query Drift

**Decisão:** `searchBySerial(prefix)` e `searchByOp(numeroOp)` com `LIKE` ou `=` conforme filtro.

### 3. Reimpressão

**Decisão:** botão por linha chama `reprintLabel(serial)` existente; desabilitado se reprovado ou serial nulo.

## Risks / Trade-offs

- **[LIKE lento em base grande]** → índice em `serial` já mitiga; limit 200.

## Migration Plan

1. Deploy app; item "Consulta" na nav.

## Open Questions

- Incluir na mesma tela histórico de calibração por produto?
