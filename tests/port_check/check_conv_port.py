"""Port check for the Max convolution path (no Max needed):

1. Runs device/code/ech_ir_loader.js under Node (mocked Max API) and compares its
   conditioned IR / partition spectra / ir_peak with reference prepare_ir().
2. Runs a line-by-line Python transliteration of device/gen/ech_conv.genexpr fed
   with the js-built spectra, and compares against direct convolution delayed 2B.

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


class GenConv:
    """Transliteration of ech_conv.genexpr (same variable names, same order)."""

    def __init__(self, H, B, K):
        self.H = H; self.B = B; self.K = K; N = 2 * B
        self.inb = np.zeros(2048); self.fdl = np.zeros(820000)
        self.acc = np.zeros((2050, 2)); self.outb = np.zeros((1024, 2))
        self.re = np.zeros(2048); self.im = np.zeros(2048)
        self.tw = np.stack([np.cos(2 * np.pi * np.arange(1024) / N), np.sin(2 * np.pi * np.arange(1024) / N)], 1)
        self.cnt = 0; self.pos = 0

    def fft(self, N, sgn):
        re, im, tw = self.re, self.im, self.tw
        j = 0
        for i in range(N - 1):
            if i < j:
                re[i], re[j] = re[j], re[i]; im[i], im[j] = im[j], im[i]
            m = N // 2
            while m >= 1 and j >= m:
                j -= m; m //= 2
            j += m
        ln = 2
        while ln <= N:
            half = ln // 2; step = N // ln
            k = np.arange(half)
            wr = tw[k * step, 0]; wi = sgn * tw[k * step, 1]
            for i in range(0, N, ln):
                pr = re[i + half:i + ln].copy(); pi2 = im[i + half:i + ln].copy()
                vr = pr * wr - pi2 * wi; vi = pr * wi + pi2 * wr
                ur = re[i:i + half].copy(); ui = im[i:i + half].copy()
                re[i:i + half] = ur + vr; im[i:i + half] = ui + vi
                re[i + half:i + ln] = ur - vr; im[i + half:i + ln] = ui - vi
            ln *= 2

    def tick(self, x):
        B, Kp, N = self.B, self.K, 2 * self.B
        c = self.cnt
        self.inb[B + c] = x
        o = self.outb[c].copy()
        if Kp > 0:
            k0 = (c * Kp) // B; k1 = ((c + 1) * Kp) // B
            for k in range(k0, k1):
                slot = (self.pos + k) % Kp
                fb = slot * (B + 1) * 2; hb = k * (B + 1) * 2
                xr = self.fdl[fb:fb + 2 * (B + 1):2]; xi = self.fdl[fb + 1:fb + 2 * (B + 1):2]
                for ch in range(2):
                    hr = self.H[ch][hb:hb + 2 * (B + 1):2]; hi = self.H[ch][hb + 1:hb + 2 * (B + 1):2]
                    self.acc[0:2 * (B + 1):2, ch] += xr * hr - xi * hi
                    self.acc[1:2 * (B + 1):2, ch] += xr * hi + xi * hr
        if c >= B - 1:
            for job in range(3):
                sgn = -1
                if job < 2:
                    sgn = 1
                    self.re[:B + 1] = self.acc[0:2 * (B + 1):2, job]; self.im[:B + 1] = self.acc[1:2 * (B + 1):2, job]
                    self.acc[:2 * (B + 1), job] = 0
                    for b in range(1, B):
                        self.re[N - b] = self.re[b]; self.im[N - b] = -self.im[b]
                else:
                    self.re[:N] = self.inb[:N]; self.im[:N] = 0
                self.fft(N, sgn)
                if job < 2:
                    self.outb[:B, job] = self.re[B:N] / N
                elif Kp > 0:
                    self.pos = (self.pos - 1 + Kp) % Kp
                    base = self.pos * (B + 1) * 2
                    self.fdl[base:base + 2 * (B + 1):2] = self.re[:B + 1]
                    self.fdl[base + 1:base + 2 * (B + 1):2] = self.im[:B + 1]
                    self.inb[:B] = self.inb[B:N].copy()
            self.cnt = 0
        else:
            self.cnt = c + 1
        return o


def main():
    res = {}
    ok = True
    ir, irsr = sf.read(os.path.join(ROOT, "ir", "originals", "synthetic", "SYN_ShortTank3S_B.wav"), always_2d=True)
    ir = ir[: int(0.5 * irsr)]                       # keep the Python transliteration quick
    for hostsr, decay, damping in [(48000, 8.0, 0.0), (44100, 1.0, 0.6), (96000, 2.0, 0.3)]:
        js = run_js(ir, irsr, hostsr, decay, damping)
        msgs = {m[1]: m[2] for m in js["outs"] if m[0] == 0}
        B = int(msgs["bsize"]); K = int(msgs["nparts"])
        ref, _ = prepare_ir(ir, irsr, hostsr, decay, damping)
        # reconstruct js time-domain IR from its partitions (inverse of what it wrote)
        H = [np.array(js["H"][0]), np.array(js["H"][1])]
        rec = []
        for ch in range(2):
            parts = []
            for k in range(K):
                X = H[ch][k * (B + 1) * 2:(k + 1) * (B + 1) * 2]
                parts.append(np.fft.irfft(X[0::2] + 1j * X[1::2], 2 * B)[:B])
            rec.append(np.concatenate(parts))
        rec = np.stack(rec, 1)[: len(ref)]
        n = min(len(rec), len(ref))
        err_ir = float(np.max(np.abs(rec[:n] - ref[:n])) / np.max(np.abs(ref)))
        pk_ref = float(np.max(np.abs(np.fft.rfft(ref.mean(axis=1), 1 << int(math.ceil(math.log2(len(ref))))))))
        pk_err = abs(msgs["ir_peak"] / pk_ref - 1)
        # gen~ transliteration vs direct convolution
        rng = np.random.default_rng(0)
        x = rng.standard_normal(B * 8 + K * B) * 0.1
        g = GenConv(H, B, K)
        y = np.array([g.tick(v) for v in x])
        L = 2 * B
        dref = np.stack([fftconvolve(x, rec[:, c])[:len(x)] for c in range(2)], 1)
        err_conv = float(np.max(np.abs(y[L:] - dref[:-L])) / np.max(np.abs(dref)))
        r = {"B": B, "K": K, "js_ms": js["ms"], "ir_vs_reference_max_rel_err": err_ir,
             "ir_peak_rel_err": pk_err, "gen_conv_vs_direct_max_rel_err": err_conv, "latency_samples": L}
        res[f"{hostsr}Hz_decay{decay}_damp{damping}"] = r
        # resampler differs (Lanczos-8 in js vs polyphase in scipy) -> tolerance when resampling
        tol_ir = 1e-4 if hostsr == irsr else 3e-2
        ok &= err_ir < tol_ir and pk_err < 0.05 and err_conv < 1e-9
        print(hostsr, r, flush=True)
    os.makedirs(os.path.join(ROOT, "reports"), exist_ok=True)
    json.dump({"passed": bool(ok), "results": res}, open(os.path.join(ROOT, "reports", "port_check_conv.json"), "w"), indent=2)
    print("PASS" if ok else "FAIL")
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
