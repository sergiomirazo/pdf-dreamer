; Build using scripts/build_windows_installer.ps1 (metadata comes from the EXE).
#ifndef BuildDir
  #if FileExists(SourcePath + "..\..\build\installer\build-config.iss")
    #include "..\..\build\installer\build-config.iss"
  #else
    #error Run scripts/build_windows_installer.ps1 first to configure BuildDir and installer metadata.
  #endif
#endif
#ifndef RedistDir
  #error RedistDir is required
#endif
#define AppExe AppIdName + ".exe"
#define PdfProgId AppIdName + ".PDF"
#define MdProgId AppIdName + ".Markdown"
#define Capabilities "Software\" + AppPublisher + "\" + AppIdName + "\Capabilities"

[Setup]
AppId={#AppIdName}
AppName={#AppName}
AppVersion={#AppVersion}
VersionInfoVersion={#NumericVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Programs\{#AppIdName}
DefaultGroupName={#AppName}
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename={#AppIdName}-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ChangesAssociations=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb,*.lib,*.exp"
; App-local Microsoft VC++ runtime: target PCs need neither Flutter nor VS.
Source: "{#RedistDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"

[Registry]
; Only our own ProgIDs and values are removed on uninstall. Extension defaults
; and UserChoice are never written, including during upgrades.
Root: HKCU; Subkey: "Software\Classes\{#PdfProgId}"; ValueType: string; ValueData: "{#AppName} PDF"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\{#PdfProgId}\DefaultIcon"; ValueType: string; ValueData: """{app}\{#AppExe}"",0"
Root: HKCU; Subkey: "Software\Classes\{#PdfProgId}\shell\open\command"; ValueType: string; ValueData: """{app}\{#AppExe}"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\{#MdProgId}"; ValueType: string; ValueData: "{#AppName} Markdown"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\{#MdProgId}\DefaultIcon"; ValueType: string; ValueData: """{app}\{#AppExe}"",0"
Root: HKCU; Subkey: "Software\Classes\{#MdProgId}\shell\open\command"; ValueType: string; ValueData: """{app}\{#AppExe}"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\.pdf\OpenWithProgids"; ValueType: string; ValueName: "{#PdfProgId}"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.md\OpenWithProgids"; ValueType: string; ValueName: "{#MdProgId}"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}"; ValueType: string; ValueName: "FriendlyAppName"; ValueData: "{#AppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\shell\open\command"; ValueType: string; ValueData: """{app}\{#AppExe}"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".pdf"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".md"; ValueData: ""
Root: HKCU; Subkey: "{#Capabilities}"; ValueType: string; ValueName: "ApplicationName"; ValueData: "{#AppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "{#Capabilities}"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "PDF and Markdown reader"
Root: HKCU; Subkey: "{#Capabilities}"; ValueType: string; ValueName: "ApplicationIcon"; ValueData: """{app}\{#AppExe}"",0"
Root: HKCU; Subkey: "{#Capabilities}\FileAssociations"; ValueType: string; ValueName: ".pdf"; ValueData: "{#PdfProgId}"
Root: HKCU; Subkey: "{#Capabilities}\FileAssociations"; ValueType: string; ValueName: ".md"; ValueData: "{#MdProgId}"
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "{#AppIdName}"; ValueData: "{#Capabilities}"; Flags: uninsdeletevalue
; MIME metadata lives on our ProgIDs, preserving shared extension metadata.
Root: HKCU; Subkey: "Software\Classes\{#PdfProgId}"; ValueType: string; ValueName: "Content Type"; ValueData: "application/pdf"
Root: HKCU; Subkey: "Software\Classes\{#MdProgId}"; ValueType: string; ValueName: "Content Type"; ValueData: "text/markdown"

[Run]
Filename: "ms-settings:defaultapps"; Description: "{cm:ChooseDefaults}"; Flags: shellexec postinstall skipifsilent
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent unchecked

[CustomMessages]
spanish.ChooseDefaults=Abrir Configuracion de Windows para elegir PDF Dreamer como predeterminada para PDF y MD
english.ChooseDefaults=Open Windows Settings to choose PDF Dreamer as the default for PDF and MD
portuguese.ChooseDefaults=Abrir Configuracoes do Windows para escolher PDF Dreamer como padrao para PDF e MD
