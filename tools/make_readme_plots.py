"""Renders the README plots into docs/img/ from the Python reference engine.

Model engine only (no third-party IRs needed). Usage: python tools/make_readme_plots.py
"""
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import spectrogram

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from reference.engine import Echolivity  # noqa: E402
from reference import signals  # noqa: E402

OUT = ROOT / "docs" / "img"
OUT.mkdir(parents=True, exist_ok=True)
SR = 48000
BG, PANEL, INK, SUB, BRASS, COPPER, STEEL = "#16130f", "#221d17", "#f3ead9", "#bfae90", "#d4ae5f", "#d9774a", "#8fa7b3"
plt.rcParams.update({"font.family": "DejaVu Sans", "text.color": INK, "axes.labelcolor": SUB, "xtick.color": SUB, "ytick.color": SUB,
                     "axes.edgecolor": SUB, "axes.facecolor": PANEL, "figure.facecolor": BG, "savefig.facecolor": BG, "font.size": 11})


def finish(ax, fig, name, title, note):
    ax.set_title(title, loc="left", fontsize=14, fontweight="bold", pad=12)
    for s in ax.spines.values():
        s.set_alpha(0.35)
    fig.text(0.01, 0.01, note, fontsize=8.5, color=SUB)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT / name, dpi=110)
    plt.close(fig)


def render(params, x):
    eng = Echolivity(SR, dict(params, engine_mode=1, mix=1.0))
    return eng.process(x)


# 1. spectrogram of the model's impulse response
imp = np.zeros(SR * 2); imp[0] = 1.0
y = render({"movement": 0.0, "modulation": 0.0, "boing": 0.0}, imp)
f, tt, S = spectrogram(y[: int(1.2 * SR), 0], SR, nperseg=1024, noverlap=960)
fig, ax = plt.subplots(figsize=(10, 4.2))
Sd = 10 * np.log10(S + 1e-14); Sd -= Sd.max()
m = ax.pcolormesh(tt * 1000, f / 1000, Sd, vmin=-70, vmax=0, cmap="copper", shading="auto")
ax.set_ylim(0, 6); ax.set_xlabel("Time (ms)"); ax.set_ylabel("Frequency (kHz)")
cb = fig.colorbar(m, ax=ax, pad=0.01); cb.set_label("dB", color=SUB); cb.ax.yaxis.set_tick_params(color=SUB)
finish(ax, fig, "dispersion_spectrogram.png", "Dispersion: each reflection is a chirp, the spring's \"pew\"",
       "Impulse response of the reference engine's physical model (left spring), Dispersion 0.55. Higher frequencies arrive first, so each echo sweeps downward.")

# 2. dub feedback on a rimshot
x = np.zeros(int(SR * 10)); r = signals.rimshot(SR); x[: len(r)] = r
fig, ax = plt.subplots(figsize=(10, 4.2))
for lab, p, c in [("Feedback 0", {}, STEEL), ("Feedback 90 %", {"feedback": 0.9}, BRASS),
                  ("Feedback 90 % + Self-Osc 60 %", {"feedback": 0.9, "self_osc": 0.6}, COPPER)]:
    yy = render(dict(p, movement=0.3), x)[:, 0]
    w = int(0.02 * SR); env = np.sqrt(np.convolve(yy ** 2, np.ones(w) / w, mode="same"))
    ax.plot(np.arange(len(env)) / SR, 20 * np.log10(env + 1e-9), color=c, lw=2, label=lab)
ax.set_ylim(-80, 0); ax.set_xlim(0, 10)
ax.set_xlabel("Time (s)"); ax.set_ylabel("Level (dBFS, 20 ms RMS)")
ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.2), frameon=False, ncol=3, fontsize=10)
finish(ax, fig, "dub_feedback.png", "One rimshot, three amounts of dub",
       "Reference engine, Model mode, synthetic rimshot. Feedback regenerates the tail; Self-Osc builds it into a controlled howl, capped by the loop limiter.")
print("wrote", sorted(p.name for p in OUT.glob("*.png")))
