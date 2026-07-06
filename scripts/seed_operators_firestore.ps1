#Requires -Version 5.1
<#
.SYNOPSIS
  Publica regras Firestore (coleção operators) e cadastra operadores padrão.

.EXAMPLE
  firebase login --reauth
  powershell -ExecutionPolicy Bypass -File scripts\seed_operators_firestore.ps1
#>
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    throw "Firebase CLI não encontrado. Instale: npm install -g firebase-tools"
}

Write-Host "==> Publicando regras Firestore (operators + products)"
Push-Location $Root
try {
    firebase deploy --only firestore:rules
    if ($LASTEXITCODE -ne 0) { throw "firebase deploy falhou (rode: firebase login --reauth)" }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "==> Cadastrando operadores na coleção operators"
Push-Location (Join-Path $Root "firebase\seed")
try {
    if (-not (Test-Path "node_modules")) {
        npm install --silent
    }
    node seed_operators.mjs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Pronto. No app: Configurações > sync ligado > Baixar catálogo da nuvem."
