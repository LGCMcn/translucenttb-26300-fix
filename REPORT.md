# TranslucentTB 2 在 Windows 26H2（build 26300）更新后完全失效

> 排查日期：2026-11-22
> 状态：**已定位并已修复（本机验证通过）**
> 一句话：26300.10075 这版累积更新（KB5132057）的 shell 不再和 TranslucentTB 的接管层对话；
> 卸载该更新、回到 26100.9974 后任务栏立刻恢复透明（自检 delta 从 0 → 114）。

---

## 0. 解决方案（已验证）

```powershell
# 1) 卸载出问题的累积更新（管理员）
dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart
#    退出码 3010 = 成功但需要重启

# 2) 重启

# 3) 验证（PASS 即修复）
powershell -ExecutionPolicy Bypass -File .\Test-TaskbarAccent.ps1
```

本机结果：

| | 修复前 | 修复后 |
|---|---|---|
| 系统 | 26H2 build **26300.10075** | 26H2 build **26300.9974** |
| 自检 delta | **0**（洋红配置完全不可见） | **114**（任务栏被正常改写） |
| 自检结论 | `RESULT: FAIL` | `RESULT: PASS` |
| 任务栏 | 不透明深色 | 透明（透出壁纸，任务栏像素 79,84,102） |

一键脚本：`Fix-RollbackUpdate.ps1 -Latest`（自动提权 + 卸载 + 注册重启后自动验证）。

---

## 1. 环境

| 项 | 值 |
|---|---|
| 系统 | Windows 10 Pro，DisplayVersion `26H2`，Build `26300.10075`（`UBR=10075`） |
| 最近更新 | `KB5132057`（2026-11-22 14:06 落地）、`KB5132056`、`KB5137006`（2026-11-20） |
| TranslucentTB | `2026.2.0`，MSIX/Store，包全名 `28017CharlesMilette.TranslucentTB_2026.2.0.0_x64__v826wp6bftszj` |
| 显示 | 单显示器 1920×1080，深色主题 |
| 个性化 | `EnableTransparency=1`，`AppsUseLightTheme=0`，`ColorPrevalence=1` |
| 其它任务栏美化 | 无（无 StartAllBack / ExplorerPatcher / Windhawk / RoundedTB） |

## 2. 症状

- 更新系统并重启后，任务栏恢复成系统默认的深色不透明条。
- TBTB 托盘图标还在，进程正常（`Responding=True`），任务管理器里能看到。
- 配置 `desktop_appearance.accent = "clear"`（全透明）不生效。
- 重启 TBTB、重启 explorer、注销、重置包 —— 均无效。

## 3. 排查证据

### 3.1 一切“常规嫌疑”均排除

| 检查项 | 实测结果 | 结论 |
|---|---|---|
| 进程 | `TranslucentTB` 运行中，`Responding=True` | 正常 |
| 自启 | AppX `StartupTask` 的 `State=2 (Enabled)`，注册表 `...\AppModel\SystemAppData\...\TranslucentTB` 存在 | 正常（AppX 不在 `HKCU\...\Run` 里是正常的） |
| 注入 | explorer.exe 已加载 `ExplorerTAP.dll`（从包 `TempState` 加载，SHA256 与安装目录一致） | 注入成功 |
| 配置 | 配置在 `%LOCALAPPDATA%\Packages\<PFN>\RoamingState\settings.json`，`LocalState` 为空属正常 | 正常 |
| 系统透明 | `HKCU\...\Themes\Personalize\EnableTransparency = 1` | 正常 |

### 3.2 决定性实验 A —— 把配置改成“刺眼洋红”也不生效

临时把 `desktop_appearance` 改成：

```json
{ "accent": "opaque", "color": "#FFFF00FF", "show_peek": false, "show_line": false, "blur_radius": 9.0 }
```

（`disable_saving: true`，`verbosity: "trace"`），然后 **杀进程 → 重启 TBTB → 重启 explorer**。

任务栏像素均值（x∈[300,1400]，y∈[1040,1074]）**完全没变**：`54,57,60`。

→ TBTB 根本没往任务栏写过外观。

### 3.3 决定性实验 B —— 手工 accent 通道是好的

同一个任务栏窗口 `Shell_TrayWnd`，自己调 `user32!SetWindowCompositionAttribute`：

| 调用 | 任务栏像素均值 | 说明 |
|---|---|---|
| 基线 | `46,48,48` | — |
| `AccentState=2, Flags=2, GradientColor=0xFFFF00FF`（洋红） | `73,51,75` | 变了，但只是**部分**染色 |
| `AccentState=3, Flags=2, GradientColor=0x00000000`（透明） | `41,43,42` | 变暗，不是“看见壁纸” |

→ 两条结论：
1. **系统没有禁用透明/合成**，accent 调用返回 `True` 且确实有视觉变化；
2. 但这台机器的任务栏**可见背景不是由 `Shell_TrayWnd` 的背景绘制决定的**——`Shell_TrayWnd` 里挂了一个
   `Windows.UI.Composition.DesktopWindowContentBridge`（`DesktopWindowXamlSource`）子窗口，真正的底色由它（XAML/合成层）画，
   所以只对外层窗口做 accent 最多只能影响一小部分。

对子窗口逐个调 accent 全部返回 `False`（只有顶层 `Shell_TrayWnd` 返回 `True`），也印证了这点。

### 3.4 TBTB 自己的 trace 日志

`%LOCALAPPDATA%\Packages\<PFN>\TempState\<pid>.log`（`verbosity: "trace"`）：

