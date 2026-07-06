@echo off
setlocal
cd /d "%~dp0"
if not exist "app\sirene_app.exe" (
  echo Erro: app\sirene_app.exe nao encontrado.
  echo Extraia o ZIP completo e mantenha a pasta app\ junto deste arquivo.
  pause
  exit /b 1
)

REM Arquivos copiados da internet/USB podem ficar bloqueados pelo Windows.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-ChildItem -LiteralPath '%~dp0app' -Recurse -File | Unblock-File -ErrorAction SilentlyContinue"

cd /d "%~dp0app"
start /wait "" "%~dp0app\sirene_app.exe"
if errorlevel 1 (
  echo.
  echo O app fechou com erro ^(codigo %errorlevel%^).
  echo Rode Diagnostico-Posto.ps1 nesta pasta ou veja Documentos\sirene_app.log
  pause
  exit /b 1
)
