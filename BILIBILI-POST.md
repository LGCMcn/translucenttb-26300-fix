# B 站投稿文案（直接复制）

视频文件：`media/ttb-26300-fix.mp4`
**1920×1080 / 30fps / 102 秒 / H.264 + AAC / 中文配音 + 声音设计（低频垫音 + 空气感转场 + Q 弹 bloop/pop/tick）**

封面：
- `media/cover-usage.png` —— "怎么用"四步（推荐，信息量最足）
- `media/poster.png` —— 标题页
- `media/cover-verify.png` —— 修复后验证页

在线下载（Release 资产）：
<https://github.com/LGCMcn/translucenttb-26300-fix/releases/latest/download/ttb-26300-fix.mp4>

NAS 分享版（整包 zip，含成片/封面/脚本，有效期至 2027-12-31）：
<https://ug.link/lgcm/filemgr/share-download/?id=11175170a8fd40aa8a40866852f8b825>

---

## 一、标题（选一个）

1. `系统一更新任务栏美化全废？Windows 26H2 这个更新先别装（已实测修复）`
2. `TranslucentTB 更新后不生效？26H2 build 26300 的坑 + 一键回滚`
3. `避坑：装了 KB5132057 任务栏就不透明了，教你 2 分钟救回来`

## 二、简介

```
Windows 26H2（build 26300.10075，KB5132057）更新后，TranslucentTB 直接失效：
进程在、托盘图标在、配置还是 clear，但任务栏就是不透明。

排查结论（不是玄学）：
· 进程 / 自启 / 配置 / ExplorerTAP.dll 注入 / 系统透明开关 —— 全部正常
· trace 日志里从来没有"给任务栏下发外观"这一步
· 对照组：手工对 Shell_TrayWnd 调 SetWindowCompositionAttribute，任务栏会变色
→ 这一版 shell 不再和 TBTB 的接管层对话，用户态修不好，只能回滚更新

实测修复：
dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart
重启后自检从 delta=0 变成 delta=114，任务栏恢复透明（26300.9974）

仓库（脚本 + 完整排查报告 + 视频）：
https://github.com/LGCMcn/translucenttb-26300-fix

备用下载（NAS 直链，国内更快，含成片+封面+脚本，有效期至 2027-12）：
https://ug.link/lgcm/filemgr/share-download/?id=11175170a8fd40aa8a40866852f8b825

使用方法（视频 00:53 处有四步演示）：
1) 打开仓库 → Code → Download ZIP，整包解压（别只拖一个脚本出来）
2) 右键 Fix-RollbackUpdate.ps1 → 使用 PowerShell 运行（管理员）
3) 等它卸载完（10–30 分钟，窗口别关）→ 重启
4) 桌面出现 TBTB-verification.txt，看到 VERDICT: FIXED 就修好了

⚠️ 卸载系统更新属于维护操作，先备份重要数据；回滚后别急着把这一版更新装回来。

#Windows11 #任务栏 #TranslucentTB #电脑技巧 #避坑
```

## 三、标签 / 分区

- 分区：科技 → 计算机技术（或 数码 → 软件应用）
- 标签：`Windows11`、`Windows更新`、`TranslucentTB`、`任务栏美化`、`电脑技巧`、`避坑`、`系统优化`

## 四、章节（发布时填，B 站会生成进度条）

```
00:00 更新后任务栏美化全废
00:04 症状：进程在、配置对、就是不生效
00:19 逐项排除：全都正常
00:37 根因：shell 不再和接管层对话
00:53 怎么用：四步搞定
01:18 一键命令
01:26 修复后验证
01:33 避坑三件事
```

## 五、上传步骤

1. 打开 <https://member.bilibili.com/platform/upload/video/frame>
2. 上传 `media/ttb-26300-fix.mp4`（或从 Release 下载），封面用 `media/cover-usage.png`
3. 标题 / 简介 / 标签按上面填，分区选"科技 → 计算机技术"
4. 简介里保留仓库地址（B 站外链不跳转，但可以复制）
5. 发布后把视频链接回填到 GitHub README 与 Release 说明

## 六、素材说明

| 文件 | 用途 |
|---|---|
| `media/ttb-26300-fix.mp4` | 成片（带配音音轨） |
| `media/cover-usage.png` / `poster.png` / `cover-verify.png` | 封面候选 |
| `media/voice/s1..s8.mp3` | 分段配音（按场景切分，可单独复用） |
| `media/voice/durations.json` | 每段配音时长，便于二次对齐 |
| `video/` | Remotion 工程 + 配音/混音脚本（`tts.ps1` / `mix.ps1`），可复现整条流水线 |

> 说明：我没有 B 站账号登录态，不能替你点"发布"；视频、封面、文案、章节都已备好，上传即可。
