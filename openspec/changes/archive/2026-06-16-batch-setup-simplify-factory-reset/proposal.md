## Why

Na tela de **Lote**, campos como **Ano** e **Próximo sequencial** expõem detalhes internos do protocolo ITF que o operador não precisa decidir — o ano deve seguir a data atual e o sequencial já é controlado pelo contador local. A seleção de **bancada** no formulário de lote gera troca acidental entre dispositivos; no chão de fábrica cada PC/posto fica fixo em uma bancada, configurada uma vez.

Supervisores também precisam de um **reset geral** em Configurações para reconfigurar um posto (novo Wi-Fi, nova bancada, dados locais zerados) sem caçar arquivos no disco.

## What Changes

- **Lote simplificado:** remover campos visíveis `Ano` e `Próximo sequencial`; o app deriva `ano` de `DateTime.now()` (2 dígitos) e calcula `proximo_sequencial` via `SerialCounters` / reconciliação existente antes de `SET_BATCH`.
- **Bancada como setup do posto:** vínculo `device_id` ↔ posto persistido em `AppConfig` (`selected_device_id`); configurado no **assistente de setup inicial** ou em **Configurações → Posto → Bancada**; tela de Lote exibe bancada **somente leitura** (sem dropdown).
- **Setup obrigatório:** se não houver bancada vinculada, o app direciona ao fluxo de configuração antes de permitir `SET_BATCH`.
- **Reset geral do posto** em Configurações: apaga SQLite local, limpa `SharedPreferences` operacionais, remove vínculo de bancada, marca Wi-Fi como não provisionado e exige novo login de operador — com confirmação forte (digitar `ZERAR`).
- Testes unitários para derivação de ano/sequencial e para o serviço de reset.

### Sugestões adicionais incluídas

| Sugestão | Escopo |
|----------|--------|
| Card read-only na Lote: "Bancada 2 — conectada" | Contexto sem edição |
| Link "Alterar bancada" só em Configurações | Evita troca acidental |
| Painel de reconciliação de série movido para Configurações/Admin | Operador comum não vê gaps técnicos |
| Após reset, reabrir assistente Wi-Fi opcional | Um fluxo para reconfigurar rede |
| Documentar caminhos de dados em `PRODUCAO.md` | Alinhado ao reset documentado antes |

### Fora de escopo

- Alterar protocolo MQTT `SET_BATCH` no firmware (payload continua com `ano` e `proximo_sequencial`).
- Reset remoto via Firestore.
- Multi-bancada no mesmo PC (um posto = uma bancada).

## Capabilities

### New Capabilities

- `posto-bancada-setup`: vínculo único bancada↔app, setup inicial e edição só em Configurações
- `factory-reset`: reset geral local (dados, Wi-Fi, bancada) com confirmação

### Modified Capabilities

- `batch-operator-ui`: formulário de lote sem ano/sequencial visíveis; usa bancada do setup
- `batch-test-execution`: derivação automática de ano e próximo sequencial no app
- `flutter-app-shell`: gate de setup quando bancada ausente
- `wifi-provisioning-wizard`: estado "provisionado" persistido; limpo no reset geral

## Impact

- `sirene_app/lib/features/batch/batch_screen.dart` — remover campos; bancada read-only
- `sirene_app/lib/features/batch/batch_serial_logic.dart` — helper `resolveBatchYear()`, `resolveProximoSequencial()`
- `sirene_app/lib/features/settings/settings_screen.dart` — seção Bancada + Reset geral
- `sirene_app/lib/core/config/app_config.dart` — flags `wifiProvisioned`, helpers de setup
- Novo `posto_setup_screen.dart` ou wizard enxuto
- Novo `factory_reset_service.dart` — apagar DB, prefs, reiniciar app
- `docs/PRODUCAO.md` — setup de posto e reset
- Testes: `batch_serial_logic_test.dart`, `factory_reset_test.dart`
