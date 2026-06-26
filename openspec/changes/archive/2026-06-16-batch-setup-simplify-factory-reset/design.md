## Context

Estado atual:

```
BatchScreen
  ├─ Dropdown bancada (selectedDeviceId em AppConfig + UI)
  ├─ Campos: OP, Ano, Quantidade, Próximo sequencial
  └─ SET_BATCH → BatchLiveScreen

AppConfig.selectedDeviceId  → SharedPreferences
SQLite bancadas           → MAC → número sequencial
ProvisioningWizard        → modal Wi-Fi, sem flag "já provisionado"
```

O operador não deve decidir ano (vem do relógio do PC) nem sequencial (vem do contador por `id_produto|ano`).

## Goals / Non-Goals

**Goals:**

- Formulário de lote com **menos campos**: produto, OP, quantidade.
- **Uma bancada por instalação** do app no posto.
- **Reset de fábrica** reproduzível pela UI para TI/supervisor.

**Non-Goals:**

- Editar sequencial manualmente (supervisor usa Admin/reconciliação futura se necessário).
- Apagar dados na nuvem Firestore.

## Decisions

### 1. Ano derivado da data local

```dart
String resolveBatchYear([DateTime? now]) {
  final y = (now ?? DateTime.now()).year % 100;
  return y.toString().padLeft(2, '0');
}
```

Usado em `_buildBatch` e ao carregar contador de seriais. Relógio errado no PC afeta o ano do serial — aceito (mesmo risco de hoje com campo manual).

### 2. Próximo sequencial invisível

Antes de `SET_BATCH`:

```dart
Future<int> resolveProximoSequencial(AppDatabase db, String idProduto, String ano) async {
  final last = await db.getLastSequencial(idProduto, ano);
  return (last ?? 0) + 1;
}
```

Opcional: se `reconcileSerials` detectar gaps, log interno + SnackBar discreto em Configurações — **não** bloqueia lote neste change.

Remover `TextFormField` de ano e sequencial; manter painel de reconciliação fora da Lote (Configurações → Avançado ou Admin).

### 3. Bancada vinculada ao posto

| Estado | Onde configura | Onde aparece |
|--------|----------------|--------------|
| Não configurada | Setup inicial ou Config → Bancada | Lote bloqueado com CTA |
| Configurada | Somente Config → Bancada | Lote read-only + live dashboard |

Persistência: `AppConfig.selectedDeviceId` (já existe). Adicionar `AppConfig.bancadaSetupComplete` (bool) setado ao confirmar primeira escolha.

**Setup inicial (após login):** se `!bancadaSetupComplete`, exibir `PostoSetupScreen` com lista de dispositivos MQTT detectados (ou mensagem "aguardando bancada" + link Wi-Fi).

**Lote:** substituir `DropdownButtonFormField` por `ListTile` read-only com status online/offline; link "Alterar em Configurações".

### 4. Reset geral do posto

Novo `FactoryResetService`:

1. Confirmar com `AlertDialog` + campo texto `ZERAR`
2. Fechar DB (`databaseProvider.close`)
3. Apagar arquivo `Documents/sirene_app.sqlite`
4. `SharedPreferences.clear()` ou lista allowlist mínima (nenhuma — reset total)
5. Limpar `sessionOperatorIdProvider`
6. `restartApp` via `Phoenix` pattern ou `SystemNavigator` + relaunch — no Windows desktop: mostrar diálogo "Feche e abra o app" se hot restart não for viável

**Wi-Fi:** `setWifiProvisioned(false)` — flag nova; após reset, card em Config sugere "Provisionar Wi-Fi".

**Bancada:** `setSelectedDeviceId(null)`, `setBancadaSetupComplete(false)`.

Não apaga Firestore nem credenciais Firebase se quiser manter sync — **decisão:** reset local limpa também `sync_enabled` e operador; Firebase Auth logout opcional com checkbox "Sair da nuvem também" (default off).

### 5. UI Configurações

Nova seção **Manutenção do posto**:

- **Bancada vinculada:** dropdown (mesmo da Lote hoje) + Salvar
- **Provisionamento Wi-Fi:** atalho existente
- **Reset geral do posto:** botão destrutivo vermelho → fluxo `ZERAR`

### 6. Fluxo de navegação

```
Login → (bancada ok?) → Shell
         └─ não → PostoSetupScreen → Shell

Lote → se !bancada → redirect PostoSetup
```

## Risks / Trade-offs

- **[Ano virada]** — contador é por `(id_produto, ano)`; virada de ano cria chave nova automaticamente ✓
- **[Reset sem fechar app]** — drift pode manter handle aberto; fechar `AppDatabase` antes de apagar arquivo
- **[Operador perde histórico local]** — reset é destrutivo; confirmação explícita

## Migration Plan

1. Deploy com campos ocultos mas lógica nova (feature pode ir direto).
2. Postos existentes com `selectedDeviceId` já salvo: `bancadaSetupComplete = true` na migração de prefs.
3. Documentar reset em `PRODUCAO.md`.

## Open Questions

- Reset deve deslogar Firebase Auth por padrão? **Proposta:** não, só dados locais; checkbox opcional.
- Setup inicial obriga provisionar Wi-Fi antes da bancada? **Proposta:** Wi-Fi recomendado mas não bloqueante — bancada pode ser escolhida se dispositivo já na rede.
