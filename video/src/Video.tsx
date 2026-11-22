import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
  Sequence,
  Easing,
} from "remotion";

/* ------------------------------------------------------------------ theme */

export const theme = {
  bg: "#08090c",
  bg2: "#101319",
  fg: "#eef2f7",
  dim: "#8b98a9",
  red: "#ff3b5c",
  green: "#2ee6a8",
  cyan: "#39d0ff",
  yellow: "#ffc857",
  purple: "#b98cff",
};

const fontSans = '"Microsoft YaHei", "PingFang SC", "Segoe UI", system-ui, sans-serif';
const fontMono = 'Consolas, "Cascadia Mono", "Courier New", monospace';

/* ------------------------------------------------------------------ helpers */

const Fade: React.FC<{
  children: React.ReactNode;
  durationInFrames: number;
  fadeIn?: number;
  fadeOut?: number;
  style?: React.CSSProperties;
}> = ({ children, durationInFrames, fadeIn = 15, fadeOut = 15, style }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(
    frame,
    [0, fadeIn, durationInFrames - fadeOut, durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const y = interpolate(frame, [0, fadeIn], [24, 0], {
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  return (
    <AbsoluteFill style={{ opacity, transform: `translateY(${y}px)`, ...style }}>
      {children}
    </AbsoluteFill>
  );
};

const Grid: React.FC = () => (
  <AbsoluteFill
    style={{
      backgroundImage: `linear-gradient(to right, rgba(255,255,255,0.035) 1px, transparent 1px),
                        linear-gradient(to bottom, rgba(255,255,255,0.035) 1px, transparent 1px)`,
      backgroundSize: "80px 80px",
      maskImage: "radial-gradient(circle at 50% 45%, black 30%, transparent 78%)",
      WebkitMaskImage: "radial-gradient(circle at 50% 45%, black 30%, transparent 78%)",
    }}
  />
);

const Backdrop: React.FC<{ tint?: string }> = ({ tint = theme.cyan }) => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 90) * 60;
  return (
    <AbsoluteFill style={{ backgroundColor: theme.bg }}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(900px 600px at ${50 + drift / 6}% 20%, ${tint}22, transparent 70%),
                       radial-gradient(800px 500px at 80% 95%, ${theme.purple}18, transparent 70%)`,
        }}
      />
      <Grid />
    </AbsoluteFill>
  );
};

const Badge: React.FC<{ text: string; color?: string }> = ({ text, color = theme.cyan }) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      gap: 10,
      padding: "10px 22px",
      borderRadius: 999,
      border: `1px solid ${color}55`,
      background: `${color}14`,
      color,
      fontFamily: fontSans,
      fontSize: 26,
      letterSpacing: 1,
    }}
  >
    {text}
  </div>
);

/* ------------------------------------------------------------------ scene 1 */

const SceneTitle: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 200, mass: 0.6 } });
  const scale = interpolate(s, [0, 1], [0.92, 1]);
  const lineW = interpolate(s, [0, 1], [0, 520]);

  return (
    <Backdrop tint={theme.red}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 34 }}>
        <div style={{ transform: `scale(${scale})`, textAlign: "center" }}>
          <div style={{ fontSize: 34, color: theme.red, letterSpacing: 8, fontFamily: fontSans }}>
            WINDOWS 26H2 · BUILD 26300.10075
          </div>
          <div
            style={{
              marginTop: 26,
              fontSize: 96,
              fontWeight: 800,
              color: theme.fg,
              fontFamily: fontSans,
              letterSpacing: 2,
            }}
          >
            系统一更新，任务栏美化全废
          </div>
          <div
            style={{
              margin: "30px auto 0",
              width: lineW,
              height: 4,
              background: `linear-gradient(90deg, transparent, ${theme.red}, transparent)`,
            }}
          />
          <div style={{ marginTop: 30, fontSize: 36, color: theme.dim, fontFamily: fontSans }}>
            TranslucentTB 2026.2.0 实测 · 附一键修好方案
          </div>
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ scene 2 */

const SymptomRow: React.FC<{ label: string; value: string; ok?: boolean; delay: number }> = ({
  label,
  value,
  ok,
  delay,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 200 } });
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        width: 1180,
        padding: "22px 34px",
        borderRadius: 18,
        background: "rgba(255,255,255,0.035)",
        border: "1px solid rgba(255,255,255,0.07)",
        opacity: s,
        transform: `translateX(${interpolate(s, [0, 1], [-40, 0])}px)`,
      }}
    >
      <span style={{ fontSize: 34, color: theme.dim, fontFamily: fontSans }}>{label}</span>
      <span
        style={{
          fontSize: 36,
          fontFamily: fontSans,
          color: ok === undefined ? theme.fg : ok ? theme.green : theme.red,
          fontWeight: 600,
        }}
      >
        {value}
      </span>
    </div>
  );
};

const SceneSymptom: React.FC = () => {
  return (
    <Backdrop tint={theme.yellow}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 22 }}>
        <Badge text="症状" color={theme.yellow} />
        <div style={{ height: 26 }} />
        <SymptomRow label="任务栏" value="恢复成系统默认不透明深色" ok={false} delay={8} />
        <SymptomRow label="TranslucentTB 进程" value="在跑，托盘图标也在" ok delay={18} />
        <SymptomRow label="配置 desktop_appearance" value="clear / #00000000" ok delay={28} />
        <SymptomRow label="重启 TBTB / explorer / 重置包" value="全都没用" ok={false} delay={38} />
        <div style={{ height: 22 }} />
        <div style={{ fontSize: 34, color: theme.dim, fontFamily: fontSans }}>
          看着像“没生效”，其实它<span style={{ color: theme.red }}>一次都没往任务栏写过东西</span>
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ scene 3 */

const CheckItem: React.FC<{ text: string; ok: boolean; delay: number; note?: string }> = ({
  text,
  ok,
  delay,
  note,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 200 } });
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 22,
        width: 1160,
        opacity: s,
        transform: `translateY(${interpolate(s, [0, 1], [22, 0])}px)`,
      }}
    >
      <div
        style={{
          width: 52,
          height: 52,
          borderRadius: 14,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 30,
          fontWeight: 800,
          color: ok ? theme.green : theme.red,
          background: ok ? `${theme.green}18` : `${theme.red}18`,
          border: `1px solid ${ok ? theme.green : theme.red}55`,
        }}
      >
        {ok ? "✓" : "✕"}
      </div>
      <div style={{ fontSize: 34, fontFamily: fontSans, color: theme.fg }}>{text}</div>
      {note ? (
        <div style={{ marginLeft: "auto", fontSize: 28, color: theme.dim, fontFamily: fontMono }}>
          {note}
        </div>
      ) : null}
    </div>
  );
};

const SceneChecks: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - 175, fps, config: { damping: 200 } });
  return (
    <Backdrop tint={theme.cyan}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 20 }}>
        <Badge text="逐项排除" color={theme.cyan} />
        <div style={{ height: 20 }} />
        <CheckItem text="进程、自启（StartupTask State=2）" ok delay={6} />
        <CheckItem text="配置读写（RoamingState\settings.json）" ok delay={14} />
        <CheckItem text="ExplorerTAP.dll 已注入 explorer" ok delay={22} />
        <CheckItem text="系统透明效果 EnableTransparency=1" ok note="1" delay={30} />
        <CheckItem text="SFC / DISM 判定系统健康" ok delay={38} />
        <CheckItem text="不透明洋红自检：任务栏像素零变化" ok={false} note="delta = 0" delay={48} />
        <div style={{ height: 18 }} />
        <div
          style={{
            opacity: s,
            fontSize: 34,
            color: theme.fg,
            fontFamily: fontSans,
            marginTop: 10,
          }}
        >
          结论：不是配置、不是自启、不是文件损坏 —— 是它<span style={{ color: theme.red }}>根本没接管任务栏</span>
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ scene 4 */

const SceneRootCause: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s1 = spring({ frame: frame - 10, fps, config: { damping: 200 } });
  const s2 = spring({ frame: frame - 60, fps, config: { damping: 200 } });

  return (
    <Backdrop tint={theme.purple}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 30 }}>
        <Badge text="根因定位" color={theme.purple} />
        <div style={{ fontSize: 58, fontWeight: 800, color: theme.fg, fontFamily: fontSans, opacity: s1 }}>
          build 26300.10075 的 shell 不再和 TBTB 的接管层对话
        </div>
        <div
          style={{
            display: "flex",
            gap: 30,
            opacity: s1,
            transform: `translateY(${interpolate(s1, [0, 1], [20, 0])}px)`,
          }}
        >
          <div
            style={{
              width: 700,
              padding: 32,
              borderRadius: 20,
              background: "rgba(255,255,255,0.04)",
              border: "1px solid rgba(255,255,255,0.08)",
            }}
          >
            <div style={{ fontSize: 28, color: theme.dim, fontFamily: fontSans }}>TBTB trace 日志</div>
            <div style={{ marginTop: 14, fontSize: 24, color: theme.red, fontFamily: fontMono, lineHeight: 1.7 }}>
              taskbar got created, refreshing...
              <br />
              Changed foreground window to Progman
              <br />
              <span style={{ color: theme.yellow }}>（从未出现“下发外观”）</span>
            </div>
          </div>
          <div
            style={{
              width: 700,
              padding: 32,
              borderRadius: 20,
              background: "rgba(255,255,255,0.04)",
              border: "1px solid rgba(255,255,255,0.08)",
            }}
          >
            <div style={{ fontSize: 28, color: theme.dim, fontFamily: fontSans }}>对照组：手工调 accent</div>
            <div style={{ marginTop: 14, fontSize: 24, color: theme.green, fontFamily: fontMono, lineHeight: 1.7 }}>
              SetWindowCompositionAttribute(Shell_TrayWnd)
              <br />
              46,48,48 → 73,51,75
              <br />
              <span style={{ color: theme.green }}>系统合成没坏 ✓</span>
            </div>
          </div>
        </div>
        <div style={{ opacity: s2, fontSize: 32, color: theme.dim, fontFamily: fontSans }}>
          换句话说：<span style={{ color: theme.fg }}>用户态怎么修都没用</span>，只能回滚这一版更新
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ scene 5 */

const TypedCode: React.FC<{ lines: string[]; charsPerFrame?: number }> = ({
  lines,
  charsPerFrame = 1.6,
}) => {
  const frame = useCurrentFrame();
  const total = lines.join("\n");
  const shown = Math.min(total.length, Math.floor(frame * charsPerFrame));
  const visible = total.slice(0, shown).split("\n");
  return (
    <div
      style={{
        width: 1400,
        padding: "34px 40px",
        borderRadius: 20,
        background: "#0c0f14",
        border: "1px solid rgba(255,255,255,0.1)",
        boxShadow: "0 30px 80px rgba(0,0,0,0.5)",
      }}
    >
      <div style={{ display: "flex", gap: 10, marginBottom: 22 }}>
        <div style={{ width: 14, height: 14, borderRadius: 7, background: "#ff5f57" }} />
        <div style={{ width: 14, height: 14, borderRadius: 7, background: "#febc2e" }} />
        <div style={{ width: 14, height: 14, borderRadius: 7, background: "#28c840" }} />
      </div>
      {visible.map((line, i) => (
        <div
          key={i}
          style={{
            fontFamily: fontMono,
            fontSize: 30,
            lineHeight: 1.75,
            color: line.trim().startsWith("#") ? theme.dim : line.includes("dism") ? theme.cyan : theme.fg,
            whiteSpace: "pre",
          }}
        >
          {line || " "}
        </div>
      ))}
    </div>
  );
};

const SceneFix: React.FC = () => {
  return (
    <Backdrop tint={theme.green}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 28 }}>
        <Badge text="一键修复（管理员）" color={theme.green} />
        <TypedCode
          lines={[
            "# 1) 卸载出问题的累积更新",
            'dism /online /remove-package /packagename:"Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.10075.1.25" /norestart',
            "",
            "# 2) 重启（退出码 3010 = 成功，需重启）",
            "",
            "# 3) 或直接跑一键脚本",
            "powershell -ExecutionPolicy Bypass -File .\\Fix-RollbackUpdate.ps1 -Latest",
          ]}
        />
        <div style={{ fontSize: 30, color: theme.dim, fontFamily: fontSans }}>
          回滚到 build 26100.9974，任务栏立刻回来
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ scene 6 */

const Bar: React.FC<{ label: string; value: number; max: number; color: string; delay: number }> = ({
  label,
  value,
  max,
  color,
  delay,
}) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [delay, delay + 40], [0, value / max], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  return (
    <div style={{ width: 1180 }}>
      <div style={{ display: "flex", justifyContent: "space-between", fontFamily: fontSans }}>
        <span style={{ fontSize: 32, color: theme.dim }}>{label}</span>
        <span style={{ fontSize: 32, color, fontFamily: fontMono }}>{value}</span>
      </div>
      <div
        style={{
          marginTop: 12,
          height: 26,
          borderRadius: 13,
          background: "rgba(255,255,255,0.06)",
          overflow: "hidden",
        }}
      >
        <div style={{ width: `${p * 100}%`, height: "100%", background: color, borderRadius: 13 }} />
      </div>
    </div>
  );
};

const SceneResult: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - 120, fps, config: { damping: 200 } });
  return (
    <Backdrop tint={theme.green}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 26 }}>
        <Badge text="修复后验证" color={theme.green} />
        <div style={{ display: "flex", gap: 30, alignItems: "flex-end" }}>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 26, color: theme.dim, fontFamily: fontSans }}>修复前</div>
            <div style={{ fontSize: 96, fontFamily: fontMono, color: theme.red, fontWeight: 800 }}>0</div>
          </div>
          <div style={{ fontSize: 60, color: theme.dim, paddingBottom: 18 }}>→</div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 26, color: theme.dim, fontFamily: fontSans }}>修复后</div>
            <div style={{ fontSize: 96, fontFamily: fontMono, color: theme.green, fontWeight: 800 }}>114</div>
          </div>
        </div>
        <Bar label="洋红自检色差（0 = 完全没接管）" value={114} max={114} color={theme.green} delay={40} />
        <div style={{ opacity: s, fontSize: 42, color: theme.fg, fontFamily: fontSans }}>
          RESULT: <span style={{ color: theme.green }}>PASS</span> · 任务栏恢复透明
        </div>
        <div style={{ fontSize: 28, color: theme.dim, fontFamily: fontMono }}>
          任务栏像素 73,83,98 ≈ 上方壁纸 95,84,96
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ scene 7 */

const SceneOutro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - 8, fps, config: { damping: 200 } });
  return (
    <Backdrop tint={theme.cyan}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 26 }}>
        <div style={{ fontSize: 64, fontWeight: 800, color: theme.fg, fontFamily: fontSans, opacity: s }}>
          避坑三件事
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 18, opacity: s }}>
          {[
            "① 26H2 build 26300.10075 先别装，装了任务栏美化全废",
            "② 已经装了？回滚这一版，重启就恢复",
            "③ 排查别瞎折腾：用洋红自检一步判定“有没有接管”",
          ].map((t, i) => (
            <div
              key={i}
              style={{
                width: 1320,
                padding: "24px 32px",
                borderRadius: 18,
                background: "rgba(255,255,255,0.04)",
                border: "1px solid rgba(255,255,255,0.08)",
                fontSize: 34,
                color: theme.fg,
                fontFamily: fontSans,
              }}
            >
              {t}
            </div>
          ))}
        </div>
        <div style={{ marginTop: 12, fontSize: 30, color: theme.cyan, fontFamily: fontMono }}>
          github.com/LGCMcn/translucenttb-26300-fix
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

/* ------------------------------------------------------------------ master */

export const TTBFixVideo: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: theme.bg }}>
      <Sequence from={0} durationInFrames={150} name="Title">
        <SceneTitle />
      </Sequence>
      <Sequence from={150} durationInFrames={270} name="Symptom">
        <Fade durationInFrames={270}>
          <SceneSymptom />
        </Fade>
      </Sequence>
      <Sequence from={420} durationInFrames={330} name="Checks">
        <Fade durationInFrames={330}>
          <SceneChecks />
        </Fade>
      </Sequence>
      <Sequence from={750} durationInFrames={330} name="RootCause">
        <Fade durationInFrames={330}>
          <SceneRootCause />
        </Fade>
      </Sequence>
      <Sequence from={1080} durationInFrames={300} name="Fix">
        <Fade durationInFrames={300}>
          <SceneFix />
        </Fade>
      </Sequence>
      <Sequence from={1380} durationInFrames={270} name="Result">
        <Fade durationInFrames={270}>
          <SceneResult />
        </Fade>
      </Sequence>
      <Sequence from={1650} durationInFrames={150} name="Outro">
        <SceneOutro />
      </Sequence>
    </AbsoluteFill>
  );
};
