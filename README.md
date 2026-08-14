<p align="center">
  <img src="plugins/legal-expert/assets/logo.png" width="112" alt="Legal Expert">
</p>

<h1 align="center">Legal Expert Marketplace</h1>

<p align="center">
  Cercetare juridică românească, documente, analiză, OCR și Excel — direct în ChatGPT și Codex.
</p>

<p align="center">
  <a href="https://github.com/legal-expert-ai/marketplace/actions/workflows/validate.yml"><img alt="Validare" src="https://github.com/legal-expert-ai/marketplace/actions/workflows/validate.yml/badge.svg"></a>
  <img alt="Versiune" src="https://img.shields.io/badge/version-0.3.0--beta.1-6C4CF1">
  <img alt="OAuth" src="https://img.shields.io/badge/auth-OAuth%202.1-E05C8A">
</p>

<p align="center">
  <a href="https://github.com/legal-expert-ai/marketplace/releases/latest/download/LegalExpertSetup.exe"><strong>Download Legal Expert for Windows</strong></a>
  ·
  <a href="INSTALL.md">How to install</a>
</p>

Legal Expert ajută profesioniștii juridici să cerceteze legislația română, să organizeze documente, să analizeze contracte, să ruleze OCR, să compare documente și să construiască tabele Excel verificabile.

## De ce aveți nevoie

- un cont Legal Expert cu abonament care include acces MCP;
- aplicația ChatGPT desktop sau Codex cu suport pentru pluginuri;
- o conexiune la internet.

Backendul Legal Expert și serverul MCP rulează în cloud. Pe calculatorul clientului se instalează doar pluginul cu skill-urile și conexiunea OAuth. Nu sunt necesare PHP, Docker, Node.js, Python sau un serviciu Legal Expert local.

## Instalare pe Windows

Descărcați și rulați [LegalExpertSetup.exe](https://github.com/legal-expert-ai/marketplace/releases/latest/download/LegalExpertSetup.exe). Pentru instrucțiuni complete, consultați [How to install](INSTALL.md).

Installerul face automat următoarele:

- instalează un Git portabil, verificat SHA-256, numai dacă Git lipsește;
- configurează marketplace-ul oficial pe canalul `stable`;
- instalează sau actualizează pluginul Legal Expert;
- nu necesită drepturi de administrator.

La final, închideți complet ChatGPT și deschideți-l din nou. Selectați Legal Expert și autentificați-vă în contul Legal Expert când apare fereastra OAuth.

### Instalare manuală pentru administratori

În PowerShell:

```powershell
codex plugin marketplace add legal-expert-ai/marketplace --ref stable
codex plugin add legal-expert@legal-expert
```

Canalul `main` livrează versiunea beta verificată automat pe Linux și Windows. Canalul `stable` este promovat numai după verificarea live a OAuth-ului și a tuturor tool-urilor MCP.

## Actualizare

Rulați din nou `LegalExpertSetup.exe`. Installerul detectează configurația existentă și face upgrade automat.

Pentru administratori, actualizarea manuală rămâne disponibilă:

```powershell
codex plugin marketplace upgrade legal-expert
codex plugin add legal-expert@legal-expert
```

După actualizare, porniți o conversație nouă pentru încărcarea noilor skill-uri.

Modificările compatibile ale tool-urilor MCP sunt livrate server-side și nu necesită update local. Modificările skill-urilor folosesc versiuni SemVer și necesită actualizarea pluginului.

## Confidențialitate și suport

- [Politica de confidențialitate](https://legal-hints.ai/privacy)
- [Termeni și condiții](https://legal-hints.ai/terms)
- [Legal Expert](https://legal-hints.ai)

Legal Expert oferă suport pentru cercetare și analiză juridică, nu înlocuiește verificarea și judecata profesională.
