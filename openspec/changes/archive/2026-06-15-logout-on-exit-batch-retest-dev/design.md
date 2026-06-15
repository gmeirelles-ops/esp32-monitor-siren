## Context

O app Flutter já exige login por PIN na abertura (`operator-pin-login`, implementado) e persiste `activeOperatorId` em `SharedPreferences` via `AppConfig`. Isso faz com que fechar e reabrir o app mantenha o operador logado — comportamento que o usuário quer inverter.

No lote, o firmware já encerra automaticamente via `END_BATCH` interno quando `aprovados >= quantidade_total` após uma aprovação (`cota_atingida` em `main.c`), mas o app apenas mostra aviso "Meta atingida" e deixa o encerramento manual. O app também gera serial, incrementa contador e avança sequencial em `processTestResult` para cada aprovação MQTT, sem distinção de reteste.

Impressão ZPL existe (`zpl_generator.dart`, `LabelPrinter`); não há exportação de arquivo para inspeção em dev.

## Goals / Non-Goals

**Goals:**
- Limpar sessão de operador quando o app é fechado, minimizado até detach ou processo encerrado (desktop/mobile).
- Enviar `END_BATCH` automaticamente pelo app quando a meta do lote for atingida (após último teste que completa a cota).
- Checkbox "Reteste" no Batch Live; sincronizar flag com firmware via MQTT; app e firmware não consomem serial/cota em reteste.
- Botão "Baixar ZPL" visível apenas em `kDebugMode`.

**Non-Goals:**
- Reteste remoto sem bancada configurada (reteste exige lote ativo na bancada).
- Exportar ZPL em builds de release ou para operadores de produção.
- Alterar layout físico da etiqueta ou impressora.
- Auto-logout por timeout de inatividade (somente fechamento do app).

## Decisions

### 1. Logout ao fechar o app

**Decisão:** Registrar `WidgetsBindingObserver` no widget raiz (`AppGate` ou `SireneApp`). Em `AppLifecycleState.detached` (e `hidden` no desktop quando aplicável), chamar `clearActiveOperator()` sem `ref` (via `AppConfig` direto). Manter logout explícito em Configurações.

**Alternativa:** Não persistir `activeOperatorId` em disco — rejeitada; ainda precisaria limpar em memória durante a sessão e o PIN login já usa prefs para a sessão corrente.

**Alternativa:** Timeout de inatividade — fora de escopo.

### 2. Auto encerrar lote

**Decisão:** No app, após `processTestResult` (ou ao receber MQTT com `aprovados_no_lote >= quantidade_total`), se meta atingida e lote ainda ativo, publicar `END_BATCH` uma vez (guard com flag `_autoEndBatchSent` por dispositivo/OP). Navegar de volta à configuração de lote ou exibir estado "Lote encerrado" como no encerramento manual.

**Critério:** `aprovados_no_lote >= quantidade_total` com `quantidade_total > 0` — alinhado ao firmware e à barra de progresso do dashboard.

**Alternativa:** Confiar só no `cota_atingida` do firmware — insuficiente; app precisa limpar `activeBatch` e UI.

### 3. Modo reteste — contrato MQTT

**Decisão:** Campo opcional `modo_reteste: true|false` no payload `SET_BATCH`. Ao marcar checkbox no app, reenviar `SET_BATCH` com os mesmos parâmetros do lote corrente e `modo_reteste` atualizado. Firmware: quando `modo_reteste` é true, ao aprovar teste **não** incrementa `aprovados` nem `proximo_sequencial`; ainda publica resultado MQTT com veredito e potência (sequencial reportado = valor que seria usado, ou 0 — ver spec).

**Alternativa:** Comando separado `SET_RETEST_MODE` — válido, mas `SET_BATCH` já é o canal de configuração do lote; estender é menos surface area.

**App:** `retestModeProvider` (StateProvider<bool>); `processTestResult` verifica flag local **e** ignora serial/buffer/counter/advance se reteste; grava `test_results` com `is_retest = 1` e `serial` nulo.

### 4. Métricas de progresso em reteste

**Decisão:** Testes em reteste são gravados no SQLite para rastreabilidade, mas **excluídos** do cálculo de aprovados/reprovados/yield/pendentes no dashboard (filtro `is_retest = 0` em `getBatchMetrics`).

### 5. Export ZPL em dev

**Decisão:** Na tela Etiquetas (ou seção dev do Batch Live), botão "Baixar ZPL" visível se `kDebugMode`. Gera ZPL do buffer corrente (ou bloco selecionado) via `generateZplLabelRow` e salva com `file_picker` / `path_provider` + `File.writeAsString` (desktop) ou diálogo nativo. Nome sugerido: `etiquetas_<OP>_<timestamp>.zpl`.

**Alternativa:** Copiar para clipboard — menos útil para inspeção de arquivo completo.

## Risks / Trade-offs

- **[Lifecycle inconsistente entre plataformas]** → Tratar `detached` + `AppLifecycleState.paused` no desktop com debounce curto; documentar que "fechar janela" no Windows dispara detach.
- **[SET_BATCH durante teste rejeitado ao togglar reteste]** → Desabilitar checkbox enquanto `TESTING`; ou enfileirar toggle após teste (preferir desabilitar).
- **[Firmware antigo sem modo_reteste]** → App ainda suprime serial localmente; firmware pode consumir cota — exibir aviso se versão firmware não suporta flag (detecção futura); nesta entrega firmware e app atualizados juntos.
- **[Auto END_BATCH duplicado]** → Firmware já pode enviar `cota_atingida`; app idempotente com guard e tolerância a rejeição `END_BATCH` se lote já idle.

## Migration Plan

1. Deploy firmware com `modo_reteste` (retrocompatível: ausente = false).
2. Deploy app; migração Drift adiciona `is_retest` em `test_results` default 0.
3. Operadores passam a logar PIN a cada abertura do app — comunicar na implantação.
4. Rollback: reverter app (sessão volta a persistir) e firmware (ignora campo extra).

## Open Questions

- Sequencial reportado em reteste no MQTT: usar `proximo_sequencial` atual sem incrementar (espelha "próxima peça") — adotado na spec.
- Auto END_BATCH deve imprimir etiquetas órfãs antes? **Proposta:** sim, chamar mesmo fluxo de fechamento manual (`_maybePrintLabels` + flush órfãs) antes de `END_BATCH`.
