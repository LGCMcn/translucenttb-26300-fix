# TranslucentTB 更新系统后任务栏不透明 —— 已定位并修复（Windows 26H2 / build 26300）

> 实测机器：Windows 10 Pro 26H2，TranslucentTB 2026.2.0
> 结论：**回滚出问题的累积更新 KB5132057 后，TranslucentTB 恢复正常接管任务栏（已在本机验证通过）。**

| 文件 | 用途 |
|---|---|
| `Fix-RollbackUpdate.ps1` | **一键修复**：定位并卸载出问题的累积更新，重启后自动验证 |
| `Repair-TranslucentTB.ps1` | 一键诊断/无损修复（自启、配置、注入、透明设置）+ 效果自检 |
| `Test-TaskbarAccent.ps1` | 效果自检：用"刺眼洋红"判定 TBTB 到底有没有在给任务栏上色 |
| `Verify-AfterReboot.ps1` | 重启后一次性验证，结果写到桌面 `TBTB-verification.txt` |
| [`REPORT.md`](REPORT.md) | 完整排查报告（含全部证据、对照实验、结论） |

## 一键修复

```powershell
# 卸载最新一个累积更新（脚本会自己提权）
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 -Latest

# 或者指定包名
powershell -ExecutionPolicy Bypass -File .\Fix-RollbackUpdate.ps1 `
    -PackageName 'Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25'

# 只在确认问题后想自动重启时加 -Restart
```

脚本行为：`DISM /Remove-Package /NoRestart` → 需要重启时会注册一个"登录时一次性验证"任务 → 你重启 → 桌面生成 `TBTB-verification.txt`（`VERDICT: FIXED` 即成功）。

## 环境与结果

| | 修复前 | 修复后 |
|---|---|---|
| 系统 | Windows 10 Pro 26H2，build **26300.10075** | Windows 10 Pro 26H2，build **26300.9974** |
| 累积更新 | `Package_for_RollupFix~…~26100.10075.1.25`（KB5132057） | 已卸载，回退到 `…26100.9974.1.23` |
| TranslucentTB | 2026.2.0（`28017CharlesMilette.TranslucentTB_2026.2.0.0_x64__v826wp6bftszj`） | 同左 |
| 任务栏 | 不透明深色，改配置无任何反应（自检 delta = **0**） | 透明，自检 delta = **114** |
| 自检结论 | `RESULT: FAIL` | `RESULT: PASS` |

## 症状

更新系统并重启后，任务栏回到系统默认深色不透明；TranslucentTB 托盘图标在、进程正常、配置还是 `clear`，但怎么都不生效。重启 TBTB、重启 explorer、重置包都无效。

## 根因

不是配置、不是自启、不是透明效果被关、不是包损坏、也不是系统文件损坏（`SFC`/`DISM` 都判健康）。

- TBTB 进程、`StartupTask`、配置读写、`ExplorerTAP.dll` 注入 explorer **全部正常**；
- TBTB 的 trace 日志里只看到窗口/任务栏事件，**没有任何一次"把任务栏插入 monitor / 下发外观"**；
- 对照组：自己调 `user32!SetWindowCompositionAttribute` 给 `Shell_TrayWnd` 上洋红，任务栏**会**变色（46,48,48 → 73,51,75），说明系统合成/accent 通道没坏；
- 也就是说：**26300.10075 这一版 shell 已经不再和 TBTB 的接管层对话了**，用户态怎么修都没用。

卸载这一版累积更新、回到 `26100.9974` 后，同一条链路立刻恢复（自检 delta 从 0 变成 114，任务栏恢复透明）。

> 注：修复前曾观察到 `explorer.exe 10.0.26100.1710` / `Taskbar.dll 10.0.10011.16384` 与系统版本不一致，但 `System32` 与 `WinSxS` 里的同名文件 **SHA256 完全相同**，属于按路径读取版本号的假象，不能作为“文件损坏”的依据（详见 `REPORT.md` 3.5 节）。

## 自检是怎么判定的

把 `desktop_appearance` 临时改成不透明洋红 `#FFFF00FF`，重启 TBTB，然后抓任务栏像素平均色和基线比：

```
baseline RGB = 79,84,102     <- 修复后：透明任务栏，透出壁纸
test     RGB = 48,50,53      <- 洋红配置生效，任务栏被改写
delta        = 114           -> PASS
```

修复前同样的流程 `delta = 0`（一点没变）。自检结束会自动还原原配置并重启 TBTB。

## 后续建议

- 这个 build 的累积更新暂时别装；等 TBTB 发布适配版本，或等微软修复 shell 后再装。
- 想反馈上游：把 `REPORT.md` + `TBTB-verification.txt` + `%LOCALAPPDATA%\Packages\28017CharlesMilette.TranslucentTB_v826wp6bftszj\TempState\*.log` 一起提到
  <https://github.com/TranslucentTB/TranslucentTB/issues>。
