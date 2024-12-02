[Setup]
AppName=MyPass+
AppVersion=0.0.3
AppVerName=MyPass+
AppPublisher=rfvc
AppPublisherURL=https://github.com/rodolfo-verde
DefaultDirName={pf}\MyPass+
DefaultGroupName=MyPass+
OutputDir=.
OutputBaseFilename=MyPass+Installer
Compression=lzma
SolidCompression=yes
UninstallDisplayIcon={app}\password_manager.exe
AppId={{80133055-5abf-4cf4-a5ff-0ddd2330d4de}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MyPass+"; Filename: "{app}\password_manager.exe"
Name: "{group}\Uninstall MyPass+"; Filename: "{uninstallexe}"
Name: "{commondesktop}\MyPass+"; Filename: "{app}\password_manager.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\password_manager.exe"; Description: "{cm:LaunchProgram,MyPass+}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\MyPass+"
Type: filesandordirs; Name: "{userappdata}\rfvc\MyPass+"

[Registry]
; Write the current version to the registry for future version checks
Root: HKLM; Subkey: "Software\MyPassPlus"; ValueType: string; ValueName: "Version"; ValueData: "0.0.3"; Flags: uninsdeletevalue

[Code]
const
  MyAppVersion = '0.0.3';

function CompareVersions(InstalledVersion, CurrentVersion: string): Integer;
begin
  Result := CompareText(InstalledVersion, CurrentVersion);
end;

function InitializeSetup(): Boolean;
var
  InstalledVersion: string;
  CompareResult: Integer;
begin
  Result := True; // Allow installation by default
  
  // Check the registry for the installed version
  if RegQueryStringValue(HKLM, 'Software\MyPassPlus', 'Version', InstalledVersion) then
  begin
    CompareResult := CompareVersions(InstalledVersion, MyAppVersion);
    
    if CompareResult >= 0 then
    begin
      // If the installed version is the same or newer, show a message and cancel installation
      MsgBox(ExpandConstant('{cm:AlreadyInstalledMsg}'), mbError, MB_OK);
      Result := False;
    end;
  end;
end;

[Messages]
english.ConfirmUninstall=Warning: Uninstalling %1 will permanently delete all your saved passwords.%n%nAre you sure you want to completely remove %1 and all of its components?
spanish.ConfirmUninstall=Advertencia: Desinstalar %1 eliminará permanentemente todas sus contraseñas guardadas.%n%n¿Está seguro que desea eliminar completamente %1 y todos sus componentes?

[CustomMessages]
english.AlreadyInstalledMsg=A newer or the same version of MyPass+ is already installed. Uninstall it first before installing this version.
spanish.AlreadyInstalledMsg=Ya hay una versión más nueva o la misma versión de MyPass+ instalada. Desinstálala primero antes de instalar esta versión.