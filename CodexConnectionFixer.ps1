Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:FixerVersion = "1.0.0"

function New-CodexFixerString {
  param([Parameter(Mandatory = $true)][int[]]$CodePoints)

  $characters = foreach ($codePoint in $CodePoints) {
    [char]$codePoint
  }
  return (-join $characters)
}

function Get-CodexConnectionFixerUiText {
  return [pscustomobject]@{
    WindowTitle = "Codex " + (New-CodexFixerString -CodePoints @(0x8FDE, 0x63A5, 0x4FEE, 0x590D, 0x5668))
    Title = (New-CodexFixerString -CodePoints @(0x4FEE, 0x590D)) + " Codex " + (New-CodexFixerString -CodePoints @(0x53CD, 0x590D, 0x91CD, 0x8FDE, 0x95EE, 0x9898))
    Description = (New-CodexFixerString -CodePoints @(0x8FD0, 0x884C, 0x4FEE, 0x590D, 0x4F1A, 0x5207, 0x6362, 0x5230)) + " HTTP-only Provider" + (New-CodexFixerString -CodePoints @(0xFF1B, 0x56DE, 0x6EDA, 0x4F1A, 0x6062, 0x590D, 0x672C, 0x5DE5, 0x5177, 0x521B, 0x5EFA, 0x7684, 0x5907, 0x4EFD, 0x3002))
    DetectStatus = New-CodexFixerString -CodePoints @(0x68C0, 0x6D4B, 0x5F53, 0x524D, 0x72B6, 0x6001)
    RunFix = New-CodexFixerString -CodePoints @(0x8FD0, 0x884C, 0x4FEE, 0x590D)
    Rollback = New-CodexFixerString -CodePoints @(0x56DE, 0x6EDA, 0x4FEE, 0x590D)
    OpenConfigFolder = New-CodexFixerString -CodePoints @(0x6253, 0x5F00, 0x914D, 0x7F6E, 0x76EE, 0x5F55)
    StateLabel = New-CodexFixerString -CodePoints @(0x72B6, 0x6001, 0xFF1A)
    ConfigLabel = New-CodexFixerString -CodePoints @(0x914D, 0x7F6E, 0xFF1A)
    NotSet = New-CodexFixerString -CodePoints @(0x672A, 0x8BBE, 0x7F6E)
    HttpProviderTableLabel = "HTTP Provider " + (New-CodexFixerString -CodePoints @(0x8868, 0xFF1A))
    WebSocketsDisabledLabel = "WebSocket " + (New-CodexFixerString -CodePoints @(0x5DF2, 0x7981, 0x7528, 0xFF1A))
    RollbackAvailableLabel = New-CodexFixerString -CodePoints @(0x53EF, 0x56DE, 0x6EDA, 0xFF1A)
    Fixed = New-CodexFixerString -CodePoints @(0x5DF2, 0x4FEE, 0x590D)
    NotFixed = New-CodexFixerString -CodePoints @(0x672A, 0x4FEE, 0x590D)
    IncompleteConfig = New-CodexFixerString -CodePoints @(0x914D, 0x7F6E, 0x4E0D, 0x5B8C, 0x6574)
    RolledBack = New-CodexFixerString -CodePoints @(0x5DF2, 0x56DE, 0x6EDA)
    NoState = New-CodexFixerString -CodePoints @(0x65E0, 0x56DE, 0x6EDA, 0x72B6, 0x6001)
    MissingBackup = New-CodexFixerString -CodePoints @(0x5907, 0x4EFD, 0x7F3A, 0x5931)
    StatusRefreshed = New-CodexFixerString -CodePoints @(0x72B6, 0x6001, 0x5DF2, 0x5237, 0x65B0, 0xFF1A)
    FixApplied = New-CodexFixerString -CodePoints @(0x4FEE, 0x590D, 0x5DF2, 0x5B8C, 0x6210, 0x3002, 0x5907, 0x4EFD, 0xFF1A)
    RestartAfterFix = (New-CodexFixerString -CodePoints @(0x8BF7, 0x91CD, 0x542F)) + " Codex" + (New-CodexFixerString -CodePoints @(0xFF0C, 0x5E76, 0x68C0, 0x67E5, 0x662F, 0x5426, 0x8FD8, 0x4F1A, 0x53CD, 0x590D)) + " Reconnecting" + (New-CodexFixerString -CodePoints @(0x3002))
    StatusFailed = New-CodexFixerString -CodePoints @(0x72B6, 0x6001, 0x68C0, 0x67E5, 0x5931, 0x8D25, 0xFF1A)
    NoStateMessage = New-CodexFixerString -CodePoints @(0x6CA1, 0x6709, 0x4FEE, 0x590D, 0x5668, 0x72B6, 0x6001, 0x6587, 0x4EF6, 0xFF1B, 0x4E0D, 0x4F1A, 0x731C, 0x6D4B, 0x8981, 0x6062, 0x590D, 0x54EA, 0x4E2A, 0x5907, 0x4EFD, 0x3002)
    RollbackCompleted = New-CodexFixerString -CodePoints @(0x56DE, 0x6EDA, 0x5DF2, 0x5B8C, 0x6210, 0xFF0C, 0x6765, 0x6E90, 0xFF1A)
    RestartAfterRollback = (New-CodexFixerString -CodePoints @(0x56DE, 0x6EDA, 0x540E, 0x8BF7, 0x91CD, 0x542F)) + " Codex" + (New-CodexFixerString -CodePoints @(0x3002))
    RollbackNotCompleted = New-CodexFixerString -CodePoints @(0x56DE, 0x6EDA, 0x672A, 0x5B8C, 0x6210, 0xFF1A)
    RollbackFailed = New-CodexFixerString -CodePoints @(0x56DE, 0x6EDA, 0x5931, 0x8D25, 0xFF1A)
    FolderOpened = New-CodexFixerString -CodePoints @(0x5DF2, 0x6253, 0x5F00, 0x914D, 0x7F6E, 0x76EE, 0x5F55, 0x3002)
    OpenFolderFailed = New-CodexFixerString -CodePoints @(0x6253, 0x5F00, 0x76EE, 0x5F55, 0x5931, 0x8D25, 0xFF1A)
    RunFixFailed = New-CodexFixerString -CodePoints @(0x8FD0, 0x884C, 0x4FEE, 0x590D, 0x5931, 0x8D25, 0xFF1A)
  }
}

