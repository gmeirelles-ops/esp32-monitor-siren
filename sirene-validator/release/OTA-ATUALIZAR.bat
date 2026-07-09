@echo off
REM Atualiza firmware via OTA (serve .bin + MQTT). Edite BANCADA abaixo.
set BANCADA=1
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\ota_update_windows.ps1" -Bancada %BANCADA%
pause
