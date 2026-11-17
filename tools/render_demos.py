"""Listening renders for the Dub Producer / Dub Organiser review (renders/).

renders/presets/<preset>__<material>.wav   every factory preset x core material
renders/engines/rimshot__<IR|Model|Parallel|IR>Model|Model>IR>.wav   hybrid A/B set
renders/feedback/<material>__fb<..>.wav     feedback & self-oscillation behaviour
All 48 kHz / 24-bit FLAC, rendered by the reference engine (= device DSP).
Material is synthesised (see reference/signals.py); judge with your own stems too.
"""
import glob, json, os, sys
import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from reference.engine import Echolivity  # noqa
from reference.params import ENGINE_MODES  # noqa
from reference import signals as S  # noqa

SR = 48000
OUT = os.path.join(ROOT, "renders")


def ir(name):
    from reference.irlib import load
    return load(name)


def write(path, y):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pk = np.max(np.abs(y))
    if pk > 0.98:
        y = y * 0.98 / pk
    sf.write(path.replace(".wav", ".flac"), y, SR, subtype="PCM_24")


def main():
    mats = {k: f(SR) for k, f in S.MATERIAL.items()}
    for k in mats:
        mats[k] = mats[k] * 0.5 / np.max(np.abs(mats[k]))
    for pf in sorted(glob.glob(os.path.join(ROOT, "presets", "*.json"))):
        if pf.endswith("index.json"):
            continue
        p = json.load(open(pf))
        x_ir, x_sr = ir(p["ir"])
        for m in ["rimshot", "snare", "reggae_pattern", "dubtechno_chords", "bass_stab", "sustained_synth"]:
            y = Echolivity(SR, p["params"], ir=x_ir, ir_sr=x_sr).process(np.r_[mats[m], np.zeros(SR * 2)])
            write(os.path.join(OUT, "presets", f"{p['number']:02d}_{p['name'].replace(' ', '_').replace('[', '').replace(']', '')}__{m}.wav"), y)
        print("preset", p["name"], flush=True)
    x_ir, x_sr = ir("TP_FISHER_K10_derickgtwk_STEREO_96k")
    for mode, name in enumerate(ENGINE_MODES):
        y = Echolivity(SR, dict(engine_mode=mode, mix=1.0, feedback=0.0), ir=x_ir, ir_sr=x_sr).process(mats["rimshot"])
        write(os.path.join(OUT, "engines", f"rimshot__{name.replace('>', '-to-')}.wav"), y)
    for m in ["rimshot", "snare", "bass_stab", "dubtechno_chords"]:
        x = S.place(SR, 12, [(0.1, mats[m][: SR])])
        for fb, osc in [(0.0, 0.0), (0.6, 0.0), (1.0, 0.0), (1.0, 0.5)]:
            y = Echolivity(SR, dict(engine_mode=2, mix=1.0, feedback=fb, self_osc=osc, fb_drive=0.5),
                           ir=x_ir, ir_sr=x_sr).process(x)
            write(os.path.join(OUT, "feedback", f"{m}__fb{fb}_osc{osc}.wav"), y)
    print("done")


if __name__ == "__main__":
    main()
