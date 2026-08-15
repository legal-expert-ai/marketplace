#ifndef InstallerVersion
  #define InstallerVersion "1.0.5"
#endif

[Setup]
AppId={{AE258957-F55B-4702-A8A3-1A1DD5D9C10F}
AppName=Legal Expert for ChatGPT
AppVersion={#InstallerVersion}
AppVerName=Legal Expert for ChatGPT {#InstallerVersion}
AppPublisher=Legal Expert
AppPublisherURL=https://legal-expert.ai
AppSupportURL=https://github.com/legal-expert-ai/marketplace/blob/main/SUPPORT.md
AppUpdatesURL=https://github.com/legal-expert-ai/marketplace/releases/latest
VersionInfoCompany=Legal Expert
VersionInfoDescription=Legal Expert for ChatGPT Installer
VersionInfoProductName=Legal Expert for ChatGPT
VersionInfoProductVersion={#InstallerVersion}
VersionInfoVersion={#InstallerVersion}
DefaultDirName={localappdata}\Legal Expert
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableWelcomePage=no
DisableFinishedPage=no
PrivilegesRequired=lowest
ChangesEnvironment=yes
Uninstallable=no
OutputDir=..\..\dist
OutputBaseFilename=LegalExpertSetup
SetupIconFile=..\..\plugins\legal-expert\assets\logo.ico
WizardImageFile=assets\wizard-background.png
WizardSmallImageFile=..\..\plugins\legal-expert\assets\logo.png
WizardImageStretch=yes
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "Install-LegalExpert.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Code]
procedure InitializeWizard;
begin
  WizardForm.Caption := 'Legal Expert pentru ChatGPT';
  WizardForm.WelcomeLabel1.Caption := 'Legal Expert pentru ChatGPT';
  WizardForm.WelcomeLabel2.Caption :=
    'Cercetare juridica, analiza de documente si workflow-uri Legal Expert,' + #13#10 +
    'direct in ChatGPT. Instalarea include conexiunea securizata OAuth.';
  WizardForm.FinishedHeadingLabel.Caption := 'Legal Expert este pregatit';
  WizardForm.FinishedLabel.Caption :=
    'Pluginul si conexiunea securizata au fost instalate.' + #13#10 + #13#10 +
    'Inchideti complet ChatGPT din system tray, apoi deschideti aplicatia din nou.';
  WizardForm.PageNameLabel.Font.Color := $00F73E9B;
  WizardForm.StatusLabel.Font.Color := $00F73E9B;
end;

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
    ExpandConstant('{app}') + '" -InstallerVersion "{#InstallerVersion}"';

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
