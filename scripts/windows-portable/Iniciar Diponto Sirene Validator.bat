@echo off
setlocal
cd /d "%~dp0"
if not exist "app\sirene_app.exe" (
  echo Erro: app\sirene_app.exe nao encontrado.
  echo Extraia o ZIP completo e mantenha a pasta app\ junto deste arquivo.
  pause
  exit /b 1
)
start "" "%~dp0app\sirene_app.exe"
