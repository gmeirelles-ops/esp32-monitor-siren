## 1. Banco de dados

- [x] 1.1 Tabela `CalibrationHistory` (idProduto, potenciaRef, deviceId, createdAt)
- [x] 1.2 Tabela `OpLocks` (numeroOp PK, status, lockedAt)
- [x] 1.3 Migração schema v6 → v7 + regen build_runner
- [x] 1.4 Métodos: `insertCalibration`, `getCalibrationHistory`, `lockOp`, `isOpLocked`, `recentHardwareEvents`

## 2. OTA campaign

- [x] 2.1 `DevicesNotifier.sendOtaCampaign(deviceIds, url)`
- [x] 2.2 Multi-seleção de dispositivos + envio em `admin_screen.dart`

## 3. Trava de OP

- [x] 3.1 `lockOp` ao `sendEndBatch`
- [x] 3.2 Checar `isOpLocked` antes do `SET_BATCH` no fluxo de lote + mensagem

## 4. Histórico de calibração

- [x] 4.1 Registrar calibração no `_save` do produto quando houver nova calibração
- [x] 4.2 Exibir histórico no formulário ao editar

## 5. Alertas in-app

- [x] 5.1 Card "Alertas recentes" no `dashboard_screen.dart` (vazio quando não há)

## 6. Testes e validação

- [x] 6.1 Teste unitário: `lockOp`/`isOpLocked`
- [x] 6.2 Teste unitário: `insertCalibration`/`getCalibrationHistory` (ordem desc)
- [x] 6.3 Teste unitário: `recentHardwareEvents` (limite/ordem)
- [x] 6.4 `flutter analyze` e `flutter test` passando
