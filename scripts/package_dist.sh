#!/usr/bin/env bash
# Empacota dist/ a partir de sirene_app/build/.../Release ou de pacote app/ existente.
# Roda no Linux (devcontainer) quando nao ha PowerShell/Inno Setup.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/sirene_app"
DIST="$ROOT/dist"
TEMPLATES="$ROOT/scripts/windows-portable"
VERSION="$(grep -E '^\s*version:' "$APP_DIR/pubspec.yaml" | head -1 | sed -E 's/.*version:\s*([0-9.]+).*/\1/')"
PACKAGE="DipontoSireneValidator-${VERSION}-win64"
RELEASE="$APP_DIR/build/windows/x64/runner/Release"
SOURCE_APP=""

if [[ -d "$RELEASE" && -f "$RELEASE/sirene_app.exe" ]]; then
  SOURCE_APP="$RELEASE"
  echo "==> Usando build Release: $SOURCE_APP"
elif [[ -f "$DIST/DipontoSireneValidator-1.0.0-win64/app/sirene_app.exe" ]]; then
  SOURCE_APP="$DIST/DipontoSireneValidator-1.0.0-win64/app"
  echo "==> AVISO: sem build Windows novo; reempacotando binario existente (1.0.0)"
  echo "    Para build atualizado, rode no Windows: scripts/rebuild_windows_clean.ps1"
else
  echo "ERRO: nenhum sirene_app.exe encontrado."
  echo "  Esperado: $RELEASE/sirene_app.exe"
  exit 1
fi

PKG_DIR="$DIST/$PACKAGE"
APP_DEST="$PKG_DIR/app"
rm -rf "$PKG_DIR"
mkdir -p "$APP_DEST" "$DIST"

echo "==> Copiando para $PKG_DIR/app"
cp -a "$SOURCE_APP/." "$APP_DEST/"

TOOLS_SRC="$APP_DIR/tools/windows"
if [[ -d "$TOOLS_SRC" ]]; then
  mkdir -p "$APP_DEST/tools/windows"
  cp -a "$TOOLS_SRC/." "$APP_DEST/tools/windows/"
fi

sed "s/{{VERSION}}/$VERSION/g" "$TEMPLATES/LEIA-ME.txt" > "$PKG_DIR/LEIA-ME.txt"
cp "$TEMPLATES/Iniciar Diponto Sirene Validator.bat" "$PKG_DIR/"

ZIP="$DIST/${PACKAGE}.zip"
rm -f "$ZIP"
echo "==> Gerando $ZIP"
(cd "$DIST" && zip -r -q "$(basename "$ZIP")" "$(basename "$PKG_DIR")")

echo ""
echo "Pronto!"
echo "  Pasta: $PKG_DIR"
echo "  ZIP:   $ZIP"
if [[ ! -f "$RELEASE/sirene_app.exe" ]]; then
  echo ""
  echo "NOTA: ZIP gerado com binario de jun/2025 (1.0.0). Instalador .exe requer Windows + Inno Setup."
fi
