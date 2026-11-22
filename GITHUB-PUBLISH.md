# 发布到 GitHub 用的现成内容

这个文件是给"把这套东西发出去"准备的材料：仓库结构、Release 说明、给上游的 Issue 模板、以及提交命令。

---

## 1. 仓库结构

```
translucenttb-26300-fix/
├─ README.md                       # 门面：症状 + 一键修复 + 验证结果
├─ REPORT.md                       # 完整排查报告（证据/对照实验/根因）
├─ Fix-RollbackUpdate.ps1          # 一键修复：卸载出问题的累积更新 + 重启后自动验证
├─ Repair-TranslucentTB.ps1        # 诊断/无损修复 + 效果自检
├─ Test-TaskbarAccent.ps1          # 洋红自检：TBTB 到底有没有在给任务栏上色
├─ Verify-AfterReboot.ps1          # 重启后一次性验证（登录任务调用）
└─ GITHUB-PUBLISH.md               # 本文件
```

## 2. 仓库名 / 简介

- 仓库名建议：`translucenttb-win11-26300-fix`
- 描述：`TranslucentTB 在 Windows 26H2 build 26300.10075 更新后不透明 —— 根因定位 + 一键回滚修复（已实测）`

## 3. Release v1.0.0 说明（中文）

```markdown
## 修复：Windows 26H2 (build 26300.10075) 更新后 TranslucentTB 不生效

### 症状
更新并重启后任务栏恢复成系统默认不透明深色；TranslucentTB 托盘图标在、进程正常、
配置仍是 `clear`，但改什么都不生效。重启 TBTB / 重启 explorer / 重置包均无效。

### 根因
26300.10075 这次累积更新（KB5132057，包 `Package_for_RollupFix~…~26100.10075.1.25`）
之后，shell 不再和 TranslucentTB 的接管层交互：
- TBTB 进程、自启(StartupTask)、配置读写、`ExplorerTAP.dll` 注入 explorer 全部正常；
- trace 日志中从未出现"把任务栏插入 monitor / 下发外观"；
- 对照组：手工 `SetWindowCompositionAttribute` 给 `Shell_TrayWnd` 上色仍然有效（46,48,48 → 73,51,75），
  说明系统合成没坏，坏的是 TBTB 与 shell 之间的接管链路；
- `SFC` / `DISM` 均判系统健康，排除文件损坏。

### 修复（已在本机验证）
卸载该累积更新并重启，回到 26100.9974：

dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart

或一键：`powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest`

### 验证
洋红自检（把桌面外观临时改成不透明洋红，比对任务栏像素）：

| | 修复前 | 修复后 |
|---|---|---|
| OS | 26300.10075 | 26300.9974 |
| 自检 delta | 0 | 114 |
| 结果 | RESULT: FAIL | RESULT: PASS |
| 任务栏 | 不透明 | 透明（像素 79,84,102，透出壁纸） |

### 环境
Windows 10 Pro 26H2 / TranslucentTB 2026.2.0 / 单显示器 1920×1080 / 深色主题
```

## 4. Release v1.0.0 notes (English)

```markdown
## Fix: TranslucentTB stops working after Windows 26H2 build 26300.10075

### Symptom
After the update the taskbar is back to the stock opaque look. TranslucentTB keeps running,
its MSIX StartupTask is enabled, its config still says `accent: "clear"`, and `ExplorerTAP.dll`
is injected into explorer.exe - yet nothing is applied. Restarting TBTB / explorer and
resetting the package does not help.

### Root cause
On build 26300.10075 (KB5132057, package `Package_for_RollupFix~...~26100.10075.1.25`) the
shell no longer talks to TranslucentTB's taskbar hook layer. A manual
`SetWindowCompositionAttribute` on `Shell_TrayWnd` still works (46,48,48 -> 73,51,75), so the
compositor is fine and the hook chain is what is dead. SFC and DISM report a healthy image.

### Fix (verified on the machine)
Remove that cumulative update and reboot (back to 26100.9974):

dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart

One-liner: `powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest`

### Verification
A magenta paint self-test (temporarily set the desktop appearance to opaque magenta and compare
taskbar pixels): delta 0 -> 114, `RESULT: FAIL` -> `RESULT: PASS`, taskbar transparent again.
```

## 5. 给上游的 Issue 模板（英文，可直接贴）

```markdown
**Environment**
- Windows 10 Pro, DisplayVersion 26H2, build 26300.10075 (KB5132057 installed 2026-11-22)
- TranslucentTB 2026.2.0 (MSIX, 28017CharlesMilette.TranslucentTB_2026.2.0.0_x64__v826wp6bftszj)
- Single 1920x1080 monitor, dark theme, EnableTransparency=1

**Summary**
After installing the cumulative update above, TranslucentTB never applies any taskbar appearance.
Reverting the update (back to build 26100.9974) restores normal behaviour immediately.

**What is still working**
- process running, StartupTask State=2 (enabled)
- config read from %LOCALAPPDATA%\Packages\<PFN>\RoamingState\settings.json (accent "clear")
- ExplorerTAP.dll injected into explorer.exe (loaded from the package TempState folder)
- WinEvent hooks fire (taskbar create/destroy, foreground changes are logged)

**What is broken**
- with verbosity "trace" the log never contains a taskbar insertion / appearance application
- setting desktop_appearance to opaque magenta and restarting TBTB changes nothing
  (taskbar pixel average identical: 48,50,53 before and after; delta = 0)
- log also shows: `window.cpp:181 Verifying if a window is on the current virtual desktop
  failed. (0x80040154: Class not registered)` and `trayicon.cpp:55 Failed to notify shell.`

**Control experiment**
Calling user32!SetWindowCompositionAttribute on Shell_TrayWnd manually from a test process DOES
change the taskbar (46,48,48 -> 73,51,75), so the compositor/accent path is fine on this build.
SFC /scannow and DISM /ScanHealth report no corruption.

**After reverting the update (build 26100.9974)**
The same magenta self-test reports delta = 114 and the taskbar is transparent again.

Logs and the self-test script are attached.
```

## 6. 提交命令（自己执行，确认没问题再 push）

```powershell
cd D:\库\Documents\deepseek-harness\default-workspace\translucenttb-fix
git init
git add .
git commit -m "Fix: TranslucentTB not applied on Windows 26H2 build 26300.10075 (rollback KB5132057, verified)"
git branch -M main
git remote add origin https://github.com/<you>/translucenttb-win11-26300-fix.git
git push -u origin main
```

打 tag / 发 Release：

```powershell
git tag -a v1.0.0 -m "v1.0.0 verified fix"
git push origin v1.0.0
# 然后在 GitHub 上 New release -> 选择 tag v1.0.0 -> 粘贴第 3/4 节内容
```
