# Legal Expert pentru ChatGPT și Codex

Legal Expert ajută profesioniștii juridici să cerceteze legislația română, să organizeze documente, să analizeze contracte, să ruleze OCR, să compare documente și să construiască tabele Excel verificabile.

## De ce aveți nevoie

- un cont Legal Expert cu abonament care include acces MCP;
- aplicația ChatGPT desktop sau Codex cu suport pentru pluginuri;
- o conexiune la internet.

Backendul Legal Expert și serverul MCP rulează în cloud. Pe calculatorul clientului se instalează doar pluginul cu skill-urile și conexiunea OAuth. Nu sunt necesare PHP, Docker, Node.js, Python sau un serviciu Legal Expert local.

## Instalare early access pe Windows

În PowerShell:

```powershell
codex plugin marketplace add mincua/legal-expert-plugin --ref stable
codex plugin add legal-expert@legal-expert
```

Deschideți apoi o conversație nouă, selectați Legal Expert și autentificați-vă în contul Legal Expert când apare fereastra OAuth.

Canalul `stable` este publicat numai după ce versiunea trece verificările OAuth și testele MCP. Până atunci, instalarea este intenționat indisponibilă.

## Actualizare

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
