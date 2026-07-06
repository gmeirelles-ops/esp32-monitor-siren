@echo off
setlocal
cd /d "%~dp0"
echo Exportar catálogo e config deste PC para dados_posto\
echo (feche o app antes, se estiver aberto)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0exportar_posto_usb.ps1" %*
echo.
pause
