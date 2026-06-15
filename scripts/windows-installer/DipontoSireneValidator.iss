# Diponto Sirene Validator - instalador Windows (Inno Setup 6)
; Compilado via scripts/build_windows_installer.ps1

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef MyReleaseDir
  #define MyReleaseDir "..\..\sirene_app\build\windows\x64\runner\Release"
#endif

#ifndef MyOutputDir
  #define MyOutputDir "..\..\dist"
#endif

#ifndef MyAppIcon
  #define MyAppIcon "..\..\sirene_app\windows\runner\resources\app_icon.ico"
#endif

#ifndef MyReadmeFile
  #define MyReadmeFile "..\windows-installer\LEIA-ME.install.txt"
#endif

#define MyAppName "Diponto Sirene Validator"
#define MyAppPublisher "Diponto"
#define MyAppExeName "sirene_app.exe"
#define MyAppId "{{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Diponto\Sirene Validator
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#MyOutputDir}
OutputBaseFilename=DipontoSireneValidator-{#MyAppVersion}-setup
SetupIconFile={#MyAppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=
InfoBeforeFile=
MinVersion=10.0

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na area de trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[Files]
Source: "{#MyReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#MyReadmeFile}"; DestDir: "{app}"; DestName: "LEIA-ME.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Iniciar {#MyAppName}"; Flags: nowait postinstall skipifsilent
