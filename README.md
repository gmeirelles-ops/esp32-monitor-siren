# Diponto — Monitor Sirene Validator

[![CI](https://github.com/gmeirelles-ops/esp32-monitor-siren/actions/workflows/ci.yml/badge.svg)](https://github.com/gmeirelles-ops/esp32-monitor-siren/actions/workflows/ci.yml)

Monorepo do sistema de validação de sirenes em linha de produção: firmware ESP32, app Flutter de operação e sincronização opcional com Firebase.

## Arquitetura

```
  ┌──────────────┐     MQTT (Mosquitto)      ┌─────────────────┐
  │ ESP32        │◄────────────────────────►│ App Flutter     │
  │ sirene-      │   sirene/<id>/status      │ sirene_app      │
  │ validator    │   heartbeat, alerta,      │ (Windows posto) │
  └──────────────┘   calibracao, comando     └────────┬────────┘
         │                                            │
         │ Wi-Fi / portal 192.168.4.1                 │ SQLite local
         ▼                                            ▼
  ┌──────────────┐                          ┌─────────────────┐
  │ PZEM + relé  │                          │ Etiquetas /     │
  │ botão físico │                          │ Lote (INICIAR)  │
  └──────────────┘                          └────────┬────────┘
                                                     │
                              sync opcional          ▼
                                          ┌─────────────────┐
                                          │ Firestore       │
                                          └────────┬────────┘
                                                   │
                                          (sync opcional)
```

## Gestor vs operador (um único app)

O **sirene_app** atende operador e gestor no mesmo binário. No cadastro de operadores, marque **Gestor** para quem deve ver telas administrativas após o login com PIN.

| | Operador | Gestor |
|--|----------|--------|
| Login | PIN local | PIN local (flag Gestor) |
| Menu | Lote, Gravação | Lote, Painel, Relatório, Gravação, Cadastros, Configurações |
| Painel / cadastros | Não | Sim |

O projeto `sirene_manager_app/` (app separado com Firestore) ficou **experimental** e não é necessário para o fluxo atual.

## Estrutura do repositório

| Pasta | Conteúdo |
|-------|----------|
| `sirene-validator/` | Firmware ESP-IDF (testes, MQTT, offline, OTA) |
| `sirene_app/` | App Flutter desktop (operador + gestor com flag no login) |
| `sirene_manager_app/` | *(experimental, não usado)* app gestor separado com Firestore |
| `firebase/` | Regras e índices Firestore |
| `scripts/` | Setup Firebase, benches MQTT |
| `docs/` | Checklist de produção |
| `openspec/` | Especificações e changes (workflow OpenSpec) |

## Pré-requisitos

- **Firmware:** ESP-IDF v5.x, Python 3
- **App:** Flutter stable (SDK em `sirene_app/pubspec.yaml`)
- **Nuvem (opcional):** Node.js + Firebase CLI para deploy de regras
- **Produção:** PC Windows no posto, broker Mosquitto na LAN, impressora Zebra

## Testes rápidos

### CI local (recomendado antes do push)

```bash
./scripts/ci_local.sh
```

Executa os mesmos passos dos jobs `flutter-test` e `firmware-host-tests` do GitHub Actions.

### App Flutter

```bash
cd sirene_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

### Host tests do firmware (lógica pura, sem ESP32)

```bash
./sirene-validator/scripts/run_host_tests.sh
```

### Build firmware (requer ESP-IDF no PATH)

```bash
cd sirene-validator
idf.py -B /tmp/sv_build build
```

## Produção em fábrica

Guia completo de deploy, provisionamento Wi-Fi/MQTT, Firebase e cadastro de produtos:

→ **[docs/PRODUCAO.md](docs/PRODUCAO.md)**

### App Windows no pendrive

```powershell
# Na raiz, em PC Windows com Flutter + VS C++
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1
```

Ou baixe o ZIP pelo GitHub Actions: **CI** → **Run workflow** → artifact `DipontoSireneValidator-win64.zip`.

## OpenSpec (desenvolvimento)

Changes ativas ficam em `openspec/changes/<nome>/`. Workflow:

1. `/opsx:propose` — criar proposta com design e tasks
2. `/opsx:apply` — implementar tasks
3. `/opsx:archive` — arquivar change concluída

Specs de capabilities: `openspec/specs/<capability>/spec.md`

## Capabilities → código

| Capability (OpenSpec) | Componente principal |
|----------------------|----------------------|
| `mqtt-messaging`, `batch-test-execution`, `offline-resilience`, `system-robustness`, `wifi-provisioning`, `device-telemetry`, `ota-update`, `calibration-mode`, `hardware-monitoring` | `sirene-validator/` |
| `mqtt-client`, `flutter-app-shell`, `batch-operator-ui`, `device-monitoring`, `label-printing`, `production-dashboard`, `serial-counter`, `firestore-sync`, `firebase-auth`, `product-catalog`, `catalog-cloud-pull`, `operator-traceability`, `ota-campaign`, `op-lock`, `calibration-history`, `desktop-ui-layout`, `wifi-provisioning-wizard`, `serial-and-labels`, `serial-traceability`, `calibration-and-ota` | `sirene_app/` |
| `firebase-setup` | `firebase/`, `scripts/setup_firebase.sh` |

## CI e branch protection

O workflow `.github/workflows/ci.yml` roda em push/PR para `main`. Jobs manuais (**workflow_dispatch**): build IDF completo e **Windows portable release** (ZIP do app para pendrive).

Recomenda-se habilitar branch protection em `main` exigindo os checks `Flutter tests` e `Firmware host tests` antes do merge.
