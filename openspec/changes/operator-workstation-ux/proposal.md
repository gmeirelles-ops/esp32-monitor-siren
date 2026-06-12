## Why

O fluxo atual abre em **Dispositivos**, mas o operador no posto começa pelo **Lote** — a primeira aba é técnica, não operacional. Operadores são rastreados só via e-mail Firebase (quando sync está ligado), sem cadastro local nem seleção explícita no turno. Cadastros estão fragmentados (Produtos isolado, sem Operadores). A navegação com 7 abas (incluindo Admin) sobrecarrega mobile e mistura papéis de operador e manutenção.

Esta change reorganiza o app como **estação de trabalho do operador**: Lote na entrada, operador selecionado no turno, cadastros unificados e layout mais consistente — elevando usabilidade sem alterar contratos MQTT/firmware.

## What Changes

- Remover **Dispositivos** da navegação principal; **Lote** passa a ser a tela inicial.
- Seletor de **operador ativo** persistente (SQLite), obrigatório antes de iniciar lote; gravado em cada teste.
- Nova tela **Cadastros** com abas **Produtos** e **Operadores** (CRUD local).
- Dispositivos e detalhe técnico acessíveis via **Configurações → Dispositivos** (ou drawer secundário).
- **Admin/OTA** movido para Configurações (supervisor), fora da nav principal.
- Shell unificada: `DipontoAppBar` em mobile e desktop; status MQTT + operador ativo sempre visíveis.
- Layout: hierarquia visual no Lote (operador → dispositivo → produto → OP), cards e espaçamento revisados.
- Banner global de falha de impressão (snackbar persistente ou barra no shell).
- Testes unitários e widget para seletor de operador e cadastros.

## Capabilities

### New Capabilities

- `operator-registry`: cadastro local de operadores e seleção do operador ativo do turno

### Modified Capabilities

- `flutter-app-shell`: navegação centrada no operador (Lote primeiro, Cadastros, sem Dispositivos/Admin na rail)
- `batch-operator-ui`: seletor de operador e dispositivo integrados no fluxo de lote
- `operator-traceability`: rastreio por operador local (nome/código), com fallback Firebase quando aplicável
- `product-catalog`: cadastros agrupados com operadores na mesma área
- `desktop-ui-layout`: shell workstation, AppBar consistente, hierarquia visual
- `device-monitoring`: lista de dispositivos como área secundária (Configurações), não aba principal

## Impact

- **App Flutter**: `app.dart`, `batch_screen.dart`, `batch_live_screen.dart`, novo `operators_*`, `cadastros_screen.dart`, `database.dart` (schema v9, tabela `operators`), `mqtt_providers.dart` (operador ativo), `settings_screen.dart`, remoção de Admin da nav
- **Firestore**: campo `operador` nos testes passa a usar nome/código local; sync inalterado em estrutura
- **Firmware / MQTT**: sem alteração de contrato
