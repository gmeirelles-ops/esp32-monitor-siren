## Why

A tela de Lote atual mistura configuração (`SET_BATCH`) e acompanhamento em um único formulário, com pouca visibilidade do histórico e métricas do lote em execução. O operador precisa de uma visão dedicada — com status ao vivo, operador, aprovados/reprovados e gráficos — logo após configurar o lote. Além disso, o desenvolvimento do fluxo completo fica bloqueado sem hardware PZEM; é necessário um modo de simulação com potências fictícias.

## What Changes

- Separar o fluxo em duas etapas: **configuração** (formulário atual) e **painel ao vivo do lote** (nova tela aberta após `SET_BATCH` bem-sucedido).
- Nova tela **Batch Live Dashboard** com:
  - Cabeçalho do lote (OP, produto, dispositivo, estado FSM, operador autenticado).
  - Contadores de aprovados, reprovados, pendentes e progresso em relação à meta.
  - Gráfico de potência média por teste (linha ou barras coloridas por veredito).
  - Lista cronológica de testes do lote corrente (sequencial, veredito, potência, serial, horário).
  - Indicadores de estado (`BATCH_READY`, `TESTING`) e ações `END_BATCH`.
  - Cards extras: yield do lote, última rejeição MQTT, etiquetas na fila de impressão.
- Persistir e consultar testes **filtrados por `numero_op`** no SQLite para alimentar o dashboard.
- **Modo desenvolvimento** (somente builds debug / flag explícita):
  - Botão "Simular teste" que injeta resultado fictício (potência aleatória dentro/fora dos limites) no pipeline MQTT local, sem PZEM.
  - Opcional no firmware: flag de compilação `CONFIG_DEV_MOCK_PZEM` para ciclo completo via botão físico com leituras simuladas.
- A tela de configuração de lote permanece para novo `SET_BATCH`; se já houver lote ativo no dispositivo, oferecer atalho "Ver lote em andamento".

## Capabilities

### New Capabilities

- `batch-live-dashboard`: Tela dedicada de acompanhamento ao vivo do lote com métricas, gráficos e histórico por OP.
- `batch-dev-simulator`: Modo de desenvolvimento para simular testes com potências fictícias sem dependência do PZEM.

### Modified Capabilities

- `batch-operator-ui`: Navegação pós-`SET_BATCH` para o dashboard; confirmação por rejeição (não mais timeout de heartbeat); remoção do acompanhamento detalhado da tela de configuração.
- `batch-test-execution`: Suporte opcional a medição PZEM simulada em build de desenvolvimento do firmware.

## Impact

- **App Flutter**: `batch_screen.dart` (refatorar), nova `batch_live_screen.dart`, providers de métricas por OP, queries Drift por `numero_op`, possível dependência de gráficos (`fl_chart` ou similar já usado no painel).
- **Banco local**: query `watchTestsByOp(numeroOp)`; sem migração de schema (campos já existem em `test_results`).
- **Firmware** (opcional): componente `pzem` ou `main.c` com ramo `CONFIG_DEV_MOCK_PZEM`.
- **Specs existentes**: `batch-operator-ui`, `production-dashboard` (reuso de padrões de gráfico), `operator-traceability`.
