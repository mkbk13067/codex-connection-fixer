param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "dist"),
  [string]$Version = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CscPath {
  $candidates = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
  )

  foreach ($candidate in $candidates) {
    if ([System.IO.File]::Exists($candidate)) {
      return $candidate
    }
  }

  throw "Could not find .NET Framework csc.exe. This build requires Windows with .NET Framework 4.x."
}

function Get-FixerVersion {
  param([Parameter(Mandatory = $true)][string]$ScriptPath)

  $content = [System.IO.File]::ReadAllText($ScriptPath, [System.Text.Encoding]::UTF8)
  if ($content -match '\$script:FixerVersion\s*=\s*"([^"]+)"') {
    return $Matches[1]
  }

  throw "Could not read FixerVersion from CodexConnectionFixer.ps1."
}

function ConvertTo-CSharpStringLiteral {
  param([Parameter(Mandatory = $true)][string]$Value)

  return $Value.Replace("\", "\\").Replace('"', '\"')
}

$scriptPath = Join-Path $PSScriptRoot "CodexConnectionFixer.ps1"
if ([string]::IsNullOrWhiteSpace($Version)) {
  $Version = Get-FixerVersion -ScriptPath $scriptPath
}

New-Item -ItemType Directory -Force $OutputDir | Out-Null

$escapedVersion = ConvertTo-CSharpStringLiteral -Value $Version
$sourcePath = Join-Path $OutputDir "CodexConnectionFixerApp.cs"
$exePath = Join-Path $OutputDir "CodexConnectionFixer-$Version.exe"
$shaPath = "$exePath.sha256.txt"

$csharp = @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;

internal static class Program
{
    private const string Version = "$escapedVersion";
    private const string Fixed = "\u5df2\u4fee\u590d";
    private const string NotFixed = "\u672a\u4fee\u590d";
    private const string Incomplete = "\u914d\u7f6e\u4e0d\u5b8c\u6574";

    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }

    private sealed class MainForm : Form
    {
        private readonly TextBox statusBox;
        private readonly TextBox logBox;

        internal MainForm()
        {
            Text = "Codex \u8fde\u63a5\u4fee\u590d\u5668";
            StartPosition = FormStartPosition.CenterScreen;
            Width = 760;
            Height = 500;
            MinimumSize = new System.Drawing.Size(700, 430);

            Label title = new Label();
            title.Text = "\u4fee\u590d Codex \u53cd\u590d\u91cd\u8fde\u95ee\u9898";
            title.Font = new System.Drawing.Font("Microsoft YaHei UI", 14, System.Drawing.FontStyle.Bold);
            title.AutoSize = true;
            title.Left = 18;
            title.Top = 16;
            Controls.Add(title);

            Label description = new Label();
            description.Text = "\u8fd0\u884c\u4fee\u590d\u4f1a\u5207\u6362\u5230 HTTP-only Provider\uff1b\u56de\u6eda\u4f1a\u6062\u590d\u672c\u5de5\u5177\u521b\u5efa\u7684\u5907\u4efd\u3002";
            description.Font = new System.Drawing.Font("Microsoft YaHei UI", 9);
            description.AutoSize = true;
            description.Left = 20;
            description.Top = 52;
            Controls.Add(description);

            statusBox = new TextBox();
            statusBox.Left = 20;
            statusBox.Top = 82;
            statusBox.Width = 690;
            statusBox.Height = 125;
            statusBox.Multiline = true;
            statusBox.ReadOnly = true;
            statusBox.ScrollBars = ScrollBars.Vertical;
            statusBox.Font = new System.Drawing.Font("Consolas", 9);
            Controls.Add(statusBox);

            Button detect = NewButton("\u68c0\u6d4b\u5f53\u524d\u72b6\u6001", 20, 224, 150);
            detect.Click += delegate { RefreshStatus(); };

            Button run = NewButton("\u8fd0\u884c\u4fee\u590d", 182, 224, 140);
            run.Click += delegate { RunFix(); };

            Button rollback = NewButton("\u56de\u6eda\u4fee\u590d", 334, 224, 140);
            rollback.Click += delegate { RollbackFix(); };

            Button open = NewButton("\u6253\u5f00\u914d\u7f6e\u76ee\u5f55", 486, 224, 170);
            open.Click += delegate { OpenConfigFolder(); };

            logBox = new TextBox();
            logBox.Left = 20;
            logBox.Top = 274;
            logBox.Width = 690;
            logBox.Height = 150;
            logBox.Multiline = true;
            logBox.ReadOnly = true;
            logBox.ScrollBars = ScrollBars.Vertical;
            logBox.Font = new System.Drawing.Font("Consolas", 9);
            Controls.Add(logBox);

            Shown += delegate { RefreshStatus(); };
        }

        private Button NewButton(string text, int left, int top, int width)
        {
            Button button = new Button();
            button.Text = text;
            button.Left = left;
            button.Top = top;
            button.Width = width;
            button.Height = 34;
            Controls.Add(button);
            return button;
        }

        private void RefreshStatus()
        {
            try
            {
                ConfigStatus status = ConfigStore.GetStatus();
                statusBox.Text = FormatStatus(status);
                Log("\u72b6\u6001\u5df2\u5237\u65b0\uff1a" + LabelForState(status.State));
            }
            catch (Exception ex)
            {
                Log("\u72b6\u6001\u68c0\u67e5\u5931\u8d25\uff1a" + ex.Message);
            }
        }

        private void RunFix()
        {
            try
            {
                ApplyResult result = ConfigStore.ApplyFix();
                Log("\u4fee\u590d\u5df2\u5b8c\u6210\u3002\u5907\u4efd\uff1a" + result.BackupPath);
                Log("\u8bf7\u91cd\u542f Codex\uff0c\u5e76\u68c0\u67e5\u662f\u5426\u8fd8\u4f1a\u53cd\u590d Reconnecting\u3002");
                RefreshStatus();
            }
            catch (Exception ex)
            {
                Log("\u8fd0\u884c\u4fee\u590d\u5931\u8d25\uff1a" + ex.Message);
            }
        }

        private void RollbackFix()
        {
            try
            {
                RollbackResult result = ConfigStore.Rollback();
                if (result.State == "RolledBack")
                {
                    Log("\u56de\u6eda\u5df2\u5b8c\u6210\uff0c\u6765\u6e90\uff1a" + result.BackupPath);
                    Log("\u56de\u6eda\u540e\u8bf7\u91cd\u542f Codex\u3002");
                }
                else if (result.State == "NoState")
                {
                    Log("\u6ca1\u6709\u4fee\u590d\u5668\u72b6\u6001\u6587\u4ef6\uff1b\u4e0d\u4f1a\u731c\u6d4b\u8981\u6062\u590d\u54ea\u4e2a\u5907\u4efd\u3002");
                    if (Directory.Exists(result.BackupDir))
                    {
                        Process.Start("explorer.exe", result.BackupDir);
                    }
                }
                else
                {
                    Log("\u56de\u6eda\u672a\u5b8c\u6210\uff1a" + result.Message);
                }
                RefreshStatus();
            }
            catch (Exception ex)
            {
                Log("\u56de\u6eda\u5931\u8d25\uff1a" + ex.Message);
            }
        }

        private void OpenConfigFolder()
        {
            try
            {
                Paths paths = Paths.GetDefault();
                Directory.CreateDirectory(paths.CodexHome);
                Process.Start("explorer.exe", paths.CodexHome);
                Log("\u5df2\u6253\u5f00\u914d\u7f6e\u76ee\u5f55\u3002");
            }
            catch (Exception ex)
            {
                Log("\u6253\u5f00\u76ee\u5f55\u5931\u8d25\uff1a" + ex.Message);
            }
        }

        private string FormatStatus(ConfigStatus status)
        {
            string provider = String.IsNullOrWhiteSpace(status.ModelProvider) ? "\u672a\u8bbe\u7f6e" : status.ModelProvider;
            return "\u72b6\u6001\uff1a" + LabelForState(status.State) + Environment.NewLine
                + "\u914d\u7f6e\uff1a" + status.ConfigPath + Environment.NewLine
                + "model_provider: " + provider + Environment.NewLine
                + "HTTP Provider \u8868\uff1a" + status.HasHttpProviderTable + Environment.NewLine
                + "WebSocket \u5df2\u7981\u7528\uff1a" + status.SupportsWebsocketsFalse + Environment.NewLine
                + "\u53ef\u56de\u6eda\uff1a" + status.RollbackAvailable;
        }

        private string LabelForState(string state)
        {
            if (state == "Fixed") return Fixed;
            if (state == "Not Fixed") return NotFixed;
            if (state == "Incomplete Config") return Incomplete;
            if (state == "RolledBack") return "\u5df2\u56de\u6eda";
            if (state == "NoState") return "\u65e0\u56de\u6eda\u72b6\u6001";
            if (state == "MissingBackup") return "\u5907\u4efd\u7f3a\u5931";
            return state;
        }

        private void Log(string message)
        {
            logBox.AppendText("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + message + Environment.NewLine);
        }
    }

    private sealed class Paths
    {
        internal string CodexHome;
        internal string ConfigPath;
        internal string BackupDir;
        internal string StatePath;

        internal static Paths GetDefault()
        {
            string home = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".codex");
            return new Paths
            {
                CodexHome = home,
                ConfigPath = Path.Combine(home, "config.toml"),
                BackupDir = Path.Combine(home, "backups"),
                StatePath = Path.Combine(home, "codex-connection-fixer-state.json")
            };
        }
    }

    private sealed class ConfigStatus
    {
        internal string State;
        internal string ConfigPath;
        internal bool ConfigExists;
        internal string ModelProvider;
        internal bool HasHttpProviderTable;
        internal bool SupportsWebsocketsFalse;
        internal bool RollbackAvailable;
    }

    private sealed class ApplyResult
    {
        internal string BackupPath;
    }

    private sealed class RollbackResult
    {
        internal string State;
        internal string BackupPath;
        internal string BackupDir;
        internal string Message;
    }

    private static class ConfigStore
    {
        internal static ConfigStatus GetStatus()
        {
            Paths paths = Paths.GetDefault();
            string content = File.Exists(paths.ConfigPath) ? ReadUtf8(paths.ConfigPath) : "";
            TextStatus textStatus = GetTextStatus(content);
            return new ConfigStatus
            {
                State = textStatus.State,
                ConfigPath = paths.ConfigPath,
                ConfigExists = File.Exists(paths.ConfigPath),
                ModelProvider = textStatus.ModelProvider,
                HasHttpProviderTable = textStatus.HasHttpProviderTable,
                SupportsWebsocketsFalse = textStatus.SupportsWebsocketsFalse,
                RollbackAvailable = File.Exists(paths.StatePath)
            };
        }

        internal static ApplyResult ApplyFix()
        {
            Paths paths = Paths.GetDefault();
            Directory.CreateDirectory(paths.CodexHome);
            Directory.CreateDirectory(paths.BackupDir);
            bool existed = File.Exists(paths.ConfigPath);
            string original = existed ? ReadUtf8(paths.ConfigPath) : "";
            string timestamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
            string backupPath = Path.Combine(paths.BackupDir, "config.toml.backup-" + timestamp);
            WriteUtf8(backupPath, original);
            TextStatus before = GetTextStatus(original);
            WriteUtf8(paths.ConfigPath, UpdateConfigText(original));
            string state = "{\n"
                + "  \"fixerVersion\": \"" + EscapeJson(Version) + "\",\n"
                + "  \"timestamp\": \"" + EscapeJson(timestamp) + "\",\n"
                + "  \"backupPath\": \"" + EscapeJson(backupPath) + "\",\n"
                + "  \"backupPathBase64\": \"" + Convert.ToBase64String(Encoding.UTF8.GetBytes(backupPath)) + "\",\n"
                + "  \"configExisted\": " + (existed ? "true" : "false") + ",\n"
                + "  \"previousModelProvider\": \"" + EscapeJson(before.ModelProvider ?? "") + "\"\n"
                + "}\n";
            WriteUtf8(paths.StatePath, state);
            return new ApplyResult { BackupPath = backupPath };
        }

        internal static RollbackResult Rollback()
        {
            Paths paths = Paths.GetDefault();
            if (!File.Exists(paths.StatePath))
            {
                return new RollbackResult { State = "NoState", BackupDir = paths.BackupDir, Message = "No state file." };
            }

            string state = ReadUtf8(paths.StatePath);
            Match match = Regex.Match(state, "\"backupPathBase64\"\\s*:\\s*\"([^\"]+)\"");
            if (!match.Success)
            {
                return new RollbackResult { State = "NoState", BackupDir = paths.BackupDir, Message = "No backup path in state." };
            }

            string backupPath = Encoding.UTF8.GetString(Convert.FromBase64String(match.Groups[1].Value));
            if (!File.Exists(backupPath))
            {
                return new RollbackResult { State = "MissingBackup", BackupPath = backupPath, Message = "Recorded backup is missing." };
            }

            WriteUtf8(paths.ConfigPath, ReadUtf8(backupPath));
            return new RollbackResult { State = "RolledBack", BackupPath = backupPath };
        }

        private sealed class TextStatus
        {
            internal string State;
            internal string ModelProvider;
            internal bool HasHttpProviderTable;
            internal bool SupportsWebsocketsFalse;
        }

        private static TextStatus GetTextStatus(string content)
        {
            List<string> lines = Lines(content);
            int firstTable = FindFirstTable(lines);
            string provider = null;
            int topCount = firstTable < 0 ? lines.Count : firstTable;
            for (int i = 0; i < topCount; i++)
            {
                Match match = Regex.Match(lines[i], "^\\s*model_provider\\s*=\\s*\"([^\"]+)\"");
                if (match.Success)
                {
                    provider = match.Groups[1].Value;
                    break;
                }
            }

            TableRange range = FindTable(lines, "^\\s*\\[model_providers\\.openai_http\\]\\s*$");
            bool websocketFalse = false;
            if (range.Exists)
            {
                for (int i = range.Start + 1; i < range.End; i++)
                {
                    if (Regex.IsMatch(lines[i], "^\\s*supports_websockets\\s*=\\s*false\\s*$"))
                    {
                        websocketFalse = true;
                        break;
                    }
                }
            }

            bool topProvider = provider == "openai_http";
            string state = topProvider && websocketFalse ? "Fixed" : (topProvider || range.Exists || websocketFalse ? "Incomplete Config" : "Not Fixed");
            return new TextStatus
            {
                State = state,
                ModelProvider = provider,
                HasHttpProviderTable = range.Exists,
                SupportsWebsocketsFalse = websocketFalse
            };
        }

        private static string UpdateConfigText(string content)
        {
            List<string> lines = Lines(content);
            lines = SetTopProvider(lines);
            lines = SetProviderTable(lines);
            return lines.Count == 0 ? "" : String.Join("\n", lines.ToArray()) + "\n";
        }

        private static List<string> Lines(string content)
        {
            if (content == null) content = "";
            content = content.TrimStart('\ufeff').Replace("\r\n", "\n").Replace("\r", "\n");
            if (content.Length == 0) return new List<string>();
            List<string> lines = new List<string>(content.Split('\n'));
            if (lines.Count > 0 && lines[lines.Count - 1] == "") lines.RemoveAt(lines.Count - 1);
            return lines;
        }

        private static int FindFirstTable(List<string> lines)
        {
            for (int i = 0; i < lines.Count; i++)
            {
                if (Regex.IsMatch(lines[i], "^\\s*\\[")) return i;
            }
            return -1;
        }

        private sealed class TableRange
        {
            internal bool Exists;
            internal int Start;
            internal int End;
        }

        private static TableRange FindTable(List<string> lines, string pattern)
        {
            int start = -1;
            for (int i = 0; i < lines.Count; i++)
            {
                if (Regex.IsMatch(lines[i], pattern))
                {
                    start = i;
                    break;
                }
            }
            if (start < 0) return new TableRange { Exists = false, Start = -1, End = -1 };
            int end = lines.Count;
            for (int i = start + 1; i < lines.Count; i++)
            {
                if (Regex.IsMatch(lines[i], "^\\s*\\["))
                {
                    end = i;
                    break;
                }
            }
            return new TableRange { Exists = true, Start = start, End = end };
        }

        private static List<string> SetTopProvider(List<string> lines)
        {
            int firstTable = FindFirstTable(lines);
            List<string> top = firstTable < 0 ? new List<string>(lines) : lines.GetRange(0, firstTable);
            List<string> rest = firstTable < 0 ? new List<string>() : lines.GetRange(firstTable, lines.Count - firstTable);
            List<string> result = new List<string>();
            bool written = false;
            foreach (string line in top)
            {
                if (Regex.IsMatch(line, "^\\s*model_provider\\s*="))
                {
                    if (!written)
                    {
                        result.Add("model_provider = \"openai_http\"");
                        written = true;
                    }
                }
                else
                {
                    result.Add(line);
                }
            }
            if (!written)
            {
                int insert = 0;
                for (int i = 0; i < result.Count; i++)
                {
                    if (Regex.IsMatch(result[i], "^\\s*model\\s*=")) insert = i + 1;
                }
                result.Insert(insert, "model_provider = \"openai_http\"");
            }
            result.AddRange(rest);
            return result;
        }

        private static List<string> SetProviderTable(List<string> lines)
        {
            TableRange range = FindTable(lines, "^\\s*\\[model_providers\\.openai_http\\]\\s*$");
            string[] desired = new string[]
            {
                "name = \"OpenAI HTTP only\"",
                "wire_api = \"responses\"",
                "supports_websockets = false"
            };

            if (!range.Exists)
            {
                List<string> result = new List<string>(lines);
                if (result.Count > 0 && result[result.Count - 1].Trim().Length > 0) result.Add("");
                result.Add("[model_providers.openai_http]");
                result.AddRange(desired);
                return result;
            }

            List<string> output = range.Start == 0 ? new List<string>() : lines.GetRange(0, range.Start);
            List<string> section = new List<string>();
            section.Add("[model_providers.openai_http]");
            Dictionary<string, bool> seen = new Dictionary<string, bool>();
            for (int i = range.Start + 1; i < range.End; i++)
            {
                Match match = Regex.Match(lines[i], "^\\s*(name|wire_api|supports_websockets)\\s*=");
                if (match.Success)
                {
                    string key = match.Groups[1].Value;
                    if (!seen.ContainsKey(key))
                    {
                        if (key == "name") section.Add(desired[0]);
                        if (key == "wire_api") section.Add(desired[1]);
                        if (key == "supports_websockets") section.Add(desired[2]);
                        seen[key] = true;
                    }
                }
                else
                {
                    section.Add(lines[i]);
                }
            }
            if (!seen.ContainsKey("name")) section.Add(desired[0]);
            if (!seen.ContainsKey("wire_api")) section.Add(desired[1]);
            if (!seen.ContainsKey("supports_websockets")) section.Add(desired[2]);
            output.AddRange(section);
            if (range.End < lines.Count) output.AddRange(lines.GetRange(range.End, lines.Count - range.End));
            return output;
        }

        private static string ReadUtf8(string path)
        {
            return File.ReadAllText(path, Encoding.UTF8);
        }

        private static void WriteUtf8(string path, string content)
        {
            string dir = Path.GetDirectoryName(path);
            if (!String.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
            File.WriteAllText(path, content ?? "", Encoding.UTF8);
        }

        private static string EscapeJson(string value)
        {
            if (value == null) return "";
            return value.Replace("\\", "\\\\").Replace("\"", "\\\"");
        }
    }
}
"@

[System.IO.File]::WriteAllText($sourcePath, $csharp, [System.Text.Encoding]::UTF8)

$csc = Get-CscPath
$arguments = @(
  "/nologo",
  "/target:winexe",
  "/optimize+",
  "/platform:anycpu",
  "/reference:System.Windows.Forms.dll",
  "/reference:System.Drawing.dll",
  "/out:$exePath",
  $sourcePath
)

& $csc @arguments
if ($LASTEXITCODE -ne 0) {
  throw "csc.exe failed with exit code $LASTEXITCODE."
}

if (-not [System.IO.File]::Exists($exePath)) {
  throw "csc.exe completed but did not create $exePath."
}

$hash = Get-FileHash -Algorithm SHA256 -Path $exePath
$checksumText = "$($hash.Hash.ToLowerInvariant())  $(Split-Path -Leaf $exePath)`n"
[System.IO.File]::WriteAllText($shaPath, $checksumText, [System.Text.Encoding]::UTF8)

Remove-Item -LiteralPath $sourcePath -Force -ErrorAction SilentlyContinue

[pscustomobject]@{
  Version = $Version
  ExePath = $exePath
  Sha256Path = $shaPath
  Sha256 = $hash.Hash.ToLowerInvariant()
}
