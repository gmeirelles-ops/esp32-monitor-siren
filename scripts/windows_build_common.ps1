#Requires -Version 5.1
# Funcoes compartilhadas para build Windows (portatil e instalador).

$script:SubstDrive = "S:"
$script:RepoRootCache = $null

function Test-HasNonAsciiPath {
    param([string]$Path)
    return $Path -cmatch '[^\u0000-\u007F]'
}

function Get-PhysicalRepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Assert-SafeWindowsProjectPath {
    $physicalRoot = Get-PhysicalRepoRoot
    if (-not (Test-HasNonAsciiPath $physicalRoot)) {
        return
    }

    Write-Host ""
    Write-Host "ERRO: o projeto esta em caminho com acento/caractere especial:" -ForegroundColor Red
    Write-Host "  $physicalRoot"
    Write-Host ""
    Write-Host "O CMake grava esse caminho no cache e o build falha em flutter_wrapper_app.vcxproj."
    Write-Host "O mapeamento subst S: NAO resolve - o Windows expoe o caminho real ao CMake."
    Write-Host ""
    Write-Host "Solucao A (recomendada): mova ou clone para caminho ASCII, ex.:"
    Write-Host "  C:\dev\diponto-sirene"
    Write-Host ""
    Write-Host 'Solucao B (junction sem mover arquivos):'
    Write-Host ('  cmd /c mklink /J C:\dev\diponto-sirene "' + $physicalRoot + '"')
    Write-Host "  cd C:\dev\diponto-sirene"
    Write-Host "  powershell -ExecutionPolicy Bypass -File scripts\gerar_instalador_atualizado.ps1"
    Write-Host ""
    throw "Caminho do projeto incompativel com flutter build windows."
}

function Ensure-WindowsAsciiRepoPath {
    if ($script:RepoRootCache) {
        return $script:RepoRootCache
    }

    $physicalRoot = Get-PhysicalRepoRoot
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

    Assert-SafeWindowsProjectPath
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
    $logLines = [System.Collections.Generic.List[string]]::new()
    try {
        & $Command 2>&1 | ForEach-Object {
            $line = $_.ToString()
            Write-Host $line
            $logLines.Add($line)
        }
        if ($LASTEXITCODE -ne 0) {
            $logDir = Join-Path (Get-RepoRoot) "dist"
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            $logPath = Join-Path $logDir "last-build.log"
            $logLines | Set-Content $logPath -Encoding UTF8
            throw "$FailureMessage`nUltimas linhas salvas em: $logPath"
        }
    }
    finally {
        $ErrorActionPreference = $prevErrorAction
    }
}

