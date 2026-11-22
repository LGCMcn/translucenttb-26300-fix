import React from "react";
import { AbsoluteFill } from "remotion";

const theme = {
  bg: "#07080b",
  fg: "#f2f6fb",
  dim: "#8b98a9",
  red: "#ff3b5c",
  green: "#2ee6a8",
  cyan: "#39d0ff",
  yellow: "#ffc857",
};
const fontSans = '"Microsoft YaHei", "PingFang SC", "Segoe UI", system-ui, sans-serif';
const fontMono = 'Consolas, "Cascadia Mono", monospace';

const Grid: React.FC = () => (
  <AbsoluteFill
    style={{
      backgroundImage: `linear-gradient(to right, rgba(255,255,255,0.04) 1px, transparent 1px),
                        linear-gradient(to bottom, rgba(255,255,255,0.04) 1px, transparent 1px)`,
      backgroundSize: "64px 64px",
      maskImage: "radial-gradient(circle at 30% 40%, black 25%, transparent 80%)",
      WebkitMaskImage: "radial-gradient(circle at 30% 40%, black 25%, transparent 80%)",
    }}
  />
);

const Backdrop: React.FC<{ children?: React.ReactNode; tint?: string }> = ({
  children,
  tint = theme.red,
}) => (
  <AbsoluteFill style={{ backgroundColor: theme.bg }}>
    <AbsoluteFill
      style={{
        background: `radial-gradient(1100px 720px at 18% 22%, ${tint}2e, transparent 68%),
                     radial-gradient(900px 620px at 88% 88%, ${theme.cyan}1f, transparent 70%)`,
      }}
    />
    <Grid />
    {children}
  </AbsoluteFill>
);

/** a little taskbar mock: opaque vs transparent */
const TaskbarMock: React.FC<{ transparent: boolean; label: string; ok: boolean }> = ({
  transparent,
  label,
  ok,
}) => (
  <div style={{ width: 600 }}>
    <div
      style={{
        height: 108,
        borderRadius: 16,
        border: `2px solid ${ok ? theme.green : theme.red}66`,
        background: transparent
          ? "linear-gradient(90deg,#dfe6ee 0%,#cfd8e4 50%,#c2cede 100%)"
          : "#1b1e24",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 18,
        boxShadow: transparent
          ? `0 0 40px ${theme.green}25`
          : "inset 0 0 40px rgba(0,0,0,0.6)",
      }}
    >
      {[0, 1, 2, 3, 4].map((i) => (
        <div
          key={i}
          style={{
            width: 34,
            height: 34,
            borderRadius: 8,
            background: transparent ? "rgba(20,24,30,0.55)" : "rgba(255,255,255,0.16)",
          }}
        />
      ))}
      <div
        style={{
          marginLeft: 24,
          fontSize: 26,
          fontFamily: fontMono,
          color: transparent ? "rgba(20,24,30,0.75)" : theme.dim,
        }}
      >
        14:20
      </div>
    </div>
    <div
      style={{
        marginTop: 16,
        display: "flex",
        alignItems: "center",
        gap: 12,
        fontFamily: fontSans,
        fontSize: 30,
        color: ok ? theme.green : theme.red,
      }}
    >
      <span style={{ fontSize: 34 }}>{ok ? "✓" : "✕"}</span>
      {label}
    </div>
  </div>
);

const Corner: React.FC<{ text: string; color: string; right?: number; top?: number }> = ({
  text,
  color,
  right = 60,
  top = 56,
}) => (
  <div
    style={{
      position: "absolute",
      right,
      top,
      padding: "14px 28px",
      borderRadius: 999,
      background: color,
      color: "#0b0d11",
      fontFamily: fontSans,
      fontSize: 30,
      fontWeight: 800,
      letterSpacing: 1,
    }}
  >
    {text}
  </div>
);

