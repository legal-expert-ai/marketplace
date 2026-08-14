# How to install Legal Expert on Windows

## Instalare recomandată

[**Descarcă LegalExpertSetup.exe**](https://github.com/legal-expert-ai/marketplace/releases/latest/download/LegalExpertSetup.exe)

1. Deschideți fișierul descărcat.
2. Așteptați confirmarea că Legal Expert a fost instalat.
3. Închideți complet ChatGPT și deschideți-l din nou.
4. Selectați Legal Expert și autentificați-vă prin OAuth.

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