function Convert-CodexConnectionStateLabel {
  param([Parameter(Mandatory = $true)][string]$State)

  $text = Get-CodexConnectionFixerUiText
  switch ($State) {
    "Fixed" { return $text.Fixed }
    "Not Fixed" { return $text.NotFixed }
    "Incomplete Config" { return $text.IncompleteConfig }
    "RolledBack" { return $text.RolledBack }
    "NoState" { return $text.NoState }
    "MissingBackup" { return $text.MissingBackup }
    default { return $State }
  }
}

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

  $text = Get-CodexConnectionFixerUiText
  $modelProvider = if ($null -eq $Status.ModelProvider -or [string]::IsNullOrWhiteSpace([string]$Status.ModelProvider)) {
    $text.NotSet
  } else {
    [string]$Status.ModelProvider
  }
  $stateLabel = Convert-CodexConnectionStateLabel -State ([string]$Status.State)

  return (@(
    "$($text.StateLabel)$stateLabel"
    "$($text.ConfigLabel)$($Status.ConfigPath)"
    "model_provider: $modelProvider"
    "$($text.HttpProviderTableLabel)$($Status.HasHttpProviderTable)"
    "$($text.WebSocketsDisabledLabel)$($Status.SupportsWebsocketsFalse)"
    "$($text.RollbackAvailableLabel)$($Status.RollbackAvailable)"
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
  $text = Get-CodexConnectionFixerUiText
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  [System.Windows.Forms.Application]::EnableVisualStyles()

  $form = New-Object System.Windows.Forms.Form
  $form.Text = $text.WindowTitle
  $form.StartPosition = "CenterScreen"
  $form.Size = New-Object System.Drawing.Size(720, 460)
  $form.MinimumSize = New-Object System.Drawing.Size(680, 420)

  $titleLabel = New-Object System.Windows.Forms.Label
  $titleLabel.Text = $text.Title
  $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
  $titleLabel.AutoSize = $true
  $titleLabel.Location = New-Object System.Drawing.Point(16, 16)
  $form.Controls.Add($titleLabel)

  $description = New-Object System.Windows.Forms.Label
  $description.Text = $text.Description
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
  $detectButton.Text = $text.DetectStatus
  $detectButton.Location = New-Object System.Drawing.Point(20, 212)
  $detectButton.Size = New-Object System.Drawing.Size(140, 34)
  $form.Controls.Add($detectButton)

  $runButton = New-Object System.Windows.Forms.Button
  $runButton.Text = $text.RunFix
  $runButton.Location = New-Object System.Drawing.Point(174, 212)
  $runButton.Size = New-Object System.Drawing.Size(140, 34)
  $form.Controls.Add($runButton)

  $rollbackButton = New-Object System.Windows.Forms.Button
  $rollbackButton.Text = $text.Rollback
  $rollbackButton.Location = New-Object System.Drawing.Point(328, 212)
  $rollbackButton.Size = New-Object System.Drawing.Size(140, 34)
  $form.Controls.Add($rollbackButton)

  $openFolderButton = New-Object System.Windows.Forms.Button
  $openFolderButton.Text = $text.OpenConfigFolder
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
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.StatusRefreshed)$(Convert-CodexConnectionStateLabel -State ([string]$status.State))"
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.StatusFailed)$($_.Exception.Message)"
    }
  }

  $detectButton.Add_Click($refreshStatus)

  $runButton.Add_Click({
    try {
      $result = Apply-CodexConnectionFix
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.FixApplied)$($result.BackupPath)"
      Add-CodexConnectionFixerLog -TextBox $logBox -Message $text.RestartAfterFix
      & $refreshStatus
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.RunFixFailed)$($_.Exception.Message)"
    }
  })

  $rollbackButton.Add_Click({
    try {
      $result = Rollback-CodexConnectionFix
      if ($result.State -eq "RolledBack") {
        Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.RollbackCompleted)$($result.BackupPath)"
        Add-CodexConnectionFixerLog -TextBox $logBox -Message $text.RestartAfterRollback
      } elseif ($result.State -eq "NoState") {
        Add-CodexConnectionFixerLog -TextBox $logBox -Message $text.NoStateMessage
        if ([System.IO.Directory]::Exists($result.BackupDir)) {
          Start-Process explorer.exe $result.BackupDir
        }
      } else {
        Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.RollbackNotCompleted)$($result.Message)"
      }
      & $refreshStatus
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.RollbackFailed)$($_.Exception.Message)"
    }
  })

  $openFolderButton.Add_Click({
    try {
      $paths = Get-CodexConnectionFixerPaths
      New-Item -ItemType Directory -Force $paths.CodexHome | Out-Null
      Start-Process explorer.exe $paths.CodexHome
      Add-CodexConnectionFixerLog -TextBox $logBox -Message $text.FolderOpened
    } catch {
      Add-CodexConnectionFixerLog -TextBox $logBox -Message "$($text.OpenFolderFailed)$($_.Exception.Message)"
    }
  })

  $form.Add_Shown($refreshStatus)
  [void]$form.ShowDialog()
}

if ($env:CODEX_CONNECTION_FIXER_NO_GUI -ne "1") {
  Start-CodexConnectionFixerGui
}