/* ---------------------------------------------------------------- cover A */
export const CoverA: React.FC = () => (
  <Backdrop>
    <Corner text="已实测修复" color={theme.green} />
    <AbsoluteFill style={{ padding: "92px 92px 80px", display: "flex", flexDirection: "row" }}>
      <div style={{ width: "54%", display: "flex", flexDirection: "column", justifyContent: "center" }}>
        <div
          style={{
            display: "inline-flex",
            alignSelf: "flex-start",
            padding: "10px 24px",
            borderRadius: 999,
            border: `2px solid ${theme.red}66`,
            background: `${theme.red}1a`,
            color: theme.red,
            fontFamily: fontSans,
            fontSize: 30,
            letterSpacing: 2,
          }}
        >
          避坑 · WINDOWS 26H2
        </div>

        <div style={{ marginTop: 40, fontFamily: fontSans, fontWeight: 800, lineHeight: 1.06 }}>
          <div style={{ fontSize: 132, color: theme.fg, letterSpacing: -2 }}>系统一更新</div>
          <div style={{ fontSize: 132, color: theme.red, letterSpacing: -2, marginTop: 8 }}>
            任务栏美化全废
          </div>
        </div>

        <div
          style={{
            marginTop: 40,
            fontSize: 40,
            color: theme.dim,
            fontFamily: fontSans,
            lineHeight: 1.5,
          }}
        >
          TranslucentTB 直接失效
          <br />
          <span style={{ color: theme.fg }}>附一键回滚 · 2 分钟救回来</span>
        </div>

        <div
          style={{
            marginTop: 46,
            display: "flex",
            alignItems: "center",
            gap: 20,
            fontFamily: fontMono,
            fontSize: 32,
            color: theme.dim,
          }}
        >
          <span>build 26300.10075</span>
          <span style={{ color: theme.red }}>→</span>
          <span style={{ color: theme.green }}>26300.9974</span>
        </div>
      </div>

      <div
        style={{
          width: "46%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "flex-end",
          gap: 54,
        }}
      >
        <TaskbarMock transparent={false} label="修复前：不透明" ok={false} />
        <TaskbarMock transparent label="修复后：透明" ok />
      </div>
    </AbsoluteFill>
  </Backdrop>
);

/* ---------------------------------------------------------------- cover B */
export const CoverB: React.FC = () => (
  <Backdrop tint={theme.yellow}>
    <Corner text="全程 2 分钟" color={theme.yellow} />
    <AbsoluteFill
      style={{ padding: "88px 92px", display: "flex", flexDirection: "column", justifyContent: "center" }}
    >
      <div style={{ fontFamily: fontSans, fontSize: 34, color: theme.yellow, letterSpacing: 3 }}>
        WINDOWS 26H2 更新踩坑
      </div>
      <div
        style={{
          marginTop: 26,
          fontFamily: fontSans,
          fontSize: 118,
          fontWeight: 800,
          color: theme.fg,
          lineHeight: 1.08,
          letterSpacing: -1,
        }}
      >
        任务栏不透明？
        <br />
        <span style={{ color: theme.yellow }}>一条命令回滚</span>
      </div>

      <div style={{ marginTop: 54, display: "flex", gap: 26 }}>
        {[
          { n: "1", t: "下载整包", d: "GitHub / NAS 镜像" },
          { n: "2", t: "右键运行脚本", d: "自动提管理员权限" },
          { n: "3", t: "重启验证", d: "看到 FIXED 即成功" },
        ].map((s) => (
          <div
            key={s.n}
            style={{
              flex: 1,
              padding: "28px 30px",
              borderRadius: 22,
              background: "rgba(255,255,255,0.05)",
              border: "1px solid rgba(255,255,255,0.1)",
            }}
          >
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: 16,
                background: `${theme.yellow}22`,
                border: `1px solid ${theme.yellow}66`,
                color: theme.yellow,
                fontFamily: fontSans,
                fontSize: 32,
                fontWeight: 800,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              {s.n}
            </div>
            <div style={{ marginTop: 18, fontFamily: fontSans, fontSize: 38, color: theme.fg, fontWeight: 700 }}>
              {s.t}
            </div>
            <div style={{ marginTop: 8, fontFamily: fontSans, fontSize: 26, color: theme.dim }}>{s.d}</div>
          </div>
        ))}
      </div>

      <div
        style={{
          marginTop: 46,
          display: "flex",
          gap: 20,
          alignItems: "center",
          fontFamily: fontMono,
          fontSize: 30,
          color: theme.dim,
        }}
      >
        <span style={{ color: theme.red }}>自检 delta 0</span>
        <span>→</span>
        <span style={{ color: theme.green }}>114</span>
        <span style={{ marginLeft: 30 }}>TranslucentTB 2026.2.0</span>
      </div>
    </AbsoluteFill>
  </Backdrop>
);

