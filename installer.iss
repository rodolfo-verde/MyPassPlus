[Setup]
AppName=MyPass+
AppVersion=0.0.3
AppVerName=MyPass+
DefaultDirName={pf}\MyPass+
DefaultGroupName=MyPass+
OutputDir=.
OutputBaseFilename=MyPass+Installer
Compression=lzma
SolidCompression=yes
UninstallDisplayIcon={app}\MyPass+.exe
AppId={{80133055-5abf-4cf4-a5ff-0ddd2330d4de}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MyPass+"; Filename: "{app}\MyPass+.exe"
Name: "{group}\Uninstall MyPass+"; Filename: "{uninstallexe}"
Name: "{commondesktop}\MyPass+"; Filename: "{app}\MyPass+.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\MyPass+.exe"; Description: "{cm:LaunchProgram,MyPass+}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\MyPass+"
Type: filesandordirs; Name: "{userappdata}\rfvc\MyPass+"

[Registry]
; Write the current version to the registry for future version checks
Root: HKLM; Subkey: "Software\MyPassPlus"; ValueType: string; ValueName: "Version"; ValueData: "0.0.3"; Flags: uninsdeletevalue

[Code]
const
  MyAppVersion = '0.0.3';

function IsAppRunning(): Boolean;
var
  ResultCode: Integer;
begin
  if not Exec('tasklist.exe', '/FI "IMAGENAME eq MyPass+.exe" /NH', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Result := False;
  end
  else
  begin
    if (ResultCode = 0) then
      Result := True
    else
      Result := False;
  end;

  if Result then
  begin
    MsgBox(ExpandConstant('{cm:AppIsRunningMsg}'), mbError, MB_OK);
  end;
end;

function CompareVersions(Ver1, Ver2: string): Integer;
var
  Pos1, Pos2, Len1, Len2, Num1, Num2: Integer;
  Part1, Part2: string;
begin
  Pos1 := 1;
  Pos2 := 1;
  Len1 := Length(Ver1);
  Len2 := Length(Ver2);
  
  // Compare each version part
  while (Pos1 <= Len1) or (Pos2 <= Len2) do
  begin
    // Get next version part from Ver1
    Part1 := '';
    while (Pos1 <= Len1) and (Ver1[Pos1] <> '.') do
    begin
      Part1 := Part1 + Ver1[Pos1];
      Inc(Pos1);
    end;
    Inc(Pos1); // skip dot
    
    // Get next version part from Ver2
    Part2 := '';
    while (Pos2 <= Len2) and (Ver2[Pos2] <> '.') do
    begin
      Part2 := Part2 + Ver2[Pos2];
      Inc(Pos2);
    end;
    Inc(Pos2); // skip dot
    
    // Convert to numbers and compare
    Num1 := StrToIntDef(Part1, 0);
    Num2 := StrToIntDef(Part2, 0);
    
    if Num1 < Num2 then
      Result := -1
    else if Num1 > Num2 then
      Result := 1
    else
      Continue;
      
    Exit;
  end;
  
  Result := 0;
end;

function InitializeSetup(): Boolean;
var
  InstalledVersion: string;
  CompareResult: Integer;
begin
  Result := True;
  
  // First check if the app is running
  if IsAppRunning() then
  begin
    Result := False;
    Exit;
  end;
  
  // Then proceed with version check
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
english.AppIsRunningMsg=MyPass+ is currently running. Please close the application before continuing with the installation.
spanish.AppIsRunningMsg=MyPass+ se está ejecutando actualmente. Por favor, cierre la aplicación antes de continuar con la instalación.