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

# 2. IR path latency: before (uniform partitions, 2B = 1024 samples) and now (zero)
import soundfile as sf
from reference.engine import Echolivity
irx, irsr = sf.read(str(ROOT / "ir/originals/synthetic/SYN_K10Spec_2S.wav"), always_2d=True)
x = np.zeros(int(SR * 0.25)); x[0] = 1.0
yy = Echolivity(SR, dict(engine_mode=0, mix=1.0, drive=0.0, decay=8.0, damping=0.0), ir=irx, ir_sr=irsr).process(x)[:, 0]
w = int(0.001 * SR); env = np.sqrt(np.convolve(yy ** 2, np.ones(w) / w, mode="same"))
env_db = 20 * np.log10(env / env.max() + 1e-9)
t = np.arange(len(env)) / SR * 1000
fig, ax = plt.subplots(figsize=(10, 4.2))
ax.plot(t + 1024 / SR * 1000, env_db, color=STEEL, lw=1.6, ls="--", label="Before: 1024-sample convolution delay (21.3 ms)")
ax.plot(t, env_db, color=BRASS, lw=2, label="Now: zero latency")
ax.set_ylim(-60, 2); ax.set_xlim(0, 160)
ax.set_xlabel("Time after the hit (ms)"); ax.set_ylabel("Level (dB, 1 ms RMS)")
ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.2), frameon=False, ncol=2, fontsize=10)
finish(ax, fig, "ir_latency.png", "The IR path now arrives on time",
       "IR mode, synthetic K-10-spec IR, 48 kHz, one impulse. Reference engine; the device's gen~ convolver matches it to 1e-15 with no delay (tests/port_check).")
print("wrote", sorted(p.name for p in OUT.glob("*.png")))
