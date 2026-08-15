# Changelog

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
