## Context

Hoje:
- Nav: Dispositivos | Lote | Painel | Produtos | Etiquetas | Config | Admin (7 itens)
- `processTestResult` usa `authServiceProvider?.currentUser?.email` como operador
- `BatchScreen` já tem dropdown de dispositivo; `DevicesScreen` duplica descoberta MQTT
- Mobile não usa `DipontoAppBar`; desktop só mostra provisionamento Wi-Fi na aba Dispositivos
- `printFailureProvider` visível principalmente em Etiquetas

Operadores em fábrica tipicamente não têm conta Firebase — rastreio local é mais realista.

## Goals / Non-Goals

**Goals:**
- Fluxo operador: abrir app → escolher operador → configurar/acompanhar lote.
- Cadastro simples de operadores (nome, matrícula/código, ativo).
- Nav enxuta: **Lote | Painel | Etiquetas | Cadastros | Configurações** (5 itens).
- Layout profissional e consistente desktop/mobile.

**Non-Goals:**
- Autenticação por PIN/biometria de operador (fase 2).
- Sync de operadores para Firestore nesta change (pode usar campo texto no teste).
- Remover `devicesProvider` ou monitoramento MQTT — só muda onde a UI vive.
- Papéis Firebase admin vs operador (change `harden-firestore-rules`).

## Decisions

### 1. Modelo de operador local (SQLite)

**Decisão:** tabela `operators`:
- `id` (PK autoincrement)
- `codigo` (text, unique, ex. matrícula "0042")
- `nome` (text)
- `ativo` (bool, default true)
- `created_at`

Operador ativo do turno: `SharedPreferences` `active_operator_id` + provider Riverpod.

**Alternativa:** só lista em memória — perde cadastro entre reinícios.

### 2. Rastreio em testes

**Decisão:** `test_results.operador` grava `"codigo — nome"` do operador ativo. Se Firebase autenticado e sem operador local, fallback para e-mail (compatibilidade).

**Alternativa:** coluna `operator_id` FK — mais normalizado; adotar FK opcional em schema v9 com denormalização do display name.

### 3. Navegação

**Decisão:**

```
NavigationRail / BottomNav (5):
  Lote (index 0, default)
  Painel
  Etiquetas
  Cadastros      ← TabBar: Produtos | Operadores
  Configurações  ← inclui link Dispositivos, Admin/OTA, sync

Dispositivos: rota push de Configurações (DevicesScreen reutilizada)
Provisionamento Wi-Fi: ícone na AppBar global ou dentro de Config → Dispositivos
```

**Alternativa:** drawer lateral — mais cliques; rail já funciona no desktop.

### 4. Seletor de operador

**Decisão:** chip/banner no topo do Lote e na `DipontoAppBar` (desktop): "Operador: Maria (0042)" → abre bottom sheet/dialog de seleção. Bloquear `SET_BATCH` se nenhum operador ativo.

**Alternativa:** login por operador a cada teste — lento no posto.

### 5. Cadastros unificados

**Decisão:** `CadastrosScreen` com `TabBar` Produtos | Operadores. Reutiliza listas/formulários existentes (`ProductsScreen` → tab; novo `OperatorsScreen`).

### 6. Layout workstation

**Decisão:**
- `DipontoAppBar` em todas as telas (mobile incluído) via shell wrapper ou cada screen migrada.
- Lote: seções em `FormSectionCard` — (1) Turno, (2) Bancada/dispositivo, (3) Produto e OP, (4) Ação.
- Cores de estado dispositivo (online/offline) inline no dropdown, não tela separada.
- Admin removido da nav; seção colapsável em Configurações.

### 7. Banner impressão global

**Decisão:** `MaterialApp` builder ou shell escuta `printFailureProvider` e exibe `MaterialBanner` dismissível até retry bem-sucedido.

## Risks / Trade-offs

- **[Operador não selecionado bloqueia linha]** → mensagem clara + último operador lembrado.
- **[Migration schema v9]** → Drift migration adiciona tabela; sem perda de dados.
- **[Supervisor perde acesso rápido a Admin]** → atalho em Configurações.
- **[Dispositivos menos visíveis]** → badge de contagem online no link em Configurações.

## Migration Plan

1. Deploy app; migration v9 cria `operators`.
2. Supervisor cadastra operadores em Cadastros antes do turno.
3. Treinar: selecionar operador ao iniciar posto.
4. Tela Dispositivos continua acessível via Configurações.

## Open Questions

- Operador inativo pode ser selecionado? (recomendado: não)
- Cadastro de operador exige supervisor? (v1: qualquer um com acesso ao app no posto)
