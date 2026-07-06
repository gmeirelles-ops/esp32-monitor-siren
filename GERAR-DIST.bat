@echo off
setlocal
cd /d "%~dp0"
echo.
echo Gerando dist do Diponto Sirene Validator...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\gerar_dist.ps1" %*
set ERR=%ERRORLEVEL%
echo.
if %ERR% NEQ 0 (
  echo Falhou com codigo %ERR%.
  pause
  exit /b %ERR%
)
echo Concluido. Arquivos em dist\
pause
