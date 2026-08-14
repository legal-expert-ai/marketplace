#define InstallerVersion "1.0.0"

[Setup]
AppId={{AE258957-F55B-4702-A8A3-1A1DD5D9C10F}
AppName=Legal Expert Plugin
AppVersion={#InstallerVersion}
AppPublisher=Legal Expert
AppPublisherURL=https://legal-hints.ai
AppSupportURL=https://github.com/legal-expert-ai/marketplace/blob/main/SUPPORT.md
DefaultDirName={localappdata}\Legal Expert
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ChangesEnvironment=yes
Uninstallable=no
OutputDir=..\..\dist
OutputBaseFilename=LegalExpertSetup
SetupIconFile=..\..\plugins\legal-expert\assets\logo.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "Install-LegalExpert.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  PowerShellPath: String;
  Parameters: String;
begin
  if CurStep <> ssPostInstall then
    Exit;

  WizardForm.StatusLabel.Caption := 'Instalez Legal Expert si dependintele necesare...';
  PowerShellPath := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  Parameters := '-NoProfile -ExecutionPolicy Bypass -File "' +
    ExpandConstant('{app}\Install-LegalExpert.ps1') + '" -InstallRoot "' +
    ExpandConstant('{app}') + '"';

  if (not Exec(PowerShellPath, Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode)) or
     (ResultCode <> 0) then
  begin
    MsgBox(
      'Instalarea nu s-a putut finaliza.' + #13#10 + #13#10 +
      'Detaliile sunt in:' + #13#10 + ExpandConstant('{app}\installer.log'),
      mbError,
      MB_OK
    );
  end
  else
  begin
    MsgBox(
      'Legal Expert a fost instalat cu succes.' + #13#10 + #13#10 +
      'Inchideti complet ChatGPT si deschideti-l din nou pentru a incarca pluginul.',
      mbInformation,
      MB_OK
    );
  end;
end;
