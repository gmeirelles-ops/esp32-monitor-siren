#Requires -Version 5.1
<#
.SYNOPSIS
  Gera ZIP portátil + instalador setup.exe atualizados em dist/.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\gerar_instalador_atualizado.ps1
#>
$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot "build_windows_all.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

. (Join-Path $PSScriptRoot "windows_build_common.ps1")
$version = Get-SireneAppVersion
$dist = Join-Path $root "dist"
$setup = Join-Path $dist "DipontoSireneValidator-$version-setup.exe"
$readme = Join-Path $dist "LEIA-ME-INSTALACAO.txt"

if (Test-Path $setup) {
    $readmeTemplate = @"
Diponto Sirene Validator — instalar em outro PC
================================================

Arquivo do instalador: DipontoSireneValidator-$version-setup.exe
Versão do app: $version

PASSO A PASSO
-------------
1. Copie DipontoSireneValidator-$version-setup.exe para o PC do posto.
2. Duplo clique no setup.exe.
3. Se o Windows avisar: Mais informações → Executar assim mesmo.
4. Abra pelo menu Iniciar.

CONFIGURAÇÃO: Configurações → MQTT e impressora → Cadastros → Lote.

Dados locais ficam no perfil do Windows; outro PC começa sem histórico.
"@
    $readmeTemplate | Set-Content $readme -Encoding UTF8
    Write-Host ""
    Write-Host "Envie para o outro PC:"
    Write-Host "  $setup"
    Write-Host "  $readme"
}
