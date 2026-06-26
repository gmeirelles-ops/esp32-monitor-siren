# Ferramentas Windows — gravação USB

## esptool.exe

O app tenta, nesta ordem:

1. `tools/windows/esptool.exe` (empacotado com o instalador)
2. `python -m esptool`
3. `py -m esptool`

### Gerar esptool.exe

No Windows com Python:

```powershell
powershell -ExecutionPolicy Bypass -File ..\..\scripts\bundle_esptool_windows.ps1
```

Ou instale globalmente: `pip install esptool`

## Layout de flash (ESP32 4 MB)

Ver `flash_manifest.json`. Modo **Atualizar app** grava só `sirene-validator.bin` em `0x20000`.
