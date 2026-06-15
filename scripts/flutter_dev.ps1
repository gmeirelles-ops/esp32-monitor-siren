#Requires -Version 5.1
<#
.SYNOPSIS
  Executa comandos Flutter a partir de um caminho ASCII (subst S:).

  O projeto em OneDrive\Area de Trabalho (com acento) quebra dart/build_runner
  e flutter build windows no Windows. Este script mapeia S: e roda o comando
  em S:\sirene_app.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 run -d windows
  powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 test
  powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 build windows --release
#>
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Drive = "S:"
$AppOnDrive = Join-Path $Drive "sirene_app"

function Ensure-SubstDrive {
    $existing = subst 2>&1 | Select-String "^$([regex]::Escape($Drive))\:"
    if (-not $existing) {
        Write-Host "==> Mapeando $Drive -> $RepoRoot"
        subst $Drive $RepoRoot
    }
}

if ($PSVersionTable.PSPlatform -and $PSVersionTable.PSPlatform -ne "Win32NT") {
    throw "Use este script no Windows."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao encontrado no PATH."
}

Ensure-SubstDrive

if ($args.Count -eq 0) {
    Write-Host "Uso: flutter_dev.ps1 <comando flutter/dart> [args...]"
    Write-Host "Ex.: flutter_dev.ps1 run -d windows"
    exit 1
}

Push-Location $AppOnDrive
try {
    $cmd = $args[0]
    $rest = @()
    if ($args.Count -gt 1) {
        $rest = $args[1..($args.Count - 1)]
    }

    switch ($cmd) {
        "pub" { & dart pub @rest; exit $LASTEXITCODE }
        "run" {
            if ($rest.Count -gt 0 -and $rest[0] -eq "build_runner") {
                & dart run @rest
            }
            else {
                & flutter run @rest
            }
            exit $LASTEXITCODE
        }
        "build_runner" { & dart run build_runner @rest; exit $LASTEXITCODE }
        default { & flutter @args; exit $LASTEXITCODE }
    }
}
finally {
    Pop-Location
}
