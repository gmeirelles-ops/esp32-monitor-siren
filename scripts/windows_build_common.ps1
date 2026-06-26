#Requires -Version 5.1
# Funções compartilhadas para build Windows (portátil e instalador).

$script:SubstDrive = "S:"
$script:RepoRootCache = $null

function Ensure-WindowsAsciiRepoPath {
    if ($script:RepoRootCache) {
        return $script:RepoRootCache
    }

    $physicalRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    if ($PSVersionTable.PSPlatform -and $PSVersionTable.PSPlatform -ne "Win32NT") {
        $script:RepoRootCache = $physicalRoot
        return $script:RepoRootCache
    }

    $drive = $script:SubstDrive
    $existing = subst 2>&1 | Select-String "^$([regex]::Escape($drive))\:"
    if (-not $existing) {
        Write-Host "==> Mapeando $drive -> $physicalRoot (evita falha com acentos no caminho)"
        subst $drive $physicalRoot | Out-Null
    }

    $script:RepoRootCache = Join-Path $drive ""
    return $script:RepoRootCache
}

function Assert-WindowsBuildEnvironment {
    if ($PSVersionTable.PSPlatform -and $PSVersionTable.PSPlatform -ne "Win32NT") {
        throw "Este script deve ser executado no Windows. Use GitHub Actions (workflow_dispatch) ou uma maquina Windows."
    }

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Flutter nao encontrado no PATH. Instale o Flutter SDK e o workload C++ do Visual Studio."
    }

    Ensure-WindowsAsciiRepoPath | Out-Null
}

function Get-RepoRoot {
    if (-not $script:RepoRootCache) {
        Ensure-WindowsAsciiRepoPath | Out-Null
    }
    return $script:RepoRootCache
}

function Get-SireneAppDir {
    return (Join-Path (Get-RepoRoot) "sirene_app")
}

function Get-SireneReleaseDir {
    return (Join-Path (Get-SireneAppDir) "build\windows\x64\runner\Release")
}

function Get-SireneAppVersion {
    $pubspecPath = Join-Path (Get-SireneAppDir) "pubspec.yaml"
    $line = Get-Content $pubspecPath | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
    if ($line -match 'version:\s*([\d.]+)') {
        return $Matches[1]
    }
    throw "Nao foi possivel ler version de pubspec.yaml"
}

function Invoke-ExternalBuildStep {
    param(
        [string]$Label,
        [scriptblock]$Command,
        [string]$FailureMessage
    )

    Write-Host "==> $Label"
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            throw $FailureMessage
        }
    }
    finally {
        $ErrorActionPreference = $prevErrorAction
    }
}

function Invoke-SireneFlutterWindowsBuild {
    $appDir = Get-SireneAppDir
    $releaseDir = Get-SireneReleaseDir

    Push-Location $appDir
    try {
        Invoke-ExternalBuildStep "flutter pub get" { flutter pub get } "flutter pub get falhou"
        Invoke-ExternalBuildStep "dart run build_runner build" { dart run build_runner build --delete-conflicting-outputs } "build_runner falhou"
        Invoke-ExternalBuildStep "flutter build windows --release" { flutter build windows --release } "flutter build windows falhou"
    }
    finally {
        Pop-Location
    }

    if (-not (Test-Path $releaseDir)) {
        throw "Saida de build nao encontrada: $releaseDir"
    }
}

function Copy-SireneBundledTools {
    param([string]$AppDestDir)

    $toolsSrc = Join-Path (Get-SireneAppDir) "tools\windows"
    if (-not (Test-Path $toolsSrc)) {
        Write-Host "    (sem tools/windows para copiar)"
        return
    }

    $toolsDest = Join-Path $AppDestDir "tools\windows"
    New-Item -ItemType Directory -Path $toolsDest -Force | Out-Null
    Copy-Item -Path (Join-Path $toolsSrc "*") -Destination $toolsDest -Recurse -Force
    Write-Host "==> Copiando tools/windows (esptool, manifest)"
}

function Test-SirenePortableLayout {
    param([string]$PackageDir)

    $exe = Join-Path $PackageDir "app\sirene_app.exe"
    $data = Join-Path $PackageDir "app\data"
    $readme = Join-Path $PackageDir "LEIA-ME.txt"
    $launcher = Join-Path $PackageDir "Iniciar Diponto Sirene Validator.bat"

    foreach ($path in @($exe, $data, $readme, $launcher)) {
        if (-not (Test-Path $path)) {
            throw "Pacote incompleto: ausente $path"
        }
    }
}

