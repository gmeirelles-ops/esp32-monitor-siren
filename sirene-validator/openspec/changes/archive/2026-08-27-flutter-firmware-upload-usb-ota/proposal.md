## Why

Atualizar o ESP32 hoje exige passos manuais frágeis:

1. Compilar e copiar `sirene-validator.bin` para o PC
2. Subir `python -m http.server` (muitas máquinas sem Python/`py`)
3. Montar URL manualmente e publicar no MQTT Explorer

O app Flutter **já envia** `OTA_UPDATE` (`AdminScreen`), mas ainda depende de URL digitada e servidor externo. Na bancada com cabo USB, o operador usa `idf.py flash` fora do app.

Objetivo: **um fluxo no app** para OTA (rede) e **outro por USB** (cabo), sem MQTT Explorer nem terminal.

## What Changes

### App Flutter (`sirene_app`)

- Nova tela **Atualizar firmware** (Configurações → Administração ou detalhe da bancada)
- **Modo OTA (rede):**
  - Selecionar `.bin` (`file_selector`, já no projeto)
  - Servidor HTTP embutido (`shelf` + `shelf_io`) na porta configurável
  - Detectar IP LAN do PC automaticamente
  - Publicar `OTA_UPDATE` via `MqttService.publishCommand` (já existe)
  - Barra de progresso / status via `otaStreamProvider` + `firmware_version` no heartbeat
- **Modo USB (cabo):**
  - Listar portas COM (`flutter_libserialport` ou equivalente Windows)
  - Selecionar `.bin` e modo: *só app* (OTA partition) ou *flash completo* (primeira vez)
  - Executar `esptool` empacotado em `tools/windows/esptool.exe` (sem depender de Python no PC)
  - Log em tempo real na UI
- Refatorar `AdminScreen` para usar o novo fluxo (deprecar campo URL manual como caminho principal)

### Firmware ESP32

- **Sem alteração obrigatória** — `OTA_UPDATE` e partições OTA já existem
- Documentar offsets de flash para o modo USB no app

### Repositório

- Script de empacotamento `scripts/bundle_esptool_windows.ps1`
- Atualizar `docs/GUIA_COMPLETO.md` seção app + OTA
- Testes unitários: montagem de URL OTA, offsets de flash, parsing de log esptool

## Explicitly Out of Scope

- OTA enviando binário **dentro** do payload MQTT (sem HTTP)
- App mobile Android/iOS para flash USB (apenas **Windows desktop** na v1)
- Download automático de firmware da nuvem (Firebase/CDN) — fase futura
- Assinatura criptográfica do `.bin` (aceito LAN industrial)

## Capabilities

### New Capabilities

- `flutter-ota-assist`: Servidor HTTP embutido + OTA MQTT one-click
- `flutter-usb-flash`: Gravação por USB com esptool empacotado
- `firmware-update-ui`: Tela unificada OTA/USB com progresso e validações

### Modified Capabilities

- `ota-operational-guide`: Fluxo principal passa a ser o app Flutter, não MQTT Explorer

## Impact

| Área | Impacto |
|------|---------|
| `sirene_app/lib/features/firmware/` | Novo módulo (serviço OTA, flash USB, tela) |
| `sirene_app/lib/features/admin/` | Integração ou redirecionamento |
| `sirene_app/pubspec.yaml` | `shelf`, `shelf_io`, `flutter_libserialport` |
| `sirene_app/tools/windows/` | `esptool.exe` + manifest de offsets |
| `sirene-validator/docs/` | Guia operacional atualizado |
| Firmware ESP32 | Nenhuma mudança de contrato MQTT |
