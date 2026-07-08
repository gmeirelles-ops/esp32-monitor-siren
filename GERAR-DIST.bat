@echo off
setlocal
cd /d "%~dp0"
echo.
echo Gerando instalador setup.exe (Diponto Sirene Validator)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\gerar_dist.ps1" -ApenasInstalador %*
set ERR=%ERRORLEVEL%
echo.
if %ERR% NEQ 0 (
  echo Falhou com codigo %ERR%.
  pause
  exit /b %ERR%
)
echo Concluido. Instalador em dist\
pause
