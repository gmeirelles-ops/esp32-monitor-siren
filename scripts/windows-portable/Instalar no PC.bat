@echo off
setlocal
cd /d "%~dp0"
echo Diponto Sirene - instalar do pendrive no PC do posto
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar_posto_do_usb.ps1"
echo.
pause