function Invoke-SirenePortablePackage {
    param(
        [switch]$SkipZip
    )

    $distRoot = Join-Path (Get-RepoRoot) "dist"
    $templatesDir = Join-Path $PSScriptRoot "windows-portable"
    $version = Get-SireneAppVersion
    $packageName = "DipontoSireneValidator-$version-win64"
    $packageDir = Join-Path $distRoot $packageName
    $zipPath = Join-Path $distRoot "$packageName.zip"
    $releaseDir = Get-SireneReleaseDir

    if (-not (Test-Path $releaseDir)) {
        throw "Saida de build nao encontrada: $releaseDir`nExecute antes: flutter build windows --release"
    }

    New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

    if (Test-Path $packageDir) {
        Remove-Item $packageDir -Recurse -Force
    }
    $appDest = Join-Path $packageDir "app"
    New-Item -ItemType Directory -Path $appDest -Force | Out-Null

    Write-Host "==> Copiando Release para dist/$packageName/app"
    Copy-Item -Path (Join-Path $releaseDir "*") -Destination $appDest -Recurse -Force
    Copy-SireneBundledTools -AppDestDir $appDest

    $readmeTemplate = Get-Content (Join-Path $templatesDir "LEIA-ME.txt") -Raw -Encoding UTF8
    $readmeTemplate.Replace("{{VERSION}}", $version) | Set-Content (Join-Path $packageDir "LEIA-ME.txt") -Encoding UTF8
    Copy-Item (Join-Path $templatesDir "Iniciar Diponto Sirene Validator.bat") $packageDir -Force

    Write-Host "==> Verificando estrutura do pacote"
    Test-SirenePortableLayout -PackageDir $packageDir

    if (-not $SkipZip) {
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        Write-Host "==> Gerando ZIP"
        Compress-Archive -Path $packageDir -DestinationPath $zipPath -Force
    }

    return [PSCustomObject]@{
        Version    = $version
        PackageDir = $packageDir
        ZipPath    = $(if ($SkipZip) { $null } else { $zipPath })
    }
}

function Compile-SireneWindowsInstaller {
    param([string]$Version)

    $distRoot = Join-Path (Get-RepoRoot) "dist"
    $issPath = Join-Path $PSScriptRoot "windows-installer\DipontoSireneValidator.iss"
    $iconPath = Join-Path (Get-SireneAppDir) "windows\runner\resources\app_icon.ico"
    $releaseDir = Get-SireneReleaseDir
    $setupPath = Join-Path $distRoot "DipontoSireneValidator-$Version-setup.exe"
    $readmeTemplate = Join-Path $PSScriptRoot "windows-portable\LEIA-ME.txt"
    $readmeInstall = Join-Path $PSScriptRoot "windows-installer\LEIA-ME.install.txt"

    if (-not (Test-Path $issPath)) {
        throw "Script Inno Setup nao encontrado: $issPath"
    }
    if (-not (Test-Path $iconPath)) {
        throw "Icone do app nao encontrado: $iconPath"
    }
    if (-not (Test-Path $releaseDir)) {
        throw "Saida de build nao encontrada: $releaseDir"
    }

    New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

    $readmeContent = Get-Content $readmeTemplate -Raw -Encoding UTF8
    $readmeContent.Replace("{{VERSION}}", $Version) | Set-Content $readmeInstall -Encoding UTF8

    $isccExe = Get-InnoSetupCompiler
    Write-Host "==> Compilando instalador com Inno Setup"
    Write-Host "    ISCC: $isccExe"

    $compilerArgs = @(
        $issPath,
        "/DMyAppVersion=$Version",
        "/DMyReleaseDir=$releaseDir",
        "/DMyOutputDir=$distRoot",
        "/DMyAppIcon=$iconPath",
        "/DMyReadmeFile=$readmeInstall"
    )

    $process = Start-Process -FilePath $isccExe -ArgumentList $compilerArgs -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Compilacao Inno Setup falhou (exit $($process.ExitCode))"
    }

    if (-not (Test-Path $setupPath)) {
        throw "Instalador nao gerado: $setupPath"
    }

    return $setupPath
}

function Get-InnoSetupCompiler {
    $fromPath = Get-Command ISCC -ErrorAction SilentlyContinue
    $candidates = @(
        $(if ($fromPath) { $fromPath.Source }),
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    if (@($candidates).Count -eq 0) {
        throw "Inno Setup 6 nao encontrado. Instale de https://jrsoftware.org/isdl.php ou: choco install innosetup"
    }

    return @($candidates)[0]
}
