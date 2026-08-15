# Changelog

## Windows installer 1.0.5

- Accepts Codex's `o_auth` status after a successful browser callback.
- Adds branded Legal Expert welcome, progress, and completion screens.
- Uses the official `legal-expert.ai` logo, icon, palette, and publisher URL.

## Windows installer 1.0.4

- Correctly parses top-level MCP arrays returned by Windows PowerShell 5.1.
- Handles other configured MCP servers whose transports do not expose a URL.

## 0.3.1 - 2026-08-15

- Replaced the legacy Legal Hints icon and links with official Legal Expert branding.
- Added the official Legal Expert wordmark and brand color.

## Windows installer 1.0.3

- Replaces stale preview MCP connections with `https://api.legal-expert.ai/mcp` during upgrades.
- Preserves an existing OAuth session when the configured Legal Expert MCP endpoint is already production.
- Verifies the production MCP URL before reporting installation success.

## Windows installer 1.0.2

- Added the native Legal Expert OAuth login and verification flow to installation and upgrades.
- Added real installation progress and an explicit ChatGPT system-tray restart reminder.
- Kept the verified portable Git fallback for Windows clients without Git installed.

## Windows installer 1.0.1

- Added a one-click, per-user Windows installer.
- Added a pinned and SHA-256-verified portable Git fallback for x64 and ARM64.
- Added idempotent marketplace/plugin installation and upgrade behavior.
- Added Windows installer smoke tests, including the no-Git fallback, and release artifacts in GitHub Actions.

## 0.3.0 - 2026-08-15

- OAuth 2.1 nativ pentru MCP, fără tokenuri configurate manual.
- Diagnostic separat pentru conexiune indisponibilă, autentificare necesară și tool lipsă.
- Cercetare tabelară fără dependență Python pe calculatorul clientului.
- Distribuție marketplace compatibilă Windows.
- Conexiune implicită la MCP-ul de producție `https://api.legal-expert.ai/mcp`.
