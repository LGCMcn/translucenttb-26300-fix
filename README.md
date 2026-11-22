# TranslucentTB 更新后任务栏不透明 · 已定位并修复（Windows 26H2 build 26300.10075）

# TranslucentTB taskbar transparency broke after a Windows update · root cause + verified fix (Windows 26H2 build 26300.10075)

> **中文**：装完 `KB5132057`（build 26300.10075）后，TranslucentTB 2026.2.0 完全失效 —— 进程在、配置对、`ExplorerTAP.dll` 也注入进去了，但任务栏永远不透明。**回滚这版更新、重启，立刻恢复**（本机已实测）。
>
> **English**: After installing KB5132057 (build 26300.10075), TranslucentTB 2026.2.0 stops working entirely — process alive, config correct, `ExplorerTAP.dll` injected, yet the taskbar is never styled. **Rolling back that cumulative update and rebooting fixes it** (verified on the machine).

配套视频：`media/ttb-26300-fix.mp4`（1920×1080 / 30fps / **102 秒** / 中文配音 + 背景音效，含"怎么用"四步演示）· 投稿文案见 [`BILIBILI-POST.md`](BILIBILI-POST.md)

| 时间 | 内容 | Time | Content |
|---|---|---|---|
| 00:00 | 更新后任务栏美化全废 | 00:00 | The update kills your taskbar mod |
| 00:04 | 症状：进程在、配置对、就是不生效 | 00:04 | Symptom: process alive, config right, no effect |
| 00:19 | 逐项排除：全都正常 | 00:19 | Rule out everything: all green |
| 00:37 | 根因：shell 不再和接管层对话 | 00:37 | Root cause: the shell stops talking to the hook layer |
| **00:53** | **怎么用：四步搞定** | **00:53** | **How to use: 4 steps** |
| 01:18 | 一键命令 | 01:18 | One-line command |
| 01:26 | 修复后验证 | 01:26 | Verification after the fix |
| 01:33 | 避坑三件事 | 01:33 | Three takeaways |


---

## TL;DR

```powershell
# 管理员 PowerShell，在本仓库目录执行
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest   # 卸载出问题的累积更新
Restart-Computer                                                            # 重启（DISM 退出码 3010 = 成功，需重启）
```

---

## 1. 症状 / Symptom

| 中文 | English |
|---|---|
| 任务栏恢复成系统默认的不透明深色 | The taskbar falls back to the stock opaque look |
| TBTB 托盘图标在、进程正常、`StartupTask` 已启用 | Tray icon present, process healthy, `StartupTask` enabled |
| 配置仍是 `accent: "clear"`，但改什么都没反应 | Config still says `accent: "clear"`, yet nothing changes |
| 重启 TBTB / 重启 explorer / 重置包 → 全无效 | Restarting TBTB / explorer, resetting the package → no effect |

## 2. 根因 / Root cause

| 中文 | English |
|---|---|
| 不是配置、不是自启、不是透明效果被关、不是包损坏；`SFC` / `DISM` 都判系统健康 | Not config, not autostart, not the transparency toggle, not a broken package; SFC and DISM report a healthy image |
| `ExplorerTAP.dll` 已注入 explorer，WinEvent 钩子也在工作 | `ExplorerTAP.dll` is injected into explorer and WinEvent hooks do fire |
| 但 trace 日志里**从来没有**"把任务栏插入 monitor / 下发外观"这一步 | But the trace log **never** shows a taskbar being inserted or an appearance being applied |
| 对照组：手工 `SetWindowCompositionAttribute` 给 `Shell_TrayWnd` 上洋红 → 任务栏**会**变色（46,48,48 → 73,51,75） | Control test: calling `SetWindowCompositionAttribute` on `Shell_TrayWnd` ourselves **does** change it (46,48,48 → 73,51,75) |
| 结论：**这一版 shell 不再和 TBTB 的接管层对话**，用户态绕不过去 | Conclusion: **this shell build no longer talks to TBTB's hook layer**; it cannot be worked around from userland |

## 3. 一键修复 / One-click fix

**中文**

```powershell
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest
# 或指定包名
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 `
    -PackageName 'Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25'
