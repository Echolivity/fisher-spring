"""QA: compare a render bounced from Ableton Live with the reference engine.

1. python tools/compare_render.py --make-inputs     -> qa/inputs/*.wav (48 kHz test files)
2. In Live (48 kHz): put a qa input on an audio track, Echolivity on the track,
   load the preset named below, set Movement = Boing = 0 (removes randomness),
   export the track (24/32-bit, no normalise, no dither) as qa/bounced/<case>.wav
3. python tools/compare_render.py qa/bounced/<case>.wav --preset "03 DUB - Deep Dub Spring" --input impulse

Reports latency-aligned correlation and level difference. Pass: corr >= 0.99, |level| <= 0.5 dB.
(Feedback cases differ slightly by design: Live's vector size sets the feedback-loop latency.)
"""
import argparse, json, os, sys
import numpy as np
import soundfile as sf
from scipy.signal import correlate

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from reference.engine import Echolivity  # noqa
from reference import signals as S  # noqa

SR = 48000


def make_inputs():
    d = os.path.join(ROOT, "qa", "inputs"); os.makedirs(d, exist_ok=True)
    imp = np.zeros(SR * 6); imp[SR // 10] = 0.5
    sf.write(os.path.join(d, "impulse.wav"), np.stack([imp, imp], 1), SR, subtype="FLOAT")
    rim = S.place(SR, 6, [(0.1, S.rimshot(SR))])
    sf.write(os.path.join(d, "rimshot.wav"), np.stack([rim, rim], 1), SR, subtype="FLOAT")
    reg = S.reggae_pattern(SR, bars=2); reg *= 0.5 / np.max(np.abs(reg))
    sf.write(os.path.join(d, "reggae.wav"), np.stack([reg, reg], 1), SR, subtype="FLOAT")
    print("wrote", d)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bounce", nargs="?")
    ap.add_argument("--preset"); ap.add_argument("--input", default="impulse")
    ap.add_argument("--make-inputs", action="store_true")
    a = ap.parse_args()
    if a.make_inputs:
        return make_inputs()
    doc = json.load(open(os.path.join(ROOT, "presets", a.preset + ".json")))
    p = dict(doc["params"], movement=0.0, boing=0.0)
    from reference.irlib import load
    ir, isr = load(doc["ir"])
    x, sr = sf.read(os.path.join(ROOT, "qa", "inputs", a.input + ".wav"), always_2d=True)
    ref = Echolivity(sr, p, ir=ir, ir_sr=isr).process(x)
    live, lsr = sf.read(a.bounce, always_2d=True)
    assert lsr == sr, "bounce sample rate differs from input"
    n = min(len(ref), len(live))
    c = correlate(live[:n, 0], ref[:n, 0], mode="full", method="fft")
    lag = int(np.argmax(c)) - (n - 1)
    if lag >= 0:
        A, B = live[lag:n, 0], ref[: n - lag, 0]
    else:
        A, B = live[: n + lag, 0], ref[-lag:n, 0]
    corr = float(np.corrcoef(A, B)[0, 1])
    lvl = 20 * np.log10(np.sqrt(np.mean(A ** 2)) / np.sqrt(np.mean(B ** 2)))
    ok = corr >= 0.99 and abs(lvl) <= 0.5
    print(json.dumps({"lag_samples": lag, "correlation": round(corr, 5), "level_diff_db": round(float(lvl), 2),
                      "passed": ok}, indent=2))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
