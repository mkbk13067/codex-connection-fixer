# Codex 连接修复器

一个 Windows 小工具，用来解决部分网络或代理环境下 Codex 启动前反复 `Reconnecting`、等待很久才开始响应的问题。

它会把 Codex 配置切换到 HTTP-only Provider，避开不稳定的 WebSocket 通道；所有修改都会先备份，并支持一键回滚。

## 直接下载运行

普通用户不需要下载源码。

Release 下载页：<https://github.com/mkbk13067/codex-connection-fixer/releases/latest>

1. 打开 GitHub Release 页面。
2. 下载最新版本里的 `CodexConnectionFixer-版本号.exe`，例如 `CodexConnectionFixer-1.0.0.exe`。
3. 双击运行这个 exe。
4. 点击 `运行修复`。
5. 重启 Codex。

如果想撤销修改，再次打开 exe，点击 `回滚修复`，然后重启 Codex。

## 适用场景

适合这些情况：

- Codex 每次开始前都会多次显示 `Reconnecting`。
- 网络、代理或 VPN 对 WebSocket 支持不稳定。
- 等待多次重连后 Codex 才开始思考。

不适合这些情况：

- Codex 没有登录。
- API 或账号权限不可用。
- GitHub、代理、DNS、防火墙需要单独配置。
- 其他与 WebSocket fallback 无关的启动慢问题。

## 它会修改什么

目标文件：

```text
%USERPROFILE%\.codex\config.toml
```

运行修复前会创建备份：

```text
%USERPROFILE%\.codex\backups\config.toml.backup-YYYYMMDD-HHMMSS
```

修复器会设置顶层 provider：

```toml
model_provider = "openai_http"
```

并确保存在 HTTP-only provider：

```toml
[model_providers.openai_http]
name = "OpenAI HTTP only"
wire_api = "responses"
supports_websockets = false
```

它会保留原有的 model、plugin、project trust、notify 等其他配置。

## 回滚

修复器会记录最近一次备份：

```text
%USERPROFILE%\.codex\codex-connection-fixer-state.json
```

点击 `回滚修复` 会恢复这份备份。  
如果状态文件不存在，工具不会猜测要恢复哪一个备份，避免误覆盖用户配置。

## 界面按钮

- `检测当前状态`：只检查配置，不修改文件。
- `运行修复`：备份配置并写入 HTTP-only Provider。
- `回滚修复`：恢复本工具记录的最近一次备份。
- `打开配置目录`：打开 `%USERPROFILE%\.codex`。

## 从源码运行

如果你不想用 exe，也可以运行脚本版本：

```text
Run-CodexConnectionFixer.vbs
```

备用入口：

```text
Run-CodexConnectionFixer.bat
```

也可以在 PowerShell 中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\CodexConnectionFixer.ps1
```

## 构建 Release 版 exe

在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1 -Version 1.0.0
```

输出文件：

```text
dist\CodexConnectionFixer-1.0.0.exe
dist\CodexConnectionFixer-1.0.0.exe.sha256.txt
```

`CodexConnectionFixer.exe` 是一个无控制台窗口的 Windows GUI 程序。发布页里的实际文件名会带版本号；用户只需要下载 exe 并双击运行。

## 测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Test-CodexConnectionFixer.ps1
```

期望结果：

```text
All Codex Connection Fixer tests passed.
```

## 常见问题

### 为什么会被 Windows 提醒未知发布者？

当前 exe 没有代码签名。Windows SmartScreen 可能会提醒未知发布者，这是未签名开源工具的常见表现。你可以从 Release 页面下载，并对照 `.sha256.txt` 校验文件。

### 修复后仍然反复重连怎么办？

1. 完全重启 Codex。
2. 再次打开工具，点击 `检测当前状态`。
3. 确认状态为 `已修复`。
4. 如果仍有问题，点击 `回滚修复`，并检查你的代理/VPN 是否支持 Codex 所需连接。

### 回滚失败怎么办？

1. 点击 `打开配置目录`。
2. 打开 `backups` 文件夹。
3. 找到要恢复的 `config.toml.backup-*`。
4. 手动复制为 `%USERPROFILE%\.codex\config.toml`。
