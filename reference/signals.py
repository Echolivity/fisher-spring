"""Deterministic test material (synthesised, so tests are reproducible and
license-free). Real-session listening with the user's own material is still
required for musical validation - these are for technical tests and renders."""
import numpy as np


def _env(n, sr, a, d):
    t = np.arange(n) / sr
    return np.minimum(t / max(a, 1e-4), 1.0) * np.exp(-t / d)


def rimshot(sr, rng=None):
    rng = rng or np.random.default_rng(1)
    n = int(0.25 * sr); t = np.arange(n) / sr
    body = np.sin(2 * np.pi * 1700 * t) * _env(n, sr, 0.0003, 0.012)
    body += 0.6 * np.sin(2 * np.pi * 480 * t) * _env(n, sr, 0.0003, 0.02)
    click = rng.standard_normal(n) * _env(n, sr, 0.0001, 0.003)
    return 0.7 * (body + 0.8 * click)


def snare(sr, rng=None):
    rng = rng or np.random.default_rng(2)
    n = int(0.4 * sr); t = np.arange(n) / sr
    tone = np.sin(2 * np.pi * 190 * t) * _env(n, sr, 0.001, 0.05)
    noise = rng.standard_normal(n) * _env(n, sr, 0.001, 0.09)
    return 0.5 * (tone + 0.7 * noise)


def hihat(sr, rng=None):
    rng = rng or np.random.default_rng(3)
    n = int(0.12 * sr)
    x = rng.standard_normal(n)
    x = np.diff(np.r_[0, x])
    return 0.25 * x * _env(n, sr, 0.0005, 0.02)


def bass_stab(sr):
    n = int(0.5 * sr); t = np.arange(n) / sr
    x = sum(np.sin(2 * np.pi * 55 * k * t) / k for k in range(1, 6))
    return 0.4 * x * _env(n, sr, 0.003, 0.15)


def chord(sr, dur=0.35):
    n = int(dur * sr); t = np.arange(n) / sr
    freqs = [220.0, 261.63, 329.63, 392.0]          # Am7 dub-techno stab
    x = sum(np.sign(np.sin(2 * np.pi * f * t)) * 0.3 + np.sin(2 * np.pi * f * 1.003 * t) for f in freqs)
    return 0.12 * x * _env(n, sr, 0.002, 0.12)


def pad(sr, dur=2.0):
    n = int(dur * sr); t = np.arange(n) / sr
    x = sum(np.sin(2 * np.pi * f * t + 0.3 * np.sin(2 * np.pi * 0.3 * t)) for f in [130.8, 196.0, 261.6])
    return 0.15 * x * np.minimum(t / 0.3, 1) * np.minimum((dur - t) / 0.3, 1)


def place(sr, total_s, events):
    """events: list of (time_s, signal)."""
    out = np.zeros(int(total_s * sr))
    for t, s in events:
        i = int(t * sr)
        m = min(len(s), len(out) - i)
        out[i:i + m] += s[:m]
    return out


def reggae_pattern(sr, bars=2, bpm=75):
    beat = 60.0 / bpm
    ev = []
    for b in range(bars):
        t0 = b * 4 * beat
        ev += [(t0 + 2 * beat, rimshot(sr))]                         # one-drop
        ev += [(t0 + 0 * beat, bass_stab(sr)), (t0 + 2.5 * beat, bass_stab(sr))]
        ev += [(t0 + k * beat + 0.5 * beat, chord(sr, 0.15)) for k in range(4)]   # skank
        ev += [(t0 + k * beat / 2, hihat(sr)) for k in range(8)]
    return place(sr, bars * 4 * beat + 3.0, ev)


def dub_techno(sr, bars=2, bpm=118):
    beat = 60.0 / bpm
    ev = []
    for b in range(bars):
        t0 = b * 4 * beat
        ev += [(t0 + k * beat + 0.5 * beat, chord(sr)) for k in (0, 1.5, 3)]
        ev += [(t0 + k * beat / 2 + beat / 4, hihat(sr)) for k in range(8)]
    return place(sr, bars * 4 * beat + 3.0, ev)


MATERIAL = {
    "rimshot": lambda sr: place(sr, 4.0, [(0.05, rimshot(sr))]),
    "snare": lambda sr: place(sr, 4.0, [(0.05, snare(sr))]),
    "hihats": lambda sr: place(sr, 3.0, [(0.05 + 0.25 * k, hihat(sr)) for k in range(6)]),
    "bass_stab": lambda sr: place(sr, 4.0, [(0.05, bass_stab(sr))]),
    "dubtechno_chords": dub_techno,
    "sustained_synth": lambda sr: place(sr, 5.0, [(0.05, pad(sr))]),
    "reggae_pattern": reggae_pattern,
}
