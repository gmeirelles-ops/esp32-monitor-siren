## Context

O app Flutter (`sirene_app/`) é o companion desktop Windows do firmware `sirene-validator`. Hoje:

- Rota inicial: tela **Dispositivos** (descoberta via `sirene/+/heartbeat`)
- Cadastro: apenas **produtos** em área admin separada
- Sem entidade **operador** no SQLite/Firestore
- Layout funcional mas sem design system unificado

O operador de bancada precisa configurar lote, acompanhar testes e imprimir etiquetas — não gerenciar dispositivos como primeira ação. A rastreabilidade industrial exige saber **quem** operou cada lote/teste.

**Restrições:** firmware inalterado; SQLite permanece primário; sync Firestore opcional; Windows desktop como alvo principal.

## Goals / Non-Goals

**Goals:**

- Lote como tela inicial e hub operacional
- Operador obrigatório e rastreável em lote/teste/sync
- Cadastros unificados (produtos + operadores)
- Layout mais profissional: hierarquia, empty states, status no shell
- Descoberta MQTT de dispositivos em background (não bloqueia UX)

**Non-Goals:**

- Autenticação biométrica ou badge RFID
- Multi-dispositivo simultâneo no mesmo posto
- Alterações no firmware ESP32 ou contratos MQTT existentes
- Redesign completo de marca (logo/cores corporativas) — apenas elevação de UX

## Decisions

### 1. Navegação: `go_router` com `/lote` como `initialLocation`

- **Escolha:** `/lote` substitui `/devices` como rota inicial; `/settings/device` absorve seleção de dispositivo.
- **Alternativa rejeitada:** manter Devices como segunda aba — ainda desvia atenção do fluxo principal.
- **Alternativa rejeitada:** wizard de onboarding — complexidade desnecessária para posto já configurado.

### 2. Modelo de dados: tabela `operators` no Drift

```dart
class Operators extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get matricula => text().nullable()();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get criadoEm => dateTime()();
}
```

- Campos `operadorId` / `operadorNome` adicionados em `batches` e `test_results` (migration vN).
- **Alternativa rejeitada:** reutilizar Firebase Auth users como operadores — mistura login de sync com identidade de chão de fábrica.

### 3. Seleção de operador: `OperatorSessionProvider` (Riverpod)

- Persiste `selectedOperatorId` em `SharedPreferences`.
- Gate no `BatchController`: `canStartBatch` exige operador + device + broker.
- Cabeçalho global mostra chip "Operador: Nome" com tap para trocar.

### 4. Dispositivos: serviço em background

- `DeviceDiscoveryService` (já existente ou extraído) roda ao conectar MQTT; atualiza lista em Configurações.
- `AppShell` consome `DeviceStatusProvider` para ícone online/offline.
- Tela `DevicesPage` deprecada — lógica migrada para `SettingsDeviceSection`.

### 5. Cadastros unificados: `CadastrosPage` com `TabBar`

- Aba **Produtos:** reutiliza widgets de `ProductListPage` / formulários existentes.
- Aba **Operadores:** nova `OperatorListPage` + `OperatorFormDialog`.
- Rota `/cadastros` substitui rotas admin fragmentadas.

### 6. Layout: tokens leves em `lib/core/theme/`

| Token | Valor sugerido |
|-------|----------------|
| `spacing.sm/md/lg` | 8 / 16 / 24 |
| `radius.card` | 12 |
| `elevation.card` | 1 |
| Cores status | verde=online, âmbar=aviso, vermelho=erro |

- Componentes novos: `AppShellScaffold`, `StatusChip`, `EmptyStateCard`, `PostoSummaryCard`.
- **Alternativa rejeitada:** adotar pacote de design externo pesado (Material 3 custom theme suficiente).

### 7. Firestore sync

- Nova coleção `operators/{id}` espelhando SQLite.
- `batches` e `test_results` ganham campos `operador_id`, `operador_nome`.
- Regras Firestore: leitura autenticada; escrita pelo `station_id` do posto.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Migration Drift quebra bancos em campo | Migration incremental; testar com DB seed; backup automático antes de migrate |
| Operador esquece de trocar no turno | Chip visível no cabeçalho; opcional: lembrete ao abrir app após 8h |
| Dispositivo não configurado bloqueia lote | Banner com CTA em Configurações; não bloquear visualização de cadastros |
| Specs sem código Flutter no repo atual | Implementação em `sirene_app/` (repositório sibling); tasks referenciam paths esperados |

## Migration Plan

1. Deploy app com migration SQLite (operadores + colunas em batches/test_results).
2. Administrador cadastra operadores na nova aba.
3. Operadores passam a selecionar identidade no início do turno.
4. Dados históricos sem `operador_id` permanecem com campo nulo (aceitável).
5. Atualizar regras Firestore e publicar com `firebase deploy --only firestore`.
6. Rollback: versão anterior do app; colunas novas ignoradas pelo schema antigo.

## Open Questions

- Operador comum pode ver lista de operadores (somente leitura) para trocar a si mesmo, ou apenas admin cadastra?
- `station_id` único por PC Windows — confirmar se já existe em Configurações → Nuvem.
- Impressão de etiqueta deve incluir nome/matrícula do operador na ZPL? (fora do escopo inicial, avaliar fase 2)
