"""Fit the tank-transducer filter (TANK_HP, TANK_LP) and the default Damping so the
physical model's long-term spectrum matches the Fisher K-10 IR at K-10 settings.

Only the tank part is fitted. The circuit parts (feed high-passes, recovery amp)
are fixed from the schematics. Writes reports/k10_tank_fit.json.
Run: python tools/fit_k10_tank.py
"""
import itertools, json, os, sys
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
import reference.engine as E  # noqa
from reference.irlib import load  # noqa

SR = 48000
BANDS = [63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000,
         2500, 3150, 4000, 5000, 6300, 8000]


def band_db(x, sr):
    X = np.abs(np.fft.rfft(x, 1 << 20)) ** 2
    f = np.fft.rfftfreq(1 << 20, 1 / sr)
    d = np.array([10 * np.log10(X[(f > b / 1.12) & (f < b * 1.12)].mean()) for b in BANDS])
    return d - d[BANDS.index(1000)]


def model_db(tank_hp, tank_lp, damping):
    E.TANK_HP, E.TANK_LP = tank_hp, tank_lp
    x = np.zeros(int(3.5 * SR)); x[64] = 0.25
    d = E.Echolivity(SR, dict(engine_mode=1, mix=1.0, drive=0.0, damping=damping, boing=0.0,
                              movement=0.0, modulation=0.0))
    y = d.process(x)
    return band_db(y.mean(axis=1), SR)


def main():
    ir, isr = load("TP_FISHER_K10_derickgtwk_STEREO_96k")
    target = band_db(ir.mean(axis=1), isr)
    best = None
    grid = itertools.product([150, 200, 250, 320, 400], [4500, 6000, 8000, 11000, 16000],
                             [0.5, 0.6, 0.7, 0.8, 0.9, 1.0])
    for hp, lp, dm in grid:
        e = model_db(hp, lp, dm) - target
        rms = float(np.sqrt(np.mean(e ** 2)))
        if best is None or rms < best[0]:
            best = (rms, hp, lp, dm, e)
    rms, hp, lp, dm, e = best
    # same check for the pre-correction voicing, for the record
    res = {"target_bands_hz": BANDS, "k10_ir_db": [round(v, 1) for v in target],
           "fit": {"TANK_HP": hp, "TANK_LP": lp, "damping_default": dm, "rms_error_db": round(rms, 2),
                   "error_per_band_db": [round(v, 1) for v in e]}}
    json.dump(res, open(os.path.join(ROOT, "reports", "k10_tank_fit.json"), "w"), indent=2)
    print(json.dumps(res["fit"]))


if __name__ == "__main__":
    main()
