@echo off
REM Compila sirene-validator e grava via USB (app 0x20000). Porta padrao COM11.
REM Uso: BUILD-E-GRAVAR-FIRMWARE.bat [COM11]
setlocal
set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM11"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sirene-validator\scripts\build_and_flash_windows.ps1" -ComPort %PORT%
exit /b %ERRORLEVEL%
