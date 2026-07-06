# Diagnóstico rápido — sirene_app fecha ao abrir (0xc000001d ou similar)
# Uso no PC do posto (PowerShell):
#   powershell -ExecutionPolicy Bypass -File Diagnostico-Posto.ps1

$ErrorActionPreference = "Continue"

Write-Host "=== Diponto Sirene Validator — diagnóstico ===" -ForegroundColor Cyan
Write-Host ""

# CPU
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Host "Processador: $($cpu.Name)"
Write-Host "Arquitetura: $($cpu.AddressWidth) bits"
Write-Host ""

# Windows
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "Windows: $($os.Caption) ($($os.OSArchitecture))"
Write-Host ""

# Pastas comuns
$candidates = @(
    "${env:ProgramFiles}\Diponto\Sirene Validator",
    "${env:ProgramFiles(x86)}\Diponto\Sirene Validator",
    "$PSScriptRoot\app",
    (Join-Path $PSScriptRoot "..\app")
)

$appDir = $null
foreach ($dir in $candidates) {
    if (Test-Path (Join-Path $dir "sirene_app.exe")) {
        $appDir = (Resolve-Path $dir).Path
        break
    }
}

if (-not $appDir) {
    Write-Host "ERRO: sirene_app.exe nao encontrado." -ForegroundColor Red
    Write-Host "Procure manualmente ou reinstale o setup.exe"
    exit 1
}

Write-Host "Pasta do app: $appDir" -ForegroundColor Green
Write-Host ""

$required = @(
    "sirene_app.exe",
    "flutter_windows.dll",
    "sqlite3.dll",
    "data\app.so",
    "data\icudtl.dat",
    "data\flutter_assets\AssetManifest.bin"
)

$ok = $true
foreach ($rel in $required) {
    $path = Join-Path $appDir $rel
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        Write-Host "  OK  $rel ($size bytes)"
    } else {
        Write-Host "  FALTA  $rel" -ForegroundColor Red
        $ok = $false
    }
}
Write-Host ""

# VC++ 2015-2022 x64 (chaves comuns)
$vcKeys = @(
    "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
)
$vcOk = $false
foreach ($key in $vcKeys) {
    if (Test-Path $key) {
        $installed = (Get-ItemProperty $key -ErrorAction SilentlyContinue).Installed
        if ($installed -eq 1) { $vcOk = $true }
    }
}
if ($vcOk) {
    Write-Host "Visual C++ Redistributable x64: instalado" -ForegroundColor Green
} else {
    Write-Host "Visual C++ Redistributable x64: NAO detectado" -ForegroundColor Yellow
    Write-Host "  Instale: https://aka.ms/vs/17/release/vc_redist.x64.exe"
}
Write-Host ""

if (-not $ok) {
    Write-Host "Instalacao INCOMPLETA. Desinstale e reinstale o setup.exe inteiro." -ForegroundColor Red
    exit 2
}

Write-Host "Tentando iniciar o app por 5 segundos (observe se a janela abre)..." -ForegroundColor Cyan
$exe = Join-Path $appDir "sirene_app.exe"
Push-Location $appDir
try {
    $proc = Start-Process -FilePath $exe -WorkingDirectory $appDir -PassThru
    Start-Sleep -Seconds 5
    if ($proc.HasExited) {
        Write-Host "O app FECHOU sozinho (codigo de saida: $($proc.ExitCode))." -ForegroundColor Red
        Write-Host "Veja o Visualizador de Eventos > Aplicativo > sirene_app.exe"
        Write-Host ""
        Write-Host "Proximos passos:"
        Write-Host "  1. Reinstalar com setup.exe copiado de novo (USB)"
        Write-Host "  2. Instalar VC++ x64 (link acima)"
        Write-Host "  3. Excluir a pasta do app no antivirus"
        Write-Host "  4. Testar ZIP portatil em C:\Diponto\Sirene (fora de Program Files)"
    } else {
        Write-Host "O app parece estar rodando (PID $($proc.Id)). Feche a janela manualmente." -ForegroundColor Green
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
} finally {
    Pop-Location
}