function Invoke-SireneFlutterClean {
    $appDir = Get-SireneAppDir
    Push-Location $appDir
    try {
        Write-Host "==> flutter clean (remove cache CMake com caminhos antigos)"
        flutter clean 2>&1 | ForEach-Object { Write-Host $_ }
        $buildDir = Join-Path $appDir "build\windows"
        if (Test-Path $buildDir) {
            Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    finally {
        Pop-Location
    }
}

function Test-FirebaseCppSdkZipValid {
    param([string]$ZipPath)

    if (-not (Test-Path $ZipPath)) {
        return $false
    }

    $size = (Get-Item $ZipPath).Length
    if ($size -lt 100MB) {
        return $false
    }

    $marker = tar -tf $ZipPath 2>$null |
        Select-String "Release/firebase_firestore.lib" |
        Select-Object -First 1
    return $null -ne $marker
}

function Ensure-FirebaseCppSdkZip {
    param([string]$OverridePath)

    $sdkVersion = "12.7.0"
    $fileName = "firebase_cpp_sdk_windows_$sdkVersion.zip"
    $x64Dir = Join-Path (Get-SireneAppDir) "build\windows\x64"
    $dest = Join-Path $x64Dir $fileName

    if (Test-FirebaseCppSdkZipValid $dest) {
        $mb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
        Write-Host "==> SDK Firebase OK no build ($mb MB)"
        return
    }

    if (Test-Path $dest) {
        Write-Host "==> Removendo ZIP Firebase corrompido/incompleto no build"
        Remove-Item $dest -Force -ErrorAction SilentlyContinue
    }

    $extracted = Join-Path $x64Dir "extracted"
    if (Test-Path $extracted) {
        Remove-Item $extracted -Recurse -Force -ErrorAction SilentlyContinue
    }

    $candidates = @()
    if ($OverridePath) { $candidates += $OverridePath }
    if ($env:FIREBASE_SDK_ZIP) { $candidates += $env:FIREBASE_SDK_ZIP }
    $candidates += @(
        (Join-Path $env:USERPROFILE "Downloads\app_flutter\build\windows\x64\$fileName"),
        "C:\dev\firebase-cpp-sdk-cache\$fileName"
    )

    foreach ($src in ($candidates | Where-Object { $_ })) {
        if (-not (Test-Path $src)) { continue }
        if (-not (Test-FirebaseCppSdkZipValid $src)) { continue }

        New-Item -ItemType Directory -Path $x64Dir -Force | Out-Null
        $mb = [math]::Round((Get-Item $src).Length / 1MB, 1)
        Write-Host "==> Copiando SDK Firebase valido ($mb MB)"
        Write-Host "    Origem: $src"
        Copy-Item $src $dest -Force
        return
    }

    Write-Host ""
    Write-Host "AVISO: SDK Firebase local nao encontrado." -ForegroundColor Yellow
    Write-Host "  O build tentara baixar da internet (pode falhar em rede instavel)."
    Write-Host "  Copie um ZIP valido para Downloads\app_flutter\build\windows\x64\"
    Write-Host "  ou defina: `$env:FIREBASE_SDK_ZIP = 'C:\caminho\firebase_cpp_sdk_windows_12.7.0.zip'"
    Write-Host ""
}

function Invoke-SireneFlutterWindowsBuild {
    param(
        [switch]$SkipClean,
        [string]$FirebaseSdkZip
    )

    $appDir = Get-SireneAppDir
    $releaseDir = Get-SireneReleaseDir

    if (-not $SkipClean) {
        Invoke-SireneFlutterClean
    }

    Push-Location $appDir
    try {
        Write-Host "==> Build a partir de: $(Get-Location)"
        Invoke-ExternalBuildStep "flutter pub get" { flutter pub get } "flutter pub get falhou"
        Invoke-ExternalBuildStep "dart run build_runner build" { dart run build_runner build } "build_runner falhou"
        Ensure-FirebaseCppSdkZip -OverridePath $FirebaseSdkZip
        # CMake 4.x (VS/GitHub runners) rejeita firebase_cpp_sdk com min < 3.5.
        $env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"
        Invoke-ExternalBuildStep "flutter build windows --release" {
            flutter build windows --release
        } "flutter build windows falhou"
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
    Write-Host '==> Copiando tools/windows (esptool e manifest)'
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

    $usbExtras = @(
        "posto_usb_paths.ps1",
        "exportar_posto_usb.ps1",
        "instalar_posto_do_usb.ps1",
        "Instalar no PC.bat",
        "Exportar dados para USB.bat",
        "LEIA-ME-USB-POSTO.txt",
        "Diagnostico-Posto.ps1"
    )
    foreach ($name in $usbExtras) {
        $src = Join-Path $templatesDir $name
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $packageDir $name) -Force
        }
    }

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

function Ensure-SireneEsptoolBundled {
    $toolsDir = Join-Path (Get-SireneAppDir) "tools\windows"
    $esptool = Join-Path $toolsDir "esptool.exe"
    if (Test-Path $esptool) {
        return
    }
    Write-Host "==> esptool.exe ausente — gerando bundle..."
    $bundleScript = Join-Path (Get-SireneAppDir) "scripts\bundle_esptool_windows.ps1"
    if (-not (Test-Path $bundleScript)) {
        throw "esptool.exe nao encontrado e bundle script ausente: $bundleScript"
    }
    # Evita que stderr do pip (WARNING) aborte o job com $ErrorActionPreference=Stop.
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bundleScript
    $bundleExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($bundleExit -ne 0 -or -not (Test-Path $esptool)) {
        throw "Falha ao gerar esptool.exe em $toolsDir (exit=$bundleExit)"
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

    Ensure-SireneEsptoolBundled
    Copy-SireneBundledTools -AppDestDir $releaseDir

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
        $msg = 'Inno Setup 6 nao encontrado. Instale de https://jrsoftware.org/isdl.php ou: choco install innosetup'
        throw $msg
    }

    return @($candidates)[0]
}
