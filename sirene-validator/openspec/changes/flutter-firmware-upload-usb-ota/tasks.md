## 1. Dependências e tooling



- [x] 1.1 Adicionar `shelf`, `shelf_io` ao `pubspec.yaml`

- [x] 1.2 Adicionar `flutter_libserialport` para listagem COM (Windows)

- [x] 1.3 Criar `scripts/bundle_esptool_windows.ps1` e documentar obtenção de `esptool.exe`

- [x] 1.4 Adicionar `tools/windows/esptool.exe` (ou placeholder + instrução de build) e manifest de offsets



## 2. Serviço OTA assistido



- [x] 2.1 Criar `OtaAssistService`: cópia temp do `.bin`, servidor shelf, detecção IP LAN

- [x] 2.2 Validar porta livre e HTTP 200 local antes de publicar MQTT

- [x] 2.3 Integrar com `sendOtaUpdate` / `sendOtaCampaign` existentes

- [x] 2.4 Monitorar `otaStreamProvider` + heartbeat até confirmar `firmware_version`

- [x] 2.5 Testes unitários: montagem de URL, validação de estado device



## 3. Serviço flash USB



- [x] 3.1 Criar `UsbFlashService`: listar COM, executar esptool com offsets

- [x] 3.2 Modo "Atualizar app" (`0x20000`) e modo "Flash completo" (4 arquivos)

- [x] 3.3 Stream de log stdout/stderr para UI; cancelamento

- [x] 3.4 Testes unitários: argumentos esptool, parsing de sucesso/erro



## 4. UI — FirmwareUpdateScreen



- [x] 4.1 Criar `lib/features/firmware/firmware_update_screen.dart` com abas OTA / USB

- [x] 4.2 `file_selector` para escolher `.bin` (e diretório build no modo completo)

- [x] 4.3 Estados visuais: idle, preparing, uploading, success, failed

- [x] 4.4 Link em Configurações → Administração e botão no `DeviceDetailScreen`

- [x] 4.5 Refatorar `AdminScreen` para usar OTA assistido (URL manual em seção avançada)



## 5. Documentação



- [x] 5.1 Atualizar `docs/GUIA_COMPLETO.md` — fluxo app OTA + USB

- [x] 5.2 Atualizar `sirene_app/README.md` com pré-requisitos (driver USB, firewall)

- [x] 5.3 Atualizar spec principal `openspec/specs/ota-operational-guide/spec.md` após implementação



## 6. Validação



- [x] 6.1 Testes unitários Flutter (`test/firmware_*_logic_test.dart`)

- [ ] 6.2 OTA pelo app: device atualiza sem Python/MQTT Explorer

- [ ] 6.3 USB pelo app: gravação @ `0x20000` em bancada Windows

- [x] 6.4 `flutter analyze` sem erros nos arquivos novos (apenas infos de deprecação; 0 errors)

