# How to install Legal Expert on Windows

## Instalare recomandată

[**Descarcă LegalExpertSetup.exe**](https://github.com/legal-expert-ai/marketplace/releases/latest/download/LegalExpertSetup.exe)

1. Deschideți fișierul descărcat.
2. În fereastra de browser deschisă automat, autentificați-vă în contul Legal Expert.
3. Așteptați confirmarea că pluginul și conexiunea OAuth au fost verificate.
4. Închideți complet ChatGPT din system tray cu `Quit`/`Exit`, apoi deschideți-l din nou. Simplul click pe `X` poate lăsa aplicația activă.

Installerul nu necesită drepturi de administrator. Dacă Git lipsește, instalează automat o versiune portabilă verificată SHA-256. Dacă Legal Expert este deja instalat, același fișier face upgrade la versiunea disponibilă pe canalul `stable`.

## Instalare manuală pentru administratori

```powershell
codex plugin marketplace add legal-expert-ai/marketplace --ref stable
codex plugin add legal-expert@legal-expert
```

## Actualizare

Rulați din nou [LegalExpertSetup.exe](https://github.com/legal-expert-ai/marketplace/releases/latest/download/LegalExpertSetup.exe), apoi reporniți ChatGPT.

## Ajutor

Dacă instalarea nu se finalizează, trimiteți suportului fișierul:

```text
%LOCALAPPDATA%\Legal Expert\installer.log
```

Consultați și [SUPPORT.md](SUPPORT.md).
