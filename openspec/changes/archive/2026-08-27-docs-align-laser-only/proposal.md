## Why

A documentação do monorepo e do firmware ficou atrás do código (guias ainda citam **1.7.x**, heartbeat **30 s**, fluxo com **Zebra**). Em produção a Diponto usa **somente laser Diatu/DiatuCAD** — o caminho Zebra (ZPL, buffer 3-across, USB RAW) é código morto e confunde posto e docs.

## What Changes

- **Alinhar docs** ao firmware **1.8.10** e ao comportamento real (heartbeat 10 s, tópicos `{site}/bancada-NN/...`, laser como única marcação física).
- **Remover Zebra do produto**: UI, config, geração ZPL, buffer de etiquetas, transportes TCP/USB RAW, preferências de impressora e textos “Etiquetas/Reimprimir” ligados a ZPL.
- Manter **gravação laser** (MarkQueue + TCP server :9101 + DiatuCAD) como único backend de marcação.
- Atualizar specs OpenSpec: capabilities de Zebra saem ou ficam como removidas; serial/remark/docs passam a laser-only.
- Testes: apagar/adaptar testes ZPL; garantir cobertura do caminho laser e remark “Regravar”.

## Capabilities

### New Capabilities

- _(nenhuma)_ — laser já existe no código; esta change consolida “somente laser” e documentação.

### Modified Capabilities

- `project-documentation`: README / PRODUCAO / guias firmware alinhados à versão e ao laser.
- `serial-and-labels`: geração ITF permanece; disparo físico só via fila laser (sem buffer ZPL).
- `remark-by-marking-mode`: remark = sempre regravação laser (sem ramo Zebra).
- `desktop-ui-layout`: Configurações e nav sem modo Etiquetas / impressora Zebra.
- `diatom-laser-marking`: promover requisitos laser como caminho único (nomenclatura Diatu no texto).
- `device-telemetry`: docs/spec alinhados a heartbeat 10 s (código atual).
- `label-printing`: **REMOVED** como capability de produto (Zebra fora).
- `windows-raw-label-printing`: **REMOVED**.
- `zpl-label-layout`: **REMOVED**.
- `nicelabel-reference-workflow`: **REMOVED** (referência histórica só em `docs/label-reference/` se mantida como arquivo morto ou deletada).

## Impact

- `sirene_app/lib/` — remover/simplificar `features/labels/` (ZPL, buffer, printers), `MarkingMode`, settings de impressora; MQTT só enfileira laser.
- `sirene_app/test/` — remover testes Zebra/ZPL; ajustar remark/mqtt.
- `docs/`, `README.md`, `sirene_app/README.md`, `sirene-validator/docs/` — versão, heartbeat, sem Zebra.
- `openspec/specs/` — sync na archive desta change.
- **Não** altera firmware C (só docs do validador), MQTT contracts, nem Firebase.
- DB: tabela `label_buffer_entries` deixa de ser escrita; migração opcional (manter coluna/tabela órfã ou dropar em schema bump).
