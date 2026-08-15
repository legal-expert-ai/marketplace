#define InstallerVersion "1.0.3"

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
procedure InstallerOutput(const S: String; const Error, FirstLine: Boolean);
var
  Payload: String;
  Separator: Integer;
  Percent: Integer;
  MessageText: String;
begin
  if Error then
  begin
    Log('Nu am putut citi progresul installerului: ' + S);
    Exit;
  end;

  Log(S);
  if Pos('LEGAL_EXPERT_PROGRESS|', S) <> 1 then
    Exit;

  Payload := Copy(S, Length('LEGAL_EXPERT_PROGRESS|') + 1, MaxInt);
  Separator := Pos('|', Payload);
  if Separator = 0 then
    Exit;

  Percent := StrToIntDef(Copy(Payload, 1, Separator - 1), -1);
  MessageText := Copy(Payload, Separator + 1, MaxInt);
  if (Percent < 0) or (Percent > 100) or (MessageText = '') then
    Exit;

  WizardForm.ProgressGauge.Max := 100;
  WizardForm.ProgressGauge.Position := Percent;
  WizardForm.StatusLabel.Caption := MessageText;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  PowerShellPath: String;
  Parameters: String;
begin
  if CurStep <> ssPostInstall then
    Exit;

  WizardForm.ProgressGauge.Max := 100;
  WizardForm.ProgressGauge.Position := 1;
  WizardForm.StatusLabel.Caption := 'Pornesc instalarea Legal Expert...';
  PowerShellPath := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  Parameters := '-NoProfile -ExecutionPolicy Bypass -File "' +
    ExpandConstant('{app}\Install-LegalExpert.ps1') + '" -InstallRoot "' +
    ExpandConstant('{app}') + '"';

  if (not ExecAndLogOutput(
       PowerShellPath,
       Parameters,
       '',
       SW_SHOWNORMAL,
       ewWaitUntilTerminated,
       ResultCode,
       @InstallerOutput
     )) or
     (ResultCode <> 0) then
  begin
    WizardForm.StatusLabel.Caption := 'Instalarea Legal Expert a esuat.';
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
      'Legal Expert a fost instalat si verificat cu succes.' + #13#10 + #13#10 +
      'IMPORTANT: inchiderea ferestrei ChatGPT nu este suficienta.' + #13#10 +
      'Din system tray, apasati click dreapta pe ChatGPT si alegeti Quit/Exit,' + #13#10 +
      'apoi porniti din nou aplicatia pentru a incarca pluginul si noul PATH.',
      mbInformation,
      MB_OK
    );
  end;
end;
