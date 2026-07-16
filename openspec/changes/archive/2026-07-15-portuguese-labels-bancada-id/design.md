## Context

O app usa `device_id` derivado do MAC ESP32 nos tópicos MQTT (`sirene/<device_id>/…`). `formatBancadaLabel` hoje retorna `Bancada {deviceId}`, expondo o MAC na UI. Parte da interface já está em português (estados FSM), mas persistem termos em inglês (Yield, Online/Offline, Dispositivos) e exportações mistas.

O download ZPL em dev (`labels_screen.dart`) usa `generateZplLabelRow` + `getSaveLocation` com extensão `.zpl` — funcional, porém sem agrupamento para buffers >3 etiquetas e rótulo genérico "Baixar arquivo de impressão".

## Goals / Non-Goals

**Goals:**
- Número de bancada estável (1, 2, 3…) atribuído na primeira detecção de cada MAC, persistido em SQLite.
- UI, relatórios e CSV mostram **Bancada N**; MAC visível só em detalhe expandido ou Configurações/Admin.
- Glossário PT aplicado nas telas principais e exportações.
- Export ZPL validado: arquivo `.zpl`, múltiplos blocos de 3 quando necessário, mensagens em português.

**Non-Goals:**
- Alterar `device_id` no firmware ou tópicos MQTT.
- Renomear/reordenar bancadas manualmente nesta entrega (futuro).
- Traduzir payloads MQTT ou vereditos `APROVADO`/`REPROVADO` (já PT).
- Disponibilizar download ZPL em release de produção.

## Decisions

### 1. Tabela `bancadas`

**Decisão:** Nova tabela Drift:

| Coluna | Tipo | Notas |
|--------|------|-------|
| `numero` | int PK autoincrement | Número exibido (1, 2, 3…) |
| `deviceId` | text unique | MAC MQTT |
| `createdAt` | datetime | Primeira detecção |

`ensureBancada(deviceId)` no primeiro heartbeat/presença: se MAC novo, `INSERT` e retorna `numero`; senão retorna existente.

**Alternativa:** Mapa em SharedPreferences — rejeitada; precisa de query e backfill de histórico.

### 2. Rótulo de exibição

**Decisão:** `formatBancadaLabel(deviceId, {Bancada? b})` → `Bancada ${numero}` via lookup; provider `bancadaByDeviceProvider` cacheia mapa.

Detalhe da bancada: linha secundária "Identificador técnico: {deviceId}" (colapsável).

### 3. Backfill

**Decisão:** Na migração, para cada `device_id` distinto em `test_results` e dispositivos em memória, criar entrada em `bancadas` ordenando por `MIN(created_at)` para preservar ordem histórica aproximada.

### 4. Glossário PT (UI)

| Antes | Depois |
|-------|--------|
| Dispositivos (nav) | Bancadas |
| Dispositivo | Bancada |
| Yield | Rendimento |
| Online / Offline | Conectada / Desconectada |
| Total testado | Total testadas |
| Baixar arquivo de impressão | Baixar arquivo ZPL |
| END_BATCH (botão) | Encerrar lote |
| dev-simulator (operador) | simulador-dev (ou oculto em relatório) |

Centralizar em `lib/shared/portuguese_labels.dart` constantes reutilizáveis.

### 5. Export ZPL

**Decisão:** Reutilizar `printLabelBatches` para gerar ZPL concatenado quando `entries.length > 3`; salvar um único `.zpl` com todos os blocos. Validar presença de `^XA` e `^XZ`. Botão renomeado para **Baixar arquivo ZPL** com tooltip explicativo.

**Alternativa:** Um arquivo por bloco de 3 — rejeitada; operador quer um arquivo por OP.

## Risks / Trade-offs

- **[Ordem de numeração após backfill]** → Documentar que números refletem ordem de primeiro teste/detecção; novas bancadas seguem sequência global.
- **[MAC ainda necessário para MQTT]** → Comandos internos continuam usando `device_id`; só UI muda.
- **[Relatórios Firestore]** → Campos `device_id` na nuvem inalterados; export CSV local usa Bancada N.

## Migration Plan

1. Deploy app com migração Drift v11 + backfill `bancadas`.
2. Primeira abertura atribui números; UI passa a mostrar Bancada 1, 2, 3.
3. Rollback: reverter app; tabela `bancadas` ignorada em versão antiga.

## Open Questions

- Permitir editar apelido da bancada ("Bancada 1 — Linha A")? **Proposta:** fora de escopo; só número.
- Mostrar MAC no CSV? **Proposta:** coluna opcional "Identificador técnico" após "Bancada" para suporte.