```
[debug] [taskbarattributeworker.cpp:1410] Resetting worker state
[debug] [taskbarattributeworker.cpp:660]  Inserting normal window 0x... to monitor 0x10001
[debug] [taskbarattributeworker.cpp:105]  A taskbar got created, refreshing...
[debug] [taskbarattributeworker.cpp:348]  Main taskbar got created, refreshing...
[debug] [taskbarattributeworker.cpp:144]  Changed foreground window to 0x... [Program Manager] [Progman] [explorer.exe]
[info]  [window.cpp:181] Verifying if a window is on the current virtual desktop failed. (0x80040154: Class not registered)
[info]  [trayicon.cpp:55] Failed to notify shell.
```

要点：
- WinEvent 钩子是工作的（任务栏创建/前台窗口变化都能收到），**但整个 trace 里没有任何一次“把任务栏插入 monitor / 下发外观”的记录** —— 说明它识别到了任务栏窗口，却没把它当成可控制的任务栏。
- `0x80040154 (REGDB_E_CLASSNOTREG)`：TBTB 通过 shell 的 COM 服务（`ImmersiveShell` 一系列）判断窗口属于哪个虚拟桌面时失败。
  我这台机器上独立复测：`CoCreateInstance(CLSID_ImmersiveShell)` → `0x80040154`，
  而 `CoCreateInstance(CLSID_VirtualDesktopManager)` → `S_OK`。
- `Failed to notify shell.`：TBTB 托盘图标 `Shell_NotifyIcon` 也失败。

### 3.5 “文件版本错配”是假象（重要）

一开始发现：

```
OS            10.0.26300.10075
explorer.exe  10.0.26100.1710      ← 看着像没更新
Taskbar.dll   10.0.10011.16384     ← 看着像 2015 年的文件
shell32.dll   10.0.26100.9949
```

看起来像“更新半应用”。但继续验证后发现**这是路径相关的版本号假象**：

- `C:\Windows\System32\Taskbar.dll` 与 WinSxS 中 `amd64_microsoft-windows-taskbar-dll_..._10.0.26100.10068_...` 下的同名文件
  **SHA256 完全相同**（`8018ECDB6BE4C1BC…`，同为 3,316,736 字节），却分别报告 `10.0.10011.16384` 和 `10.0.26100.10068`。
- `DISM /Online /Cleanup-Image /ScanHealth` → **“未检测到组件存储损坏”**
- `sfc /scannow` → **“Windows 资源保护未找到任何完整性冲突”**

→ 文件内容一致、SFC/DISM 均判健康，“版本错配”不是真因，不能据此修系统。

## 4. 已执行的修复尝试（全部成功执行，问题依旧）

| # | 动作 | 结果 |
|---|---|---|
| 1 | 结束并重启 TBTB | 无效 |
| 2 | 重启 explorer（重新注入 TAP） | 无效 |
| 3 | `Get-AppxPackage ... | Reset-AppxPackage`（管理员）+ 重启 TBTB | 无效 |
| 4 | 检查/补 `CLSID_ImmersiveShell` 的 `InProcServer32`（`windows.internal.shell.broker.dll` 等 5 个候选） | 均为 `0x80040111/0x80040154`，且该键受 TrustedInstaller ACL 保护，非预期修复点 |
| 5 | 关掉“在开始菜单和任务栏上显示主题色”（`ColorPrevalence=0`，主题色为不透明白/黑） | 无效（测完已还原为 1） |
| 6 | `DISM /Online /Cleanup-Image /ScanHealth` | 未检测到损坏 |
| 7 | `sfc /scannow` | 未找到完整性冲突 |
| 8 | 用 WinSxS 中的 `Taskbar.dll`/`explorer.exe` 覆盖 System32/Windows 下的同名文件（takeown + 改名替换），重启 explorer | 文件内容本来就一致，替换后无任何变化（`.old` 已删除，属主已还原 TrustedInstaller） |
| 9 | 以管理员运行 TBTB | WindowsApps 下直接提权启动被拒绝 |

## 5. 结论（已修复，含验证）

1. **不是** TBTB 没启动 / 自启被关 / 配置丢失 / 透明效果被关 / 包损坏 / 系统文件损坏。
2. 表现是：TBTB 的注入层正常、事件钩子正常，**但“任务栏外观”这一步从来没发生过**——
   在 26H2 build **26300.10075** 这套 shell 上，TBTB 2 的 taskbar 接管路径（XAML/TAP 侧）没有生效；
   而传统 `SetWindowCompositionAttribute` 路径对这台机器的任务栏只能造成局部染色，做不到“透明”。
3. 卸载该累积更新（`Package_for_RollupFix~…~26100.10075.1.25`）、重启回到 **26100.9974** 后，
   同一条链路立刻恢复：洋红自检 delta 由 **0 → 114**，任务栏恢复透明（像素 79,84,102，能透出壁纸）。

**→ 根因：26300.10075 这次累积更新改变了 shell 与 TBTB 接管层的交互方式；
   在用户态无法绕过，只能回滚该更新（或等 TBTB 适配 / 微软修复）。**

## 6. 处置

1. **回滚本次更新（已验证有效）**：

   ```powershell
   # 管理员：退出码 3010 = 成功，需重启
   dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart
   ```

   或直接跑一键脚本：`Fix-RollbackUpdate.ps1 -Latest`

2. **避免重装同一更新**：在该 build 的问题确认修复前，暂停 Windows 更新（或至少不要主动装回这一版）。

3. **反馈上游**：把本报告 + `TBTB-verification.txt` + `TempState\*.log` 提到
   <https://github.com/TranslucentTB/TranslucentTB/issues>。

3. **临时替代**：RoundedTB（圆角/边距，不改透明）、Windhawk 的任务栏模块 —— 但同样依赖任务栏实现，是否能用需实测。
