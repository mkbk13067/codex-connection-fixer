Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:FixerVersion = "0.1.0"

function ConvertTo-NormalizedLines {
  param([AllowNull()][string]$Content)

  $text = if ($null -eq $Content) { "" } else { $Content }
  $text = $text.TrimStart([char]0xFEFF)
  $text = $text -replace "`r`n", "`n"
  $text = $text -replace "`r", "`n"

  if ($text.Length -eq 0) {
    return @()
  }

  $lines = @($text -split "`n")
  if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq "") {
    if ($lines.Count -eq 1) {
      return @()
    }
    return @($lines[0..($lines.Count - 2)])
  }

  return $lines
}

function Join-NormalizedLines {
  param([AllowNull()][string[]]$Lines)

  if ($null -eq $Lines -or $Lines.Count -eq 0) {
    return ""
  }

  return (($Lines -join "`n") + "`n")
}

function Find-FirstTableIndex {
  param([AllowEmptyCollection()][string[]]$Lines)

  for ($index = 0; $index -lt $Lines.Count; $index += 1) {
    if ($Lines[$index] -match '^\s*\[') {
      return $index
    }
  }

  return -1
}

function Find-TableRange {
  param(
    [AllowEmptyCollection()][string[]]$Lines,
    [Parameter(Mandatory = $true)][string]$HeaderPattern
  )

  $start = -1
  for ($index = 0; $index -lt $Lines.Count; $index += 1) {
    if ($Lines[$index] -match $HeaderPattern) {
      $start = $index
      break
    }
  }

  if ($start -lt 0) {
    return [pscustomobject]@{ Exists = $false; Start = -1; End = -1 }
  }

  $end = $Lines.Count
  for ($index = $start + 1; $index -lt $Lines.Count; $index += 1) {
    if ($Lines[$index] -match '^\s*\[') {
      $end = $index
      break
    }
  }

  return [pscustomobject]@{ Exists = $true; Start = $start; End = $end }
}

function Set-TopLevelModelProvider {
  param([AllowEmptyCollection()][string[]]$Lines)

  $firstTableIndex = Find-FirstTableIndex -Lines $Lines
  if ($firstTableIndex -lt 0) {
    $topLines = @($Lines)
    $restLines = @()
  } else {
    $topLines = if ($firstTableIndex -eq 0) { @() } else { @($Lines[0..($firstTableIndex - 1)]) }
    $restLines = @($Lines[$firstTableIndex..($Lines.Count - 1)])
  }

  $resultTop = New-Object System.Collections.Generic.List[string]
  $providerWritten = $false
  foreach ($line in $topLines) {
    if ($line -match '^\s*model_provider\s*=') {
      if (-not $providerWritten) {
        $resultTop.Add('model_provider = "openai_http"')
        $providerWritten = $true
      }
      continue
    }
    $resultTop.Add($line)
  }

  if (-not $providerWritten) {
    $insertIndex = 0
    for ($index = 0; $index -lt $resultTop.Count; $index += 1) {
      if ($resultTop[$index] -match '^\s*model\s*=') {
        $insertIndex = $index + 1
      }
    }
    $resultTop.Insert($insertIndex, 'model_provider = "openai_http"')
  }

  return @($resultTop.ToArray()) + $restLines
}

function Set-HttpOnlyProviderTable {
  param([AllowEmptyCollection()][string[]]$Lines)

  $headerPattern = '^\s*\[model_providers\.openai_http\]\s*$'
  $range = Find-TableRange -Lines $Lines -HeaderPattern $headerPattern
  $desired = [ordered]@{
    name = 'name = "OpenAI HTTP only"'
    wire_api = 'wire_api = "responses"'
    supports_websockets = 'supports_websockets = false'
  }

  if (-not $range.Exists) {
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
      $result.Add($line)
    }
    if ($result.Count -gt 0 -and $result[$result.Count - 1].Trim().Length -gt 0) {
      $result.Add("")
    }
    $result.Add("[model_providers.openai_http]")
    foreach ($line in $desired.Values) {
      $result.Add($line)
    }
    return @($result.ToArray())
  }

  $before = if ($range.Start -eq 0) { @() } else { @($Lines[0..($range.Start - 1)]) }
  $after = if ($range.End -ge $Lines.Count) { @() } else { @($Lines[$range.End..($Lines.Count - 1)]) }
  $section = New-Object System.Collections.Generic.List[string]
  $section.Add("[model_providers.openai_http]")
  $seen = @{}

  for ($index = $range.Start + 1; $index -lt $range.End; $index += 1) {
    $line = $Lines[$index]
    if ($line -match '^\s*(name|wire_api|supports_websockets)\s*=') {
      $key = $Matches[1]
      if (-not $seen.ContainsKey($key)) {
        $section.Add($desired[$key])
        $seen[$key] = $true
      }
      continue
    }
    $section.Add($line)
  }

  foreach ($key in $desired.Keys) {
    if (-not $seen.ContainsKey($key)) {
      $section.Add($desired[$key])
    }
  }

  return $before + @($section.ToArray()) + $after
}

