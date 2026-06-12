## 1. Firmware — módulo mqtt_config

- [x] 1.1 Criar `components/mqtt_config/` com `mqtt_config_get_uri()`, `mqtt_config_load/save()` usando NVS namespace `mqtt_cfg`
- [x] 1.2 Adicionar constantes `MQTT_NVS_NAMESPACE`, `MQTT_NVS_HOST_KEY`, `MQTT_NVS_PORT_KEY` em `board_config.h`
- [x] 1.3 Implementar fallback para `MQTT_BROKER_URI` quando NVS vazia
- [x] 1.4 Registrar componente no CMakeLists e expor header `mqtt_config.h`

## 2. Firmware — integração mqtt_bridge

- [x] 2.1 Alterar `mqtt_bridge_init()` para chamar `mqtt_config_get_uri()` em vez de usar `MQTT_BROKER_URI` diretamente
- [x] 2.2 Validar reconexão após boot com broker da NVS
- [x] 2.3 Bump `FIRMWARE_VERSION` para 1.3.0

## 3. Firmware — portal de provisionamento

- [x] 3.1 Estender HTML do captive portal com campos `mqtt_host` e `mqtt_port` (opcionais)
- [x] 3.2 Parsear e validar host/porta no handler POST do portal
- [x] 3.3 Persistir `mqtt_cfg` junto com credenciais Wi-Fi antes do reboot
- [x] 3.4 Exibir valores atuais de broker no portal quando re-provisionando (se existirem)

## 4. Documentação e operação

- [x] 4.1 Alinhar `docs/PRODUCAO.md`, `GUIA_COMPLETO.md` e `app_config.dart` com instruções de broker via portal
- [x] 4.2 Documentar namespace NVS `mqtt_cfg` e fluxo de re-provisionamento
- [x] 4.3 Atualizar seção de provisionamento Wi-Fi no guia com screenshot/descrição dos novos campos

## 5. Validação

- [x] 5.1 Compilar firmware (`idf.py build`)
- [ ] 5.2 Smoke test: provisionar com broker customizado → confirmar conexão MQTT nos logs
- [ ] 5.3 Smoke test: provisionar sem broker → confirmar fallback de `board_config.h`
- [x] 5.4 Executar `./scripts/run_host_tests.sh` (sem regressão)
