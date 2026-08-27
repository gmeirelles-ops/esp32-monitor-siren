## Why

Operadores de produção são leigos em informática: precisam de **poucas telas**, **um botão óbvio** e **feedback grande** (passou / falhou / grave no laser). Hoje o menu do operador inclui **Consulta** bloqueada (beco sem saída), o formulário de Lote e o painel ao vivo ainda empilham muitos cards, e a UI pede **F2** — no posto real o gatilho da gravação é o **pedal**, não o teclado.

## What Changes

Decisões (operador-first):

1. **Menu operador = só 2 itens:** `Lote` e `Gravação`. Remover Consulta do nav do operador (Consulta/Relatório ficam só para gestor).
2. **Tela ao vivo (Teste):** hierarquia para leigo — resultado APROVADO/REPROVADO dominante; progresso simples; aviso **“Acione o pedal”** bem visível quando há serial na fila; esconder painéis de diagnóstico (só gestor).
3. **Copy de gravação:** em toda UI do operador, substituir “F2 / DiatuCAD” por **pedal** (linguagem da linha). Configurações/docs técnicas do gestor MAY mencionar que o pedal dispara o mesmo ciclo do software do laser.
4. **Formulário Lote:** menos cards, campos principais em linha no desktop, CTA único “Iniciar lote”, texto curto em português claro.
5. **Tokens de largura** + sync OpenSpec.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `flutter-app-shell` — destinos por papel (operador 2 / gestor completo)
- `desktop-ui-layout` — tokens + densidade Lote
- `batch-operator-ui` — formulário simplificado
- `batch-live-dashboard` — hierarquia visual + pedal
- `diatu-laser-marking` / copy de remark — instrução ao operador = pedal

## Impact

- `app.dart`, `batch_*`, `labels_*` (callouts, remark, empty states), `layout.dart`
- Sem mudança MQTT/firmware/protocolo TCP
- Gestores mantêm Painel, Relatório, Consulta, etc.
