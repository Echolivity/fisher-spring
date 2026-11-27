"""Port check for the Max convolution path (no Max needed):

1. Runs device/code/ech_ir_loader.js under Node (mocked Max API) and compares its
   conditioned IR (head taps + mid/tail partition spectra) with reference prepare_ir().
2. Runs the actual device/gen/ech_conv.genexpr, translated line by line to Python
   (genexpr_py), fed with the js-built H buffer, and compares it with direct
   convolution at zero latency.

This verifies the algorithms and data layout of the Max port. It does NOT prove
the GenExpr compiles in Max or what it costs there - that stays open until run in Live.
"""
import json, math, os, subprocess, sys, tempfile
import numpy as np
import soundfile as sf
from scipy.signal import fftconvolve

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, ROOT)
from reference.engine import prepare_ir  # noqa


def run_js(ir, irsr, hostsr, decay, damping):
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "ir.f32"); o = os.path.join(d, "out.json")
        ir.astype(np.float32).tofile(p)
        subprocess.run(["node", os.path.join(HERE, "js_harness.js"), p, str(ir.shape[1]), str(irsr),
                        str(hostsr), str(decay), str(damping), o], check=True)
        return json.load(open(o))


def layout(B):
    """H buffer layout written by ech_ir_loader.js (see ech_conv.genexpr)."""
    F, BM, T0 = 128, 64, 4 * B
    KM = (T0 - F) // BM
    return F, BM, T0, KM, F + KM * (BM + 1) * 2


def rebuild_ir(H, B, K):
    """Inverse of what the loader wrote: head taps + mid and tail partitions -> time domain."""
    F, BM, T0, KM, offT = layout(B)
    out = []
    for ch in range(2):
        seg = [H[ch][:F]]
        for k in range(KM):
            X = H[ch][F + k * (BM + 1) * 2:F + (k + 1) * (BM + 1) * 2]
            seg.append(np.fft.irfft(X[0::2] + 1j * X[1::2], 2 * BM)[:BM])
        for k in range(K):
            X = H[ch][offT + k * (B + 1) * 2:offT + (k + 1) * (B + 1) * 2]
            seg.append(np.fft.irfft(X[0::2] + 1j * X[1::2], 2 * B)[:B])
        out.append(np.concatenate(seg))
    return np.stack(out, 1)


def run_gen_conv(H, bsize, nparts, x, sr):
    """The actual ech_conv.genexpr, translated line by line (genexpr_py)."""
    sys.path.insert(0, HERE)
    from genexpr_py import load
    Conv, _, _ = load(os.path.join(ROOT, "device/gen/ech_conv.genexpr"), "Conv")
    g = Conv(sr, np.random.default_rng(0))
    g.H.a = np.stack([np.asarray(H[0], float), np.asarray(H[1], float)], 1)
    g.bsize = float(bsize); g.nparts = float(nparts)
    return np.array([g.tick(v)[:2] for v in x])


def main():
    res = {}
    ok = True
    ir_full, irsr = sf.read(os.path.join(ROOT, "ir", "originals", "synthetic", "SYN_ShortTank3S_B.wav"), always_2d=True)
    cases = [(0.5, 48000, 8.0, 0.0), (0.5, 44100, 1.0, 0.6), (0.5, 96000, 2.0, 0.3),
             (0.02, 48000, 2.0, 0.3)]          # 20 ms IR: shorter than the tail offset, head + mid only
    for secs, hostsr, decay, damping in cases:
        ir = ir_full[: int(secs * irsr)]         # keep the Python transliteration quick
        js = run_js(ir, irsr, hostsr, decay, damping)
        msgs = {m[1]: m[2] for m in js["outs"] if m[0] == 0}
        B = int(msgs["bsize"]); K = int(msgs["nparts"])
        ref, _ = prepare_ir(ir, irsr, hostsr, decay, damping)
        H = [np.array(js["H"][0]), np.array(js["H"][1])]
        rec = rebuild_ir(H, B, K)
        n = min(len(rec), len(ref))
        err_ir = float(np.max(np.abs(rec[:n] - ref[:n])) / np.max(np.abs(ref)))
        covered = len(rec) >= len(ref) and float(np.max(np.abs(rec[n:]), initial=0)) < 1e-12 * float(np.max(np.abs(ref)))
        rng = np.random.default_rng(0)
        x = rng.standard_normal(len(ref) + 8 * B) * 0.1
        y = run_gen_conv(H, B, K, x, hostsr)
        dref = np.stack([fftconvolve(x, rec[:, c])[:len(x)] for c in range(2)], 1)
        err_conv = float(np.max(np.abs(y - dref)) / np.max(np.abs(dref)))
        # latency: lag of the impulse response's peak, device vs IR
        imp = np.zeros(len(ref) + 8 * B); imp[0] = 1.0
        yi = run_gen_conv(H, B, K, imp, hostsr) if secs < 0.1 else None
        lat = int(np.argmax(np.abs(yi[:, 0])) - np.argmax(np.abs(rec[:, 0]))) if yi is not None else None
        r = {"B": B, "K_tail": K, "js_ms": js["ms"], "ir_vs_reference_max_rel_err": err_ir,
             "ir_fully_covered": covered, "gen_conv_vs_direct_max_rel_err": err_conv, "impulse_peak_lag_samples": lat,
             "note": "error is against convolution with NO delay, so it also proves zero latency"}
        res[f"{hostsr}Hz_{secs}s_decay{decay}_damp{damping}"] = r
        # resampler differs (Lanczos-8 in js vs polyphase in scipy) -> tolerance when resampling
        tol_ir = 1e-4 if hostsr == irsr else 3e-2
        ok &= err_ir < tol_ir and covered and err_conv < 1e-9 and lat in (0, None)
        print(hostsr, r, flush=True)
    os.makedirs(os.path.join(ROOT, "reports"), exist_ok=True)
    json.dump({"passed": bool(ok), "results": res}, open(os.path.join(ROOT, "reports", "port_check_conv.json"), "w"), indent=2)
    print("PASS" if ok else "FAIL")
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
