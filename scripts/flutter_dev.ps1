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
  powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 dist
  powershell -ExecutionPolicy Bypass -File scripts\flutter_dev.ps1 dist-only
#>
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_build_common.ps1")

$RepoRoot = Ensure-WindowsAsciiRepoPath
$AppOnDrive = Join-Path $RepoRoot "sirene_app"

if ($PSVersionTable.PSPlatform -and $PSVersionTable.PSPlatform -ne "Win32NT") {
    throw "Use este script no Windows."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao encontrado no PATH."
}

if ($args.Count -eq 0) {
    Write-Host "Uso: flutter_dev.ps1 <comando> [args...]"
    Write-Host "Ex.: flutter_dev.ps1 run -d windows"
    Write-Host "     flutter_dev.ps1 dist          # build release + atualiza dist/"
    Write-Host "     flutter_dev.ps1 dist-only     # so empacota Release/ em dist/"
    exit 1
}

$cmd = $args[0]
if ($cmd -eq "dist") {
    & (Join-Path $PSScriptRoot "build_windows_release.ps1")
    exit $LASTEXITCODE
}
if ($cmd -eq "dist-only") {
    & (Join-Path $PSScriptRoot "sync_dist.ps1")
    exit $LASTEXITCODE
}

Push-Location $AppOnDrive
try {
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