function Update-CodexConfigText {
  param([AllowNull()][string]$Content)

  $lines = @(ConvertTo-NormalizedLines -Content $Content)
  $lines = @(Set-TopLevelModelProvider -Lines $lines)
  $lines = @(Set-HttpOnlyProviderTable -Lines $lines)
  return Join-NormalizedLines -Lines $lines
}

function Get-CodexConfigTextStatus {
  param([AllowNull()][string]$Content)

  $lines = @(ConvertTo-NormalizedLines -Content $Content)
  $firstTableIndex = Find-FirstTableIndex -Lines $lines
  $topLines = if ($firstTableIndex -lt 0) { $lines } elseif ($firstTableIndex -eq 0) { @() } else { @($lines[0..($firstTableIndex - 1)]) }
  $topProvider = $null

  foreach ($line in $topLines) {
    if ($line -match '^\s*model_provider\s*=\s*"([^"]+)"') {
      $topProvider = $Matches[1]
      break
    }
  }

  $range = Find-TableRange -Lines $lines -HeaderPattern '^\s*\[model_providers\.openai_http\]\s*$'
  $supportsWebsocketsFalse = $false
  if ($range.Exists) {
    for ($index = $range.Start + 1; $index -lt $range.End; $index += 1) {
      if ($lines[$index] -match '^\s*supports_websockets\s*=\s*false\s*$') {
        $supportsWebsocketsFalse = $true
        break
      }
    }
  }

  $hasTopProvider = $topProvider -eq "openai_http"
  $hasProviderTable = [bool]$range.Exists
  $hasDisabledWebsockets = $hasProviderTable -and $supportsWebsocketsFalse
  $state = if ($hasTopProvider -and $hasDisabledWebsockets) {
    "Fixed"
  } elseif ($hasTopProvider -or $hasProviderTable -or $hasDisabledWebsockets) {
    "Incomplete Config"
  } else {
    "Not Fixed"
  }

  return [pscustomobject]@{
    State = $state
    ModelProvider = $topProvider
    HasHttpProviderTable = $hasProviderTable
    SupportsWebsocketsFalse = $supportsWebsocketsFalse
  }
}

