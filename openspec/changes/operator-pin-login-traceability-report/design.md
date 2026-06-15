## Context

O app Flutter já possui cadastro local de operadores (`operators`: `codigo`, `nome`, `ativo`) e rastreabilidade em `test_results` (serial, OP, veredito, potência, operador, dispositivo, timestamp). A seleção de operador ativo hoje é opcional via chip/sheet no Lote. O login Firebase existe apenas para sync em nuvem e não bloqueia o uso do app.

A change `serial-op-lookup-screen` (ainda não aplicada) cobre busca tabular por serial/OP; esta change foca em **gate de entrada por PIN** e **relatório consolidado** (ficha da sirene) — complementar, não duplicado.

## Goals / Non-Goals

**Goals:**
- Tela de login como primeira tela; sessão de operador obrigatória para o shell principal.
- Lista de operadores ativos visível na login; autenticação por PIN (`codigo`).
- Persistir `activeOperatorId` em SharedPreferences (reutiliza `AppConfig` existente).
- Tela Relatório com busca por serial e visão consolidada (teste aprovado, tentativas, etiqueta, metadados).
- Reimpressão de etiqueta a partir do relatório (reutiliza `label_print_logic`).
- Testes unitários de PIN e query; widget test da login.

**Non-Goals:**
- Hash de PIN ou autenticação forte — PIN é identificador operacional de posto, não segredo de rede.
- Rastreabilidade na nuvem Firestore (somente SQLite local).
- Substituir Firebase Auth para sync (permanece em Configurações → Nuvem).
- Mesclar com `serial-op-lookup-screen` nesta entrega (pode coexistir depois).

## Decisions

### 1. PIN = campo `codigo` existente

**Decisão:** Reutilizar `operators.codigo` como PIN numérico/alfanumérico (4–8 caracteres). Renomear rótulo na UI de cadastro para "PIN" sem migração de schema.

**Alternativa:** Nova coluna `pin_hash` — rejeitada por complexidade desnecessária em ambiente de fábrica fechado.

### 2. Fluxo de login

**Decisão:** Tela full-screen com:
- Lista/grid de operadores ativos (avatar inicial + nome; PIN oculto).
- Campo PIN mascarado + botão "Entrar".
- Ao selecionar operador na lista, foco no campo PIN; validação: PIN informado deve coincidir com `codigo` do operador selecionado.
- Bloqueio após 5 tentativas falhas por 30s (por operador selecionado).

**Alternativa:** PIN global sem seleção de operador — rejeitada; usuário pediu nome do operador visível.

### 3. Roteamento inicial

**Decisão:** `MaterialApp` com `home` condicional via `activeOperatorProvider`:
- `null` → `OperatorLoginScreen`
- operador válido → `SireneAppShell` (conteúdo atual de `app.dart`)

Logout em Configurações limpa `activeOperatorId` e retorna ao login.

### 4. Relatório de rastreabilidade

**Decisão:** Nova rota "Relatório" na navegação principal (ícone `manage_search` ou `fact_check`), entre Painel e Etiquetas.

Query `getTraceabilityBySerial(serial)` em `database.dart`:
- Busca exata se 10 dígitos; `LIKE prefix%` se parcial (debounce 300ms, máx. 50 prefixos).
- Para serial exato: agrega `test_results` (todas tentativas ordenadas), entrada em `label_buffer_entries`, produto derivado dos 3 primeiros dígitos do serial via `products`.

UI: painel superior com serial, produto, veredito final (último aprovado ou último registro); timeline de tentativas; card de etiqueta; botão reimprimir se aprovado.

**Alternativa:** Reutilizar apenas DataTable da change serial-op-lookup — insuficiente para "rastreabilidade total" pedida.

### 5. Operador no Lote

**Decisão:** Remover obrigatoriedade do seletor no início do Lote; chip de operador ativo permanece somente leitura com opção "Trocar operador" (logout parcial → login). Testes gravam operador da sessão via `resolveOperadorLabel` existente.

## Risks / Trade-offs

- **[PIN em texto claro no SQLite]** → Aceitável para posto industrial; documentar que PIN não é credencial de nuvem.
- **[Operador esquece PIN]** → Supervisor edita em Cadastros (acessível após login de outro operador ou modo manutenção futuro).
- **[Sobreposição com serial-op-lookup]** → Relatório é ficha consolidada; Consulta futura permanece busca tabular ampla.
- **[Sem operadores cadastrados]** → Login exibe CTA para Cadastros; primeiro uso exige cadastro mínimo (supervisor).

## Migration Plan

1. Deploy app; operadores existentes mantêm `codigo` como PIN.
2. Primeira abertura pós-update exige login; `activeOperatorId` anterior (se houver) pode pré-selecionar operador na lista.
3. Rollback: reverter `app.dart` para shell direto sem gate.

## Open Questions

- Cadastros acessível sem login para bootstrap inicial? **Proposta:** link discreto "Configuração inicial" na login apenas quando `operators` está vazio.
- Exportar relatório em PDF/CSV nesta entrega? **Proposta:** fora de escopo; usar `production-reporting-export` depois.
