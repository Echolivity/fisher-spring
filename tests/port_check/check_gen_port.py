"""Runs the actual device GenExpr (front -> [conv] -> back, translated to Python)
sample by sample and compares it with the reference engine.

Deterministic settings (movement = boing = 0, so gen~'s noise() has no effect).
Gains in gen~ are smoothed from 0, so the first 0.3 s are excluded.
"""
import json, os, sys
import numpy as np
import soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, ROOT); sys.path.insert(0, HERE)
from genexpr_py import load  # noqa
from reference.engine import Echolivity  # noqa
from reference import signals as S  # noqa
from check_conv_port import run_js  # noqa


def run_gen(x, sr, params, ir=None, irsr=None):
    Front, _, _ = load(os.path.join(ROOT, "device/gen/ech_front.genexpr"), "Front")
    Back, _, _ = load(os.path.join(ROOT, "device/gen/ech_back.genexpr"), "Back")
    rng = np.random.default_rng(0)
    f, b = Front(sr, rng), Back(sr, rng)
    conv = None
    if ir is not None:
        Conv, _, _ = load(os.path.join(ROOT, "device/gen/ech_conv.genexpr"), "Conv")
        js = run_js(ir, irsr, sr, params.get("decay", 2.5), params.get("damping", 0.35))
        msgs = {m[1]: m[2] for m in js["outs"] if m[0] == 0}
        conv = Conv(sr, rng)
        conv.H.a = np.stack([np.array(js["H"][0]), np.array(js["H"][1])], 1)
        conv.bsize = msgs["bsize"]; conv.nparts = msgs["nparts"]
        b.have_ir = 1.0
    from reference.params import defaults
    for k, v in {**defaults(), **params}.items():
        k = {"mix": "drywet"}.get(k, k)
        for o in (f, b):
            if hasattr(o, k):
                setattr(o, k, float(v))
    out = np.zeros((len(x), 2))
    spr = 0.0
    for n in range(len(x)):
        e, cin = f.tick(x[n], x[n], spr)[:2]
        cl = cr = 0.0
        if conv is not None:
            cl, cr = conv.tick(cin)[:2]
        o1, o2, spr = b.tick(x[n], x[n], e, cl, cr)[:3]
        out[n] = (o1, o2)
    return out


def check_param_defaults():
    import re
    from reference.params import PARAMS
    bad = []
    for f in ("ech_front", "ech_back"):
        src = open(os.path.join(ROOT, "device/gen", f + ".genexpr")).read()
        for name, val, lo, hi in re.findall(r"Param (\w+)\(([-\d.]+), min=([-\d.]+), max=([-\d.]+)\)", src):
            key = {"drywet": "mix"}.get(name, name)
            if key in PARAMS:
                plo, phi, pd = PARAMS[key][:3]
                if (float(val), float(lo), float(hi)) != (float(pd), float(plo), float(phi)):
                    bad.append(f"{f}:{name} ({val},{lo},{hi}) != params.py ({pd},{plo},{phi})")
    return bad


def main():
    res = {}
    bad = check_param_defaults()
    res["param_defaults_match"] = {"mismatches": bad}
    print("param defaults", bad or "OK")
    ok = not bad
    sr = 48000
    x = S.place(sr, 1.0, [(0.32, S.snare(sr)), (0.6, S.rimshot(sr))])
    base = dict(movement=0.0, boing=0.0, mix=1.0)
    cases = [("model_default", dict(engine_mode=1), None),
             ("model_drive_dark", dict(engine_mode=1, drive=0.8, decay=5.0, damping=0.7, tension=0.2,
                                       resonance=0.9, tone=-0.6, width=1.6, modulation=0.6, predelay=20.0), None),
             ("parallel_ir", dict(engine_mode=2, blend=0.5, decay=8.0, damping=0.0), "SYN_ShortTank3S_B"),
             ("ir_only", dict(engine_mode=0, decay=8.0, damping=0.0), "SYN_LongTank2S_A"),
             ("ir_to_model", dict(engine_mode=3, blend=0.6, decay=3.0, damping=0.3), "SYN_ShortTank3S_B")]
    for name, p, irn in cases:
        p = {**base, **p}
        ir = irsr = None
        if irn:
            ir, irsr = sf.read(os.path.join(ROOT, "ir/originals/synthetic", irn + ".wav"), always_2d=True)
            ir = ir[: int(0.4 * irsr)]
        ref = Echolivity(sr, p, ir=ir, ir_sr=irsr).process(x)
        gen = run_gen(x, sr, p, ir, irsr)
        s = int(0.3 * sr)
        err = float(np.max(np.abs(gen[s:] - ref[s:])) / (np.max(np.abs(ref[s:])) + 1e-12))
        corr = float(np.corrcoef(gen[s:, 0], ref[s:, 0])[0, 1])
        res[name] = {"max_rel_error": err, "correlation": corr}
        print(name, res[name], flush=True)
        ok &= corr > 0.999 and err < 0.02
    json.dump({"passed": bool(ok), "results": res}, open(os.path.join(ROOT, "reports", "port_check_gen.json"), "w"), indent=2)
    print("PASS" if ok else "FAIL")
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
