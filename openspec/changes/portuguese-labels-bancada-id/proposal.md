## Why

Operadores veem identificadores técnicos (MAC MQTT) onde deveriam ver linguagem de fábrica em português, e rótulos misturados (Yield, Dispositivo, Online) prejudicam o uso no chão de fábrica. A numeração sequencial de bancadas (1, 2, 3…) alinha o app ao vocabulário do posto e facilita relatórios e filtros. O download de impressão em dev já existe mas precisa ser validado e rotulado explicitamente como arquivo ZPL.

## What Changes

- Cadastro automático de **bancadas numeradas** (1, 2, 3…) ao detectar cada `device_id` MQTT (MAC); exibição principal **Bancada N** em todo o app, com MAC restrito a detalhe técnico ou admin.
- Padronização de **nomenclatura em português** na UI e exportações: Rendimento (ex-Yield), Conectada/Desconectada, seção **Bancadas** (ex-Dispositivos), mensagens e cabeçalhos CSV alinhados.
- Revisão do botão **Baixar arquivo ZPL** (modo dev): extensão `.zpl`, conteúdo `^XA`…`^XZ`, agrupamento correto quando há mais de 3 seriais, feedback em português.
- **BREAKING**: Rótulo `formatBancadaLabel` deixa de mostrar MAC cru; relatórios e filtros passam a exibir número da bancada (MAC permanece armazenado internamente).

## Capabilities

### New Capabilities

- `bancada-numbering`: mapeamento persistente MAC → número sequencial de bancada e API de rótulo
- `portuguese-ui-nomenclature`: glossário e requisitos de textos em português no app e exportações

### Modified Capabilities

- `device-monitoring`: lista e detalhe exibem bancada numerada; MAC em campo técnico secundário
- `flutter-app-shell`: navegação e títulos usam "Bancadas" e termos em português
- `desktop-ui-layout`: rótulos de formulário, métricas e estados em português consistente
- `production-dashboard`: Rendimento em vez de Yield; filtros "Bancada" com número
- `dev-label-file-export`: validação e rótulo explícito de arquivo ZPL
- `batch-live-dashboard`: nomenclatura de métricas e estados em português

## Impact

- **App Flutter**: `display_labels.dart`, nova tabela `bancadas` (Drift), `devices_screen.dart`, `device_detail_screen.dart`, dashboards, relatórios CSV, `labels_screen.dart`, `app.dart` (nav)
- **SQLite**: migração com tabela `bancadas`; backfill para dispositivos já conhecidos em `test_results`
- **MQTT / firmware**: sem alteração de `device_id` no broker (continua MAC); apenas camada de apresentação no app
- **Testes**: unitários de numeração, rótulos PT, export ZPL com extensão e conteúdo
