#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Erro: o build Windows (.exe) nao pode ser gerado no Linux.

O Flutter nao faz cross-compile para Windows a partir deste ambiente.

Opcoes:
  1. Em um PC Windows com Flutter + Visual Studio C++:
       powershell -ExecutionPolicy Bypass -File scripts/build_windows_release.ps1

  2. Pelo GitHub Actions (sem maquina Windows local):
       GitHub → Actions → CI → Run workflow → job "Windows portable release"
       Baixe o artifact DipontoSireneValidator-win64.zip

Documentacao: sirene_app/README.md e docs/PRODUCAO.md
EOF

exit 1