# 想让它卸载完自动重启，加 -Restart
```

**English**

```powershell
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest
# or specify the package explicitly
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 `
    -PackageName 'Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25'
# add -Restart to reboot automatically after removal
```

不想用脚本 / Prefer raw commands:

```powershell
dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart
# 3010 = success, reboot required
```

## 4. 怎么用（视频里也讲了）/ How to use (also covered in the video)

| # | 中文 | English |
|---|---|---|
| 1 | 打开本仓库，`Code → Download ZIP`（或 `git clone`） | Open this repo, `Code → Download ZIP` (or `git clone`) |
| 2 | **整包解压**到一个文件夹，不要只拖出单个脚本（脚本之间会互相调用） | **Extract the whole folder** — the scripts call each other |
| 3 | 右键 `Fix-RollbackUpdate.ps1` → **使用 PowerShell 运行**（脚本自己提权；窗口别关，卸载要 10–30 分钟） | Right-click `Fix-RollbackUpdate.ps1` → **Run with PowerShell** (self-elevates; keep the window open, removal takes 10–30 min) |
| 4 | 完成后重启；桌面出现 `TBTB-verification.txt`，最后一行 `VERDICT: FIXED` 就成功了 | Reboot; `TBTB-verification.txt` appears on the Desktop — `VERDICT: FIXED` means success |
| 5 | 如果显示 `STILL BROKEN`：跑 `Test-TaskbarAccent.ps1` 自检，把输出贴到 issue | If it says `STILL BROKEN`: run `Test-TaskbarAccent.ps1` and attach the output to an issue |

> 脚本只**卸载更新**，不改任何个性化设置：会先尝试建系统还原点（建不了就跳过），并注册一次性"登录后验证"任务，验证完自删。
>
> The scripts only remove the update. They try to create a restore point first (skipped if unavailable) and register a one-shot logon verification task that deletes itself afterwards.

## 5. 验证数据 / Verification

| | 修复前 / Before | 修复后 / After |
|---|---|---|
| 系统 / OS build | 26H2 **26300.10075** | 26H2 **26300.9974** |
| 洋红自检色差 / magenta self-test delta | **0**（`RESULT: FAIL`） | **114**（`RESULT: PASS`） |
| 任务栏 / taskbar | 不透明深色 / opaque | 透明，像素 73,83,98 ≈ 壁纸 95,84,96 |

自检原理：把 `desktop_appearance` 临时改成不透明洋红 `#FFFF00FF`，重启 TBTB，比对任务栏像素平均色；`delta = 0` 说明它压根没接管。

How the self-test works: temporarily set `desktop_appearance` to opaque magenta, restart TBTB, compare average taskbar pixels. `delta = 0` means nothing is being applied.

## 6. 文件 / Files

| 文件 / File | 用途 / Purpose |
|---|---|
| `Fix-RollbackUpdate.ps1` | 一键卸载出问题的累积更新 / one-click cumulative-update rollback |
| `Test-TaskbarAccent.ps1` | 洋红自检：判断 TBTB 是否真的在给任务栏上色 / magenta paint self-test |
| `Verify-AfterReboot.ps1` | 重启后一次性验证，结果写桌面 / post-reboot verification |
| `Repair-TranslucentTB.ps1` | 诊断 + 无损修复（自启/配置/注入/透明设置）/ diagnose + non-destructive repairs |
| `REPORT.md` | 完整排查报告（全部证据、对照实验）/ full investigation report |
| `GITHUB-PUBLISH.md` | 发布材料（Release notes、issue 模板）/ release notes + issue template |
| `BILIBILI-POST.md` | B 站投稿文案（标题/简介/标签/封面）/ Bilibili upload copy |
| `video/` `media/` | Remotion 源码与成片 / Remotion project and rendered video |

## 7. 注意 / Notes

- 这个 build 的累积更新**装回去就会复发**；在 TBTB 适配或微软修复前建议暂停更新。
  Reinstalling that update brings the bug back — pause updates until TBTB or Microsoft ships a fix.
- 回滚系统更新属于系统维护操作，动手前请先备份重要数据。
  Rolling back a cumulative update is system maintenance — back up your data first.
- 本仓库与 TranslucentTB 官方无关，仅为实测复现与临时解决方案。
  Not affiliated with the TranslucentTB project; this is a reproduction and a stop-gap fix.
