## 1. Firmware — recuperação e TWDT

- [x] 1.1 Publicar `{"tipo":"hardware","evento":"recuperado"}` em `alerta` ao sair de `HARDWARE_FAULT` em `hardware_monitor_task`
- [x] 1.2 Registrar `hw_mon` no TWDT (`esp_task_wdt_add`) e resetar a cada iteração do loop
- [ ] 1.3 Validar no monitor serial: falha PZEM → recuperação → mensagem de alerta publicada

## 2. App — stale heartbeat

- [x] 2.1 Adicionar constante `kStaleDeviceTimeout` (90 s) em `app_config.dart` ou constants
- [x] 2.2 Criar timer periódico em `DevicesNotifier` que marca offline dispositivos com `lastSeen` expirado
- [x] 2.3 Teste unitário: dispositivo online há >90 s sem mensagem → `isOnline == false`

## 3. App — alertas de hardware

- [x] 3.1 Limpar `lastHardwareAlert` quando heartbeat reportar FSM ≠ `HARDWARE_FAULT`
- [x] 3.2 Parsear `evento: "recuperado"` em `MqttParser.parseHardwareAlert`
- [x] 3.3 Atualizar `device_detail_screen.dart` para refletir estado sem alerta após recuperação

## 4. App — rejeições MQTT

- [x] 4.1 Substituir handler vazio de `rejections.listen` por snackbar com motivo
- [x] 4.2 Armazenar `lastRejection` em `DeviceInfo` para exibição no detalhe
- [x] 4.3 Exibir snackbar na tela de lote ao receber rejeição durante `SET_BATCH`/`END_BATCH`
- [x] 4.4 Teste unitário: parse de rejeição + verificação de motivo extraído

## 5. Specs — Purpose

- [x] 5.1 Atualizar `Purpose` em `openspec/specs/device-monitoring/spec.md`
- [x] 5.2 Atualizar `Purpose` em `openspec/specs/hardware-monitoring/spec.md`

## 6. Validação

- [x] 6.1 `flutter analyze` e `flutter test` passando
- [ ] 6.2 Compilar firmware e validar TWDT sem timeout em `hw_mon` sob MQTT offline
- [ ] 6.3 Bancada: SET_BATCH durante TESTING → operador vê snackbar de rejeição
- [ ] 6.4 Bancada: simular recuperação PZEM → alerta some no app
