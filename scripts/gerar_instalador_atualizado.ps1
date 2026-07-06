#Requires -Version 5.1
<#
.SYNOPSIS
  Gera ZIP portatil + instalador setup.exe atualizados em dist/.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\gerar_instalador_atualizado.ps1
#>
$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "gerar_dist.ps1") @args
exit $LASTEXITCODE