function Get-CodexConnectionFixerPaths {
  param([string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"))

  return [pscustomobject]@{
    CodexHome = $CodexHome
    ConfigPath = Join-Path $CodexHome "config.toml"
    BackupDir = Join-Path $CodexHome "backups"
    StatePath = Join-Path $CodexHome "codex-connection-fixer-state.json"
  }
}

function Read-TextFileUtf8 {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-TextFileUtf8 {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [AllowNull()][string]$Content
  )

  $directory = Split-Path -Parent $Path
  if ($directory) {
    New-Item -ItemType Directory -Force $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $(if ($null -eq $Content) { "" } else { $Content }), [System.Text.Encoding]::UTF8)
}

function Get-CodexConnectionFixerStatus {
  param([string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"))

  $paths = Get-CodexConnectionFixerPaths -CodexHome $CodexHome
  $content = if ([System.IO.File]::Exists($paths.ConfigPath)) { Read-TextFileUtf8 -Path $paths.ConfigPath } else { "" }
  $textStatus = Get-CodexConfigTextStatus -Content $content
  $rollbackAvailable = [System.IO.File]::Exists($paths.StatePath)

  return [pscustomobject]@{
    State = $textStatus.State
    CodexHome = $paths.CodexHome
    ConfigPath = $paths.ConfigPath
    ConfigExists = [System.IO.File]::Exists($paths.ConfigPath)
    ModelProvider = $textStatus.ModelProvider
    HasHttpProviderTable = $textStatus.HasHttpProviderTable
    SupportsWebsocketsFalse = $textStatus.SupportsWebsocketsFalse
    RollbackAvailable = $rollbackAvailable
    StatePath = $paths.StatePath
  }
}

function Apply-CodexConnectionFix {
  param([string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"))

  $paths = Get-CodexConnectionFixerPaths -CodexHome $CodexHome
  New-Item -ItemType Directory -Force $paths.CodexHome | Out-Null
  New-Item -ItemType Directory -Force $paths.BackupDir | Out-Null

  $configExisted = [System.IO.File]::Exists($paths.ConfigPath)
  $original = if ($configExisted) { Read-TextFileUtf8 -Path $paths.ConfigPath } else { "" }
  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $backupPath = Join-Path $paths.BackupDir "config.toml.backup-$timestamp"
  Write-TextFileUtf8 -Path $backupPath -Content $original

  $statusBefore = Get-CodexConfigTextStatus -Content $original
  $updated = Update-CodexConfigText -Content $original
  Write-TextFileUtf8 -Path $paths.ConfigPath -Content $updated

  $state = [ordered]@{
    fixerVersion = $script:FixerVersion
    timestamp = $timestamp
    backupPath = $backupPath
    configExisted = $configExisted
    previousModelProvider = $statusBefore.ModelProvider
    previousModelProviderAbsent = ($null -eq $statusBefore.ModelProvider)
  }
  Write-TextFileUtf8 -Path $paths.StatePath -Content (($state | ConvertTo-Json -Depth 4) + "`n")

  return [pscustomobject]@{
    State = "Fixed"
    BackupPath = $backupPath
    ConfigPath = $paths.ConfigPath
    StatePath = $paths.StatePath
  }
}

function Rollback-CodexConnectionFix {
  param([string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"))

  $paths = Get-CodexConnectionFixerPaths -CodexHome $CodexHome
  if (-not [System.IO.File]::Exists($paths.StatePath)) {
    return [pscustomobject]@{
      State = "NoState"
      Message = "No fixer state file exists. Automatic rollback will not guess a backup."
      BackupDir = $paths.BackupDir
    }
  }

  $state = Read-TextFileUtf8 -Path $paths.StatePath | ConvertFrom-Json
  $backupPath = [string]$state.backupPath
  if (-not [System.IO.File]::Exists($backupPath)) {
    return [pscustomobject]@{
      State = "MissingBackup"
      Message = "The recorded backup file does not exist."
      BackupPath = $backupPath
    }
  }

  $backupContent = Read-TextFileUtf8 -Path $backupPath
  Write-TextFileUtf8 -Path $paths.ConfigPath -Content $backupContent

  return [pscustomobject]@{
    State = "RolledBack"
    BackupPath = $backupPath
    ConfigPath = $paths.ConfigPath
  }
}

function Format-CodexConnectionStatusText {
  param([Parameter(Mandatory = $true)]$Status)

  $modelProvider = if ($null -eq $Status.ModelProvider -or [string]::IsNullOrWhiteSpace([string]$Status.ModelProvider)) {
    "(not set)"
  } else {
    [string]$Status.ModelProvider
  }

  return (@(
    "State: $($Status.State)"
    "Config: $($Status.ConfigPath)"
    "model_provider: $modelProvider"
    "HTTP provider table: $($Status.HasHttpProviderTable)"
    "WebSockets disabled: $($Status.SupportsWebsocketsFalse)"
    "Rollback available: $($Status.RollbackAvailable)"
  ) -join [Environment]::NewLine)
}

function Add-CodexConnectionFixerLog {
  param(
    [Parameter(Mandatory = $true)]$TextBox,
    [Parameter(Mandatory = $true)][string]$Message
  )

  $line = "[{0}] {1}{2}" -f (Get-Date -Format "HH:mm:ss"), $Message, [Environment]::NewLine
  $TextBox.AppendText($line)
}

function Start-CodexConnectionFixerGui {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  [System.Windows.Forms.Application]::EnableVisualStyles()

  $form = New-Object System.Windows.Forms.Form
  $form.Text = "Codex Connection Fixer"
  $form.StartPosition = "CenterScreen"
  $form.Size = New-Object System.Drawing.Size(720, 460)
  $form.MinimumSize = New-Object System.Drawing.Size(680, 420)

  $titleLabel = New-Object System.Windows.Forms.Label
  $titleLabel.Text = "Fix Codex WebSocket reconnect delay"
  $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
  $titleLabel.AutoSize = $true
  $titleLabel.Location = New-Object System.Drawing.Point(16, 16)
  $form.Controls.Add($titleLabel)

  $description = New-Object System.Windows.Forms.Label
  $description.Text = "Run Fix selects an HTTP-only Codex provider. Rollback restores the last backup created by this tool."
  $description.Font = New-Object System.Drawing.Font("Segoe UI", 9)
  $description.AutoSize = $true
  $description.Location = New-Object System.Drawing.Point(18, 48)
  $form.Controls.Add($description)

  $statusBox = New-Object System.Windows.Forms.TextBox
  $statusBox.Location = New-Object System.Drawing.Point(20, 78)
  $statusBox.Size = New-Object System.Drawing.Size(660, 118)
  $statusBox.Multiline = $true
  $statusBox.ReadOnly = $true
  $statusBox.ScrollBars = "Vertical"
  $statusBox.Font = New-Object System.Drawing.Font("Consolas", 9)
  $form.Controls.Add($statusBox)

  $detectButton = New-Object System.Windows.Forms.Button
  $detectButton.Text = "Detect Status"
  $detectButton.Location = New-Object System.Drawing.Point(20, 212)
  $detectButton.Size = New-Object System.Drawing.Size(140, 34)
  $form.Controls.Add($detectButton)

  $runButton = New-Object System.Windows.Forms.Button
  $runButton.Text = "Run Fix"
  $runButton.Location = New-Object System.Drawing.Point(174, 212)
  $runButton.Size = New-Object System.Drawing.Size(140, 34)
  $form.Controls.Add($runButton)

  $rollbackButton = New-Object System.Windows.Forms.Button
  $rollbackButton.Text = "Rollback"
  $rollbackButton.Location = New-Object System.Drawing.Point(328, 212)
  $rollbackButton.Size = New-Object System.Drawing.Size(140, 34)
  $form.Controls.Add($rollbackButton)

  $openFolderButton = New-Object System.Windows.Forms.Button
  $openFolderButton.Text = "Open Config Folder"
  $openFolderButton.Location = New-Object System.Drawing.Point(482, 212)
  $openFolderButton.Size = New-Object System.Drawing.Size(160, 34)
  $form.Controls.Add($openFolderButton)

  $logBox = New-Object System.Windows.Forms.TextBox
  $logBox.Location = New-Object System.Drawing.Point(20, 264)
  $logBox.Size = New-Object System.Drawing.Size(660, 148)
  $logBox.Multiline = $true
  $logBox.ReadOnly = $true
  $logBox.ScrollBars = "Vertical"
  $logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
  $form.Controls.Add($logBox)

  $refreshStatus = {
    try {
      $status = Get-CodexConnectionFixerStatus
      $statusBox.Text = Format-CodexConnectionStatusText -Status $status
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Status refreshed: $($status.State)"
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Status check failed: $($_.Exception.Message)"
    }
  }

  $detectButton.Add_Click($refreshStatus)

  $runButton.Add_Click({
    try {
      $result = Apply-CodexConnectionFix
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Fix applied. Backup: $($result.BackupPath)"
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Restart Codex and check whether Reconnecting repeats."
      & $refreshStatus
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Run Fix failed: $($_.Exception.Message)"
    }
  })

  $rollbackButton.Add_Click({
    try {
      $result = Rollback-CodexConnectionFix
      if ($result.State -eq "RolledBack") {
        Add-CodexConnectionFixerLog -TextBox $logBox -Message "Rollback completed from: $($result.BackupPath)"
        Add-CodexConnectionFixerLog -TextBox $logBox -Message "Restart Codex after rollback."
      } elseif ($result.State -eq "NoState") {
        Add-CodexConnectionFixerLog -TextBox $logBox -Message $result.Message
        if ([System.IO.Directory]::Exists($result.BackupDir)) {
          Start-Process explorer.exe $result.BackupDir
        }
      } else {
        Add-CodexConnectionFixerLog -TextBox $logBox -Message "Rollback did not complete: $($result.Message)"
      }
      & $refreshStatus
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Rollback failed: $($_.Exception.Message)"
    }
  })

  $openFolderButton.Add_Click({
    try {
      $paths = Get-CodexConnectionFixerPaths
      New-Item -ItemType Directory -Force $paths.CodexHome | Out-Null
      Start-Process explorer.exe $paths.CodexHome
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Opened config folder."
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "Open folder failed: $($_.Exception.Message)"
    }
  })

  $form.Add_Shown($refreshStatus)
  [void]$form.ShowDialog()
}

if ($env:CODEX_CONNECTION_FIXER_NO_GUI -ne "1") {
  Start-CodexConnectionFixerGui
}
