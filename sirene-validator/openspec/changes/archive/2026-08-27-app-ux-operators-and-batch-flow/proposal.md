## Why

O app Flutter atual abre na tela de **Dispositivos**, forçando o operador a um passo técnico antes do trabalho real (configurar e acompanhar lotes). Não há identificação de quem opera a bancada, o que limita rastreabilidade e auditoria. O cadastro de produtos está isolado e o layout não reflete o patamar de um sistema de produção industrial — é hora de alinhar a UX ao fluxo real do posto e preparar o app para rastreabilidade por operador.

## What Changes

- **BREAKING:** Remover a tela de Dispositivos como rota inicial; a **primeira tela passa a ser Lote** (configuração + dashboard ao vivo).
- Mover descoberta/seleção de dispositivo para **Configurações** ou seletor contextual discreto no fluxo de lote (não bloqueia o operador).
- Adicionar **seleção obrigatória de operador** antes de iniciar ou retomar um lote.
- Adicionar **cadastro de operadores** na mesma área administrativa de produtos (tela unificada "Cadastros").
- Melhorar **layout global**: hierarquia visual, tipografia, espaçamento, estados vazios, feedback de ações e consistência entre telas.
- Persistir `operador_id` / `operador_nome` em lotes, resultados de teste e fila de sync Firestore.
- Incluir melhorias de patamar: atalhos do operador, resumo do posto na home de lote, indicadores de conexão MQTT/dispositivo sem tela dedicada.

## Capabilities

### New Capabilities

- `operator-registry`: CRUD de operadores (SQLite local + sync opcional Firestore `operators`)
- `operator-selection`: Fluxo de escolha/troca de operador ativo no posto
- `app-shell-ui`: Design system leve, navegação e componentes visuais compartilhados

### Modified Capabilities

- `app-navigation`: Rota inicial, ordem de abas/menus e destino da descoberta de dispositivos
- `batch-workflow`: Lote exige operador; dashboard ao vivo como hub principal
- `product-admin`: Cadastros unificados (produtos + operadores)

## Impact

| Área | Impacto |
|------|---------|
| `sirene_app/lib/` | Rotas (`go_router`), telas iniciais, novos widgets e providers |
| `sirene_app/lib/data/` | Tabela Drift `operators`, migrations, repositório |
| `sirene_app/lib/features/batch/` | Gate de operador, remoção de dependência da tela Devices |
| `sirene_app/lib/features/admin/` | Tela Cadastros com abas Produtos / Operadores |
| `sirene_app/lib/features/devices/` | Rebaixada para configuração; descoberta MQTT em background |
| Firestore sync | Coleção `operators`, campos `operador_id` em `batches` e `test_results` |
| Documentação | Atualizar `GUIA_COMPLETO.md` seção 15 e fluxos de TESTING.md |
| Firmware ESP32 | **Sem alteração** — operador é responsabilidade do app |