/* ---------------------------------------------------------------- cover C */
export const CoverC: React.FC = () => (
  <Backdrop tint={theme.cyan}>
    <Corner text="实测" color={theme.cyan} />
    <AbsoluteFill
      style={{
        padding: "80px 92px",
        display: "flex",
        flexDirection: "row",
        alignItems: "center",
        gap: 60,
      }}
    >
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: fontSans, fontSize: 32, color: theme.cyan, letterSpacing: 4 }}>
          TRANSLUCENTTB · 2026.2.0
        </div>
        <div
          style={{
            marginTop: 28,
            fontFamily: fontSans,
            fontSize: 122,
            fontWeight: 800,
            color: theme.fg,
            lineHeight: 1.05,
            letterSpacing: -2,
          }}
        >
          更新完
          <br />
          任务栏<span style={{ color: theme.red }}>就不透明了</span>
        </div>
        <div style={{ marginTop: 38, fontFamily: fontSans, fontSize: 38, color: theme.dim }}>
          build 26300.10075 的问题 · 回滚即恢复
        </div>
        <div
          style={{
            marginTop: 44,
            display: "inline-flex",
            padding: "18px 34px",
            borderRadius: 16,
            background: `${theme.red}1c`,
            border: `2px solid ${theme.red}66`,
            color: theme.red,
            fontFamily: fontSans,
            fontSize: 34,
            fontWeight: 700,
          }}
        >
          先别装这一版更新
        </div>
      </div>

      <div
        style={{
          width: 620,
          padding: "40px 40px",
          borderRadius: 26,
          background: "rgba(255,255,255,0.045)",
          border: "1px solid rgba(255,255,255,0.1)",
        }}
      >
        <div style={{ fontFamily: fontSans, fontSize: 30, color: theme.dim }}>洋红自检色差</div>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 26, marginTop: 18 }}>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontFamily: fontSans, fontSize: 24, color: theme.dim }}>修复前</div>
            <div style={{ fontFamily: fontMono, fontSize: 110, fontWeight: 800, color: theme.red }}>0</div>
          </div>
          <div style={{ fontFamily: fontSans, fontSize: 54, color: theme.dim, paddingBottom: 22 }}>→</div>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontFamily: fontSans, fontSize: 24, color: theme.dim }}>修复后</div>
            <div style={{ fontFamily: fontMono, fontSize: 110, fontWeight: 800, color: theme.green }}>114</div>
          </div>
        </div>
        <div
          style={{
            marginTop: 26,
            height: 22,
            borderRadius: 11,
            background: "rgba(255,255,255,0.08)",
            overflow: "hidden",
          }}
        >
          <div style={{ width: "100%", height: "100%", background: theme.green }} />
        </div>
        <div
          style={{
            marginTop: 22,
            fontFamily: fontSans,
            fontSize: 28,
            color: theme.green,
          }}
        >
          RESULT: PASS · 任务栏恢复透明
        </div>
      </div>
    </AbsoluteFill>
  </Backdrop>
);
