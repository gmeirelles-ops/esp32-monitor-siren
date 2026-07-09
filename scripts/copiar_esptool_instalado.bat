@echo off
REM Copia esptool.exe para a instalacao em Program Files (requer "Executar como administrador").
setlocal
set "SRC=%~dp0..\sirene_app\tools\windows\esptool.exe"
set "DEST=%ProgramFiles%\Diponto\Sirene Validator\tools\windows"

if not exist "%SRC%" (
  echo ERRO: esptool nao encontrado em:
  echo   %SRC%
  echo Execute antes: sirene_app\scripts\bundle_esptool_windows.ps1
  exit /b 1
)

mkdir "%DEST%" 2>nul
copy /Y "%SRC%" "%DEST%\esptool.exe"
if errorlevel 1 (
  echo ERRO: falha ao copiar. Clique com botao direito neste .bat e escolha "Executar como administrador".
  exit /b 1
)

echo OK: %DEST%\esptool.exe
"%DEST%\esptool.exe" version
exit /b 0
