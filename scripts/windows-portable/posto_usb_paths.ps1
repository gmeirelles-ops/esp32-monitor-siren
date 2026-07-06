# Caminhos padrão dos dados locais do sirene_app (Windows).
# Dot-source: . "$PSScriptRoot\posto_usb_paths.ps1"

function Get-SireneSqlitePath {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    return Join-Path $docs 'sirene_app.sqlite'
}

function Get-SirenePrefsDir {
    return Join-Path $env:APPDATA 'br.com.diponto\Diponto Sirene Validator'
}

function Get-SirenePrefsPath {
    return Join-Path (Get-SirenePrefsDir) 'shared_preferences.json'
}

function Get-SireneUsbDadosDir {
    param([string]$PackageRoot)
    return Join-Path $PackageRoot 'dados_posto'
}
