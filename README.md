# Codex Connection Fixer

A small Windows GUI utility for Codex users whose sessions pause at startup while Codex repeatedly reconnects before falling back to HTTP.

The tool applies a reversible Codex configuration change that selects an HTTP-only OpenAI provider.

## Who This Helps

Use this tool when Codex shows repeated `Reconnecting` attempts before it starts thinking, especially on networks or proxy setups where WebSocket traffic is unreliable.

This tool does not change VPN, proxy, DNS, firewall, Codex login, or GitHub settings.

## Run

Double-click:

```text
Run-CodexConnectionFixer.bat
```

If Windows blocks the script, right-click the folder, choose "Open in Terminal", and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\CodexConnectionFixer.ps1
```

## Buttons

- `Detect Status`: checks the current Codex configuration without changing files.
- `Run Fix`: creates a backup and applies the HTTP-only provider configuration.
- `Rollback`: restores the most recent backup created by this tool.
- `Open Config Folder`: opens `%USERPROFILE%\.codex`.

Restart Codex after running the fix or rollback.

## What It Changes

Target file:

```text
%USERPROFILE%\.codex\config.toml
```

The fix sets a top-level provider:

```toml
model_provider = "openai_http"
```

It also creates or updates this provider table:

```toml
[model_providers.openai_http]
name = "OpenAI HTTP only"
wire_api = "responses"
supports_websockets = false
```

The script preserves existing model settings, plugin settings, project trust settings, notify settings, and other unrelated tables.

## Backup And Rollback

Before writing config, the tool creates a backup:

```text
%USERPROFILE%\.codex\backups\config.toml.backup-YYYYMMDD-HHMMSS
```

It records rollback metadata here:

```text
%USERPROFILE%\.codex\codex-connection-fixer-state.json
```

`Rollback` restores the backup recorded in that state file. If the state file is missing, the tool will not guess which backup to restore.

## Test

From this directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Test-CodexConnectionFixer.ps1
```

Expected result:

```text
All Codex Connection Fixer tests passed.
```

## Troubleshooting

If Codex still reconnects repeatedly after the fix:

1. Restart Codex completely.
2. Click `Detect Status` and confirm state is `Fixed`.
3. Check whether your Codex version supports `model_providers` and `supports_websockets`.
4. If needed, click `Rollback` and report the issue with your Codex version and proxy/VPN setup.

If rollback fails:

1. Click `Open Config Folder`.
2. Open the `backups` folder.
3. Restore the intended `config.toml.backup-*` file manually by renaming it to `config.toml`.
