Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$env:CODEX_CONNECTION_FIXER_NO_GUI = "1"
. (Join-Path $PSScriptRoot "CodexConnectionFixer.ps1")

$script:Failures = 0

function Invoke-Test {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Body
  )

  try {
    & $Body
    Write-Host "PASS $Name"
  } catch {
    $script:Failures += 1
    Write-Host "FAIL $Name"
    Write-Host "  $($_.Exception.Message)"
  }
}

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Assert-Equal {
  param(
    [AllowNull()]$Actual,
    [AllowNull()]$Expected,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if ($Actual -ne $Expected) {
    throw "$Message Actual=[$Actual] Expected=[$Expected]"
  }
}

function Assert-CommandExists {
  param([Parameter(Mandatory = $true)][string]$Name)

  Assert-True -Condition ([bool](Get-Command $Name -ErrorAction SilentlyContinue)) -Message "Missing function: $Name"
}

function New-TestCodexHome {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-fixer-test-" + [Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force $root | Out-Null
  return $root
}

function Read-Utf8 {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8 {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )
  $directory = Split-Path -Parent $Path
  if ($directory) {
    New-Item -ItemType Directory -Force $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
}

function New-CodePointString {
  param([Parameter(Mandatory = $true)][int[]]$CodePoints)

  $characters = foreach ($codePoint in $CodePoints) {
    [char]$codePoint
  }
  return (-join $characters)
}

Invoke-Test "empty config gets HTTP-only provider" {
  Assert-CommandExists "Update-CodexConfigText"

  $updated = Update-CodexConfigText -Content ""

  Assert-True -Condition ($updated -match '(?m)^model_provider = "openai_http"$') -Message "top-level model_provider was not written"
  Assert-True -Condition ($updated -match '(?m)^\[model_providers\.openai_http\]$') -Message "provider table was not written"
  Assert-True -Condition ($updated -match '(?m)^supports_websockets = false$') -Message "supports_websockets was not disabled"
}

Invoke-Test "existing sections are preserved and provider is top-level" {
  Assert-CommandExists "Update-CodexConfigText"
  Assert-CommandExists "Get-CodexConfigTextStatus"

  $config = @'
model = "gpt-5.5"

[plugins."github@openai-curated"]
enabled = true

[projects.'c:\users\demo\project']
trust_level = "trusted"
'@

  $updated = Update-CodexConfigText -Content $config
  $status = Get-CodexConfigTextStatus -Content $updated
  $firstTableIndex = $updated.IndexOf("[plugins.")
  $providerIndex = $updated.IndexOf('model_provider = "openai_http"')

  Assert-True -Condition ($providerIndex -ge 0) -Message "model_provider was not inserted"
  Assert-True -Condition ($providerIndex -lt $firstTableIndex) -Message "model_provider was inserted inside a table"
  Assert-True -Condition ($updated.Contains('[plugins."github@openai-curated"]')) -Message "plugin section was not preserved"
  Assert-True -Condition ($updated.Contains("[projects.'c:\users\demo\project']")) -Message "project section was not preserved"
  Assert-Equal -Actual $status.State -Expected "Fixed" -Message "status should be Fixed"
}

Invoke-Test "existing provider table is updated without duplication" {
  Assert-CommandExists "Update-CodexConfigText"

  $config = @'
model_provider = "openai_ws"

[model_providers.openai_http]
name = "Old"
wire_api = "chat"
supports_websockets = true

[desktop]
conversationDetailMode = "STEPS_COMMANDS"
'@

  $updated = Update-CodexConfigText -Content $config
  $tableCount = ([regex]::Matches($updated, '(?m)^\[model_providers\.openai_http\]$')).Count

  Assert-Equal -Actual $tableCount -Expected 1 -Message "provider table was duplicated"
  Assert-True -Condition ($updated -match '(?m)^name = "OpenAI HTTP only"$') -Message "provider name was not updated"
  Assert-True -Condition ($updated -match '(?m)^wire_api = "responses"$') -Message "wire_api was not updated"
  Assert-True -Condition ($updated -match '(?m)^supports_websockets = false$') -Message "supports_websockets was not updated"
  Assert-True -Condition ($updated.Contains('[desktop]')) -Message "following table was not preserved"
}

Invoke-Test "applying fix twice is idempotent" {
  Assert-CommandExists "Update-CodexConfigText"

  $first = Update-CodexConfigText -Content 'model = "gpt-5.5"'
  $second = Update-CodexConfigText -Content $first

  Assert-Equal -Actual $second -Expected $first -Message "second update changed already-fixed content"
}

Invoke-Test "apply creates backup and rollback restores exact original" {
  Assert-CommandExists "Apply-CodexConnectionFix"
  Assert-CommandExists "Rollback-CodexConnectionFix"

  $codexHome = New-TestCodexHome
  try {
    $configPath = Join-Path $codexHome "config.toml"
    $original = "model = `"gpt-5.5`"`r`n`r`n[desktop]`r`nconversationDetailMode = `"STEPS_COMMANDS`"`r`n"
    Write-Utf8 -Path $configPath -Content $original

    $applyResult = Apply-CodexConnectionFix -CodexHome $codexHome
    Assert-True -Condition ([System.IO.File]::Exists($applyResult.BackupPath)) -Message "backup was not created"
    Assert-True -Condition ((Read-Utf8 -Path $configPath) -match 'model_provider = "openai_http"') -Message "config was not updated"

    $rollbackResult = Rollback-CodexConnectionFix -CodexHome $codexHome
    Assert-Equal -Actual (Read-Utf8 -Path $configPath) -Expected $original -Message "rollback did not restore exact original content"
    Assert-Equal -Actual $rollbackResult.State -Expected "RolledBack" -Message "rollback result state mismatch"
  } finally {
    Remove-Item -Recurse -Force $codexHome -ErrorAction SilentlyContinue
  }
}

Invoke-Test "rollback without state does not guess a backup" {
  Assert-CommandExists "Rollback-CodexConnectionFix"

  $codexHome = New-TestCodexHome
  try {
    $backupDir = Join-Path $codexHome "backups"
    New-Item -ItemType Directory -Force $backupDir | Out-Null
    Write-Utf8 -Path (Join-Path $backupDir "config.toml.backup-20260607-120000") -Content "old"

    $result = Rollback-CodexConnectionFix -CodexHome $codexHome

    Assert-Equal -Actual $result.State -Expected "NoState" -Message "rollback should not guess backup without state"
  } finally {
    Remove-Item -Recurse -Force $codexHome -ErrorAction SilentlyContinue
  }
}

Invoke-Test "missing config directory is created on apply" {
  Assert-CommandExists "Apply-CodexConnectionFix"

  $codexHome = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-fixer-missing-" + [Guid]::NewGuid().ToString("N"))
  try {
    $result = Apply-CodexConnectionFix -CodexHome $codexHome
    $configPath = Join-Path $codexHome "config.toml"

    Assert-True -Condition ([System.IO.File]::Exists($configPath)) -Message "config file was not created"
    Assert-Equal -Actual $result.State -Expected "Fixed" -Message "apply result state mismatch"
  } finally {
    Remove-Item -Recurse -Force $codexHome -ErrorAction SilentlyContinue
  }
}

Invoke-Test "GUI entry points and launcher exist" {
  Assert-CommandExists "Format-CodexConnectionStatusText"
  Assert-CommandExists "Start-CodexConnectionFixerGui"

  $statusText = Format-CodexConnectionStatusText -Status ([pscustomobject]@{
    State = "Fixed"
    ConfigPath = "C:\Users\demo\.codex\config.toml"
    ModelProvider = "openai_http"
    HasHttpProviderTable = $true
    SupportsWebsocketsFalse = $true
    RollbackAvailable = $true
  })

  Assert-True -Condition ($statusText.Contains("config.toml")) -Message "status text should include config path"
  Assert-True -Condition ([System.IO.File]::Exists((Join-Path $PSScriptRoot "Run-CodexConnectionFixer.bat"))) -Message "launcher batch file is missing"
}

Invoke-Test "GUI defaults to Chinese and launchers do not leave a terminal window" {
  Assert-CommandExists "Format-CodexConnectionStatusText"

  $statusText = Format-CodexConnectionStatusText -Status ([pscustomobject]@{
    State = "Fixed"
    ConfigPath = "C:\Users\demo\.codex\config.toml"
    ModelProvider = "openai_http"
    HasHttpProviderTable = $true
    SupportsWebsocketsFalse = $true
    RollbackAvailable = $true
  })
  $batchPath = Join-Path $PSScriptRoot "Run-CodexConnectionFixer.bat"
  $vbsPath = Join-Path $PSScriptRoot "Run-CodexConnectionFixer.vbs"
  $batch = Read-Utf8 -Path $batchPath
  $stateFixed = New-CodePointString -CodePoints @(0x72B6, 0x6001, 0xFF1A, 0x5DF2, 0x4FEE, 0x590D)
  $configPrefix = New-CodePointString -CodePoints @(0x914D, 0x7F6E, 0xFF1A)
  $webSocketLabel = "WebSocket " + (New-CodePointString -CodePoints @(0x5DF2, 0x7981, 0x7528, 0xFF1A)) + "True"

  Assert-True -Condition ($statusText.Contains($stateFixed)) -Message "status text should default to Chinese"
  Assert-True -Condition ($statusText.Contains($configPrefix + "C:\Users\demo\.codex\config.toml")) -Message "config label should be Chinese"
  Assert-True -Condition ($statusText.Contains($webSocketLabel)) -Message "WebSocket status label should be Chinese"
  Assert-True -Condition ($batch.Contains("-WindowStyle Hidden")) -Message "batch launcher should hide the PowerShell window"
  Assert-True -Condition ([System.IO.File]::Exists($vbsPath)) -Message "no-console VBScript launcher is missing"
  Assert-True -Condition ((Read-Utf8 -Path $vbsPath).Contains(", 0, False")) -Message "VBScript launcher should run hidden"
}

if ($script:Failures -gt 0) {
  Write-Host "$script:Failures test(s) failed."
  exit 1
}

Write-Host "All Codex Connection Fixer tests passed."
