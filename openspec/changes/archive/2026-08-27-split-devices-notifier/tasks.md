## 1. Extração

- [x] 1.1 Extrair pipeline de teste + marking (`processTestResult`, `_enqueueMarking`, auto helpers)
- [x] 1.2 Extrair comandos de lote (set/end/auto-end/reteste/demo batch)
- [x] 1.3 Extrair handlers inbound (message switch, heartbeat, watchdog, rejeições)
- [x] 1.4 Extrair comandos auxiliares (calibração, ensaio, OTA, RESET_WIFI)
- [x] 1.5 Deixar `mqtt_providers.dart` como fachada (providers + notifier fino)

## 2. Verificação

- [x] 2.1 `dart analyze` limpo nos arquivos tocados
- [x] 2.2 `flutter test` verde
- [x] 2.3 Confirmar que nenhum import de tela quebrou
