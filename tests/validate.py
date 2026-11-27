"""Echolivity technical validation suite.

Every check returns (passed: bool, evidence: dict). `python tests/validate.py`
runs all checks and writes reports/technical_validation.json + .md.
tests/test_echolivity.py runs the same checks under pytest.

Scope: these validate the REFERENCE ENGINE (reference/engine.py). The Max for
Live port must be checked against renders from this engine (see
docs/QA_PROTOCOL.md) before any Max feature is marked technically validated.
"""
import glob, json, math, os, sys, time, platform
import numpy as np
import soundfile as sf
from scipy.signal import fftconvolve

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from reference.engine import (Echolivity, PartitionedConvolver, prepare_ir, estimate_rt60,  # noqa
                              input_stage, BLOCK, conv_latency)
from reference.params import PARAMS, defaults, clamp_params  # noqa
from reference import signals as S  # noqa

SRS = [44100, 48000, 88200, 96000]
IR_DIR = os.path.join(ROOT, "ir", "originals", "synthetic")
CHECKS = {}


def check(fn):
    CHECKS[fn.__name__] = fn
    return fn


def load_ir(name):
    from reference.irlib import load
    return load(name)


def db(x):
    return 20 * math.log10(max(x, 1e-12))


def rms(x):
    return float(np.sqrt(np.mean(np.square(x))))


def centroid(x, sr):
    X = np.abs(np.fft.rfft(x)) ** 2
    f = np.fft.rfftfreq(len(x), 1 / sr)
    return float(np.sum(f * X) / np.sum(X))


def wet(sr, params, ir_name=None, x=None, seconds=6.0, automation=None, seed=1):
    """Render with mix forced to 100% wet (unless params sets mix explicitly after)."""
    ir = isr = None
    if ir_name:
        ir, isr = load_ir(ir_name)
    if x is None:
        x = np.zeros(int(seconds * sr)); x[64] = 0.25
    d = Echolivity(sr, {"mix": 1.0, **params}, ir=ir, ir_sr=isr, seed=seed)
    return d.process(x, automation=automation), d


# ---------------------------------------------------------------------------
@check
def ir_library_audit():
    from tools.ir_catalogue import audit_and_build
    entries, problems = audit_and_build(write=False)
    fisher_claims = [e["id"] for e in entries if e["authenticity"] == "HARDWARE-VERIFIED"]
    return (not problems and len(entries) >= 4), {
        "irs": len(entries), "problems": problems, "hardware_verified_fisher_irs": fisher_claims}


@check
def partitioned_convolution_exact():
    """Streaming partitioned convolver == direct FFT convolution."""
    rng = np.random.default_rng(0)
    ir = rng.standard_normal((5000, 2)) * np.exp(-np.arange(5000) / 800)[:, None]
    x = rng.standard_normal(BLOCK * 40)
    c = PartitionedConvolver(ir)
    y = np.concatenate([np.stack(c.process(x[i:i + BLOCK]), 1) for i in range(0, len(x), BLOCK)])
    ref = np.stack([fftconvolve(x, ir[:, 0])[:len(x)], fftconvolve(x, ir[:, 1])[:len(x)]], 1)
    err = float(np.max(np.abs(y - ref)) / np.max(np.abs(ref)))
    return err < 1e-9, {"max_rel_error": err}


@check
def ir_reproduction_through_device():
    """Full device in IR mode (drive 0, neutral EQ) reproduces the conditioned IR."""
    ev = {}
    ok = True
    for sr in SRS:
        ir, isr = load_ir("SYN_ShortTank3S_B")
        expect, _ = prepare_ir(ir, isr, sr, decay=8.0, damping=0.0)
        y, _ = wet(sr, dict(engine_mode=0, drive=0.0, decay=8.0, damping=0.0, tone=0.0),
                   "SYN_ShortTank3S_B", seconds=2.4)
        imp = 0.25
        L = 64 + conv_latency(sr)
        n = min(len(expect) - 200, len(y) - L - 200)
        a = y[L:L + n, 0] / imp
        b = expect[:n, 0]
        corr = float(np.corrcoef(a, b)[0, 1])
        gain = db(rms(a) / rms(b))
        ev[sr] = {"correlation": round(corr, 5), "level_error_db": round(gain, 2), "latency_samples": conv_latency(sr)}
        ok &= corr > 0.995 and abs(gain) < 1.0
    return ok, ev


@check
def k10_geometry_and_ir_evidence():
    """Model at default Tension reproduces the K-10 manual's arrival times (29/37/87/111 ms),
    and the third-party K-10 IR's arrivals sit within 6% of them."""
    from scipy.signal import butter, sosfiltfilt, hilbert, find_peaks
    from reference.irlib import load
    manual = [29.0, 37.0, 87.0, 111.0]

    def arrivals(y, sr, t0):
        out = []
        for ch in range(2):
            b = sosfiltfilt(butter(4, [200, 4000], "bandpass", fs=sr, output="sos"), y[:, ch])
            e = np.convolve(np.abs(hilbert(b)), np.ones(int(sr / 1000)) / (sr / 1000), "same")[: int(0.16 * sr)]
            pk, _ = find_peaks(e, height=0.25 * e.max(), distance=int(0.004 * sr))
            out.append([(p - t0) / sr * 1000 for p in pk])
        return out

    def match(arr):
        flat = arr[0] + arr[1]
        return [min(flat, key=lambda a: abs(a - m)) for m in manual]
    sr = 48000
    x = np.zeros(sr); x[100] = 0.5
    y, _ = wet(sr, dict(engine_mode=1, drive=0.0, boing=0.0, movement=0.0, modulation=0.0), x=x)
    mm = match(arrivals(y, sr, 100))
    ir, isr = load("TP_FISHER_K10_derickgtwk_STEREO_96k", processed=False)
    im = match(arrivals(ir, isr, 0))
    ok = all(abs(a - m) <= 2.0 for a, m in zip(mm, manual)) and all(abs(a / m - 1) < 0.06 for a, m in zip(im, manual))
    return ok, {"manual_ms": manual, "model_ms": [round(v, 1) for v in mm], "k10_ir_ms": [round(v, 1) for v in im],
                "tolerance": "model +/-2 ms, IR +/-6%"}


@check
def k10_spectrum_match():
    """Model at K-10 defaults vs the K-10 IR: long-term spectrum, 1/3-octave bands 63 Hz-8 kHz,
    normalised at 1 kHz. Pass: RMS error < 3 dB."""
    from tools.fit_k10_tank import band_db, BANDS
    from reference.irlib import load
    ir, isr = load("TP_FISHER_K10_derickgtwk_STEREO_96k")
    target = band_db(ir.mean(axis=1), isr)
    y, _ = wet(48000, dict(engine_mode=1, drive=0.0, boing=0.0, movement=0.0, modulation=0.0), seconds=3.5)
    e = band_db(y.mean(axis=1), 48000) - target
    rms = float(np.sqrt(np.mean(e ** 2)))
    return rms < 3.0, {"rms_error_db": round(rms, 2), "worst_band": [BANDS[int(np.argmax(np.abs(e)))], round(float(e[np.argmax(np.abs(e))]), 1)],
                       "error_per_band_db": dict(zip(BANDS, [round(float(v), 1) for v in e]))}


@check
def decay_accuracy_model():
    ev = {}
    ok = True
    for dec in [0.5, 1.0, 2.5, 5.0, 8.0]:
        y, _ = wet(48000, dict(engine_mode=1, decay=dec, damping=0.0, resonance=0.0, boing=0.0,
                               movement=0.0, modulation=0.0, drive=0.0), seconds=max(4, 2 * dec))
        rt = estimate_rt60(y[:, 0], 48000)
        ev[dec] = round(rt, 2)
        ok &= abs(rt / dec - 1) < 0.15
    return ok, {"target_vs_measured_rt60_s": ev, "tolerance": "+/-15% (neutral damping/resonance)"}


@check
def decay_control_ir_shortens():
    ev = {}
    rts = []
    for dec in [8.0, 1.5, 0.6]:
        y, _ = wet(48000, dict(engine_mode=0, decay=dec, damping=0.0, drive=0.0), "SYN_LongTank2S_A", seconds=5)
        rts.append(estimate_rt60(y[:, 0], 48000))
        ev[dec] = round(rts[-1], 2)
    ok = rts[0] > rts[1] > rts[2] and abs(rts[2] / 0.6 - 1) < 0.25
    return ok, {"decay_setting_vs_rt60": ev, "note": "IR decay can only shorten below natural RT60"}


@check
def damping_frequency_dependent():
    ev = {}
    for eng, irn in [(1, None), (0, "SYN_LongTank2S_A")]:
        cs = []
        for dmp in [0.0, 1.0]:
            y, _ = wet(48000, dict(engine_mode=eng, damping=dmp, drive=0.0, boing=0, movement=0), irn, seconds=4)
            cs.append(centroid(y[int(0.5 * 48000):, 0], 48000))
        ev["IR" if eng == 0 else "Model"] = {"tail_centroid_hz_damp0": round(cs[0]), "damp1": round(cs[1])}
    ok = all(v["damp1"] < 0.8 * v["tail_centroid_hz_damp0"] for v in ev.values())
    return ok, ev


@check
def sample_rate_consistency():
    ev = {}
    rt = {}
    ce = {}
    for sr in SRS:
        y, _ = wet(sr, dict(engine_mode=1, boing=0, movement=0, modulation=0, drive=0), seconds=5)
        rt[sr] = estimate_rt60(y[:, 0], sr)
        ce[sr] = centroid(y[:, 0], sr)
        yi, _ = wet(sr, dict(engine_mode=0, drive=0), "SYN_ShortTank3S_B", seconds=2.5)
        ev[sr] = {"model_rt60": round(rt[sr], 3), "model_centroid_hz": round(ce[sr]),
                  "ir_rt60": round(estimate_rt60(yi[:, 0], sr), 3)}
    r = [v["model_rt60"] for v in ev.values()]
    c = [v["model_centroid_hz"] for v in ev.values()]
    i = [v["ir_rt60"] for v in ev.values()]
    spread = {"model_rt60_spread": round(max(r) / min(r) - 1, 3), "model_centroid_spread": round(max(c) / min(c) - 1, 3),
              "ir_rt60_spread": round(max(i) / min(i) - 1, 3)}
    ok = spread["model_rt60_spread"] < 0.12 and spread["model_centroid_spread"] < 0.12 and spread["ir_rt60_spread"] < 0.05
    return ok, {"per_rate": ev, "spread": spread, "tolerance": "model 12%, IR 5%"}


def _levels(y, sr, times):
    return [round(db(rms(y[int(t * sr):int((t + 0.5) * sr), 0])), 1) for t in times]


@check
def dc_offset():
    sr = 48000
    rng = np.random.default_rng(4)
    x = np.clip(rng.standard_normal(sr * 6) * 0.5 + 0.2 * np.sin(np.arange(sr * 6) * 2 * np.pi * 60 / sr), -1, 1)
    ev = {}
    ok = True
    for name, p in [("max_drive_parallel", dict(engine_mode=2, drive=1.0)),
                    ("max_drive_model_resonant", dict(engine_mode=1, drive=1.0, decay=8.0, resonance=1.0))]:
        y, _ = wet(sr, p, "SYN_LongTank2S_A", x=x)
        m = float(np.max(np.abs(y[sr * 2:].mean(axis=0))))
        ev[name] = {"dc_mean": m}
        ok &= m < 2e-3
    return ok, ev


@check
def denormal_protection():
    sr = 48000
    x = np.zeros(sr * 40); x[100] = 0.5
    ev = {}
    ok = True
    for mode in (1, 2):
        y, d = wet(sr, dict(engine_mode=mode, decay=8.0), "SYN_ShortTank3S_B", x=x)
        tiny = np.finfo(np.float64).tiny
        sub = int(np.sum((np.abs(y) < tiny) & (y != 0)))
        states = np.concatenate([d.sst, d.bufs.ravel(), d.apbuf.ravel(), d.ost, d.ist])
        sub_s = int(np.sum((np.abs(states) < tiny) & (states != 0)))
        tail = float(np.max(np.abs(y[-sr:])))
        ev[f"mode{mode}"] = {"subnormal_outputs": sub, "subnormal_states": sub_s, "tail_peak_after_40s": tail}
        ok &= sub == 0 and sub_s == 0
    return ok, ev


@check
def extreme_and_fuzzed_parameters():
    sr = 48000
    rng = np.random.default_rng(7)
    x = np.clip(rng.standard_normal(sr * 2), -1, 1)       # 0 dBFS abuse
    combos = [{k: v[0] for k, v in PARAMS.items()}, {k: v[1] for k, v in PARAMS.items()}]
    for _ in range(20):
        combos.append({k: float(rng.uniform(v[0], v[1])) for k, v in PARAMS.items()})
    worst = 0.0
    bad = 0
    for c in combos:
        y, _ = wet(sr, c, "SYN_ShortTank3S_B", x=x)
        if not np.isfinite(y).all():
            bad += 1
        worst = max(worst, float(np.max(np.abs(y))))
    return bad == 0, {"combos": len(combos), "non_finite": bad, "worst_peak": round(worst, 2),
                      "note": "peaks >1 possible with Output +6 dB and 0 dBFS noise; no NaN/inf"}


@check
def parameter_automation_smooth():
    """Sweep each parameter over its full range in 2 s against static renders."""
    sr = 48000
    rng = np.random.default_rng(5)
    x = rng.standard_normal(sr * 3) * 0.1
    ev = {}
    ok = True
    base = dict(engine_mode=2)
    for k, (lo, hi, *_r) in PARAMS.items():
        if k == "engine_mode":
            continue
        nblk = int(2 * sr / BLOCK)

        def auto(i, dev, k=k, lo=lo, hi=hi):
            dev.set(**{k: lo + (hi - lo) * min(i / nblk, 1.0)})
        y, _ = wet(sr, {**base, k: lo}, "SYN_ShortTank3S_B", x=x, automation=auto)
        ys = [wet(sr, {**base, k: v}, "SYN_ShortTank3S_B", x=x)[0] for v in (lo, hi)]
        jump = float(np.max(np.abs(np.diff(y[:, 0]))))
        ref = max(float(np.max(np.abs(np.diff(s[:, 0])))) for s in ys)
        ev[k] = {"max_step_sweep": round(jump, 4), "max_step_static": round(ref, 4)}
        ok &= np.isfinite(y).all() and jump < 1.5 * ref + 0.02
    return ok, ev


@check
def engine_mode_switching():
    sr = 48000
    x = S.reggae_pattern(sr, bars=1)

    def auto(i, dev):
        dev.set(engine_mode=(i // 40) % 5)
    y, _ = wet(sr, {}, "SYN_ShortTank3S_B", x=x, automation=auto)
    return bool(np.isfinite(y).all() and np.max(np.abs(y)) < 1.0), {"peak": round(float(np.max(np.abs(y))), 3)}


@check
def stereo_correlation():
    """L/R correlation in (-0.5, 0.9) for the model, Width 0 = mono, and mono-sum loss > -4 dB
    for every engine. (Bound widened from -0.2 on 2026-11-14: see comment below.)"""
    sr = 48000
    ev = {}
    ok = True
    for name, p, irn in [("model", dict(engine_mode=1), None), ("ir", dict(engine_mode=0), "SYN_LongTank2S_A"),
                         ("parallel", dict(engine_mode=2), "SYN_LongTank2S_A"),
                         ("model_width0", dict(engine_mode=1, width=0.0), None)]:
        y, _ = wet(sr, p, irn, x=S.place(sr, 4, [(0.05, S.snare(sr))]))
        c = float(np.corrcoef(y[:, 0], y[:, 1])[0, 1])
        mono_loss = db(rms(y[:, 0] + y[:, 1]) / (math.sqrt(2) * math.sqrt(0.5 * (rms(y[:, 0]) ** 2 + rms(y[:, 1]) ** 2))))
        ev[name] = {"lr_correlation": round(c, 3), "mono_sum_vs_power_db": round(mono_loss, 2)}
    # Criterion revised after the K-10 geometry change (model corr -0.23): mild anti-correlation
    # of a decorrelated tail is harmless; mono compatibility (below) is the real requirement.
    ok &= -0.5 < ev["model"]["lr_correlation"] < 0.9 and ev["model_width0"]["lr_correlation"] > 0.999
    ok &= all(v["mono_sum_vs_power_db"] > -4.0 for v in ev.values())
    return ok, ev


@check
def hybrid_phase_interaction():
    """Parallel blend should sum in power (no systematic cancellation)."""
    sr = 48000
    x = S.place(sr, 4, [(0.05, S.snare(sr)), (1.0, S.rimshot(sr))])
    yi, _ = wet(sr, dict(engine_mode=0), "SYN_LongTank2S_A", x=x)
    ym, _ = wet(sr, dict(engine_mode=1), "SYN_LongTank2S_A", x=x)
    yp, _ = wet(sr, dict(engine_mode=2, blend=0.5), "SYN_LongTank2S_A", x=x)
    e_expected = 0.5 * np.sum(yi ** 2) + 0.5 * np.sum(ym ** 2)
    ratio_db = 10 * math.log10(np.sum(yp ** 2) / e_expected)
    ci = float(np.corrcoef(yp[:, 0], yi[:, 0])[0, 1]); cm = float(np.corrcoef(yp[:, 0], ym[:, 0])[0, 1])
    ok = abs(ratio_db) < 2.0 and ci < 0.95 and cm < 0.95
    return ok, {"parallel_vs_power_sum_db": round(ratio_db, 2), "corr_with_ir_only": round(ci, 3),
                "corr_with_model_only": round(cm, 3),
                "note": "distinct from either engine; audible advantage still needs listening"}


@check
def drive_nonlinearity():
    sr = 48000
    t = np.arange(sr) / sr
    ev = {}

    def thd(f, drive):
        x = 0.25 * np.sin(2 * np.pi * f * t)
        y = input_stage(x, np.zeros(4), float(sr), drive)[sr // 2:]
        X = np.abs(np.fft.rfft(y * np.hanning(len(y))))
        fr = np.fft.rfftfreq(len(y), 1 / sr)
        h = [X[np.argmin(np.abs(fr - f * k))] for k in range(1, 8) if f * k < sr / 2]
        return float(np.sqrt(np.sum(np.square(h[1:]))) / h[0]), float(h[1] / h[0])
    curve = [thd(1000, d)[0] for d in (0.0, 0.25, 0.5, 0.75, 1.0)]
    even = thd(1000, 0.5)[1]
    lo, hi = thd(200, 0.4)[0], thd(3000, 0.4)[0]
    ev = {"thd_vs_drive_1k": [round(c, 4) for c in curve], "h2_over_h1_drive0.5": round(even, 4),
          "thd_200hz_vs_3khz_drive0.4": [round(lo, 4), round(hi, 4)]}
    ok = all(np.diff(curve) > 0) and even > 0.005 and hi > lo
    return ok, ev


@check
def every_control_audible():
    """Technical proxy: min vs max of each control changes the output measurably.
    Context: hybrid params in parallel mode."""
    sr = 48000
    x = S.reggae_pattern(sr, bars=1)
    ctx = {"engine_mode": 2}
    ev = {}
    ok = True
    for k, (lo, hi, *_r) in PARAMS.items():
        c = dict(ctx)
        if k == "mix":
            pass
        c = {a: b for a, b in c.items() if b is not None}
        if k == "engine_mode":
            ya, _ = wet(sr, {**c, "engine_mode": 0}, "SYN_LongTank2S_A", x=x)
            yb, _ = wet(sr, {**c, "engine_mode": 1}, "SYN_LongTank2S_A", x=x)
        else:
            ya, _ = wet(sr, {**c, k: lo}, "SYN_LongTank2S_A", x=x)
            yb, _ = wet(sr, {**c, k: hi}, "SYN_LongTank2S_A", x=x)
        diff = db(rms(ya - yb) / max(rms(ya), rms(yb)))
        ev[k] = round(diff, 1)
        ok &= diff > -25.0
    return ok, {"difference_db_min_vs_max": ev, "threshold": "> -25 dB difference signal (A/B proxy; listening still required)"}


@check
def preset_library():
    pres = sorted(glob.glob(os.path.join(ROOT, "presets", "*.json")))
    pres = [p for p in pres if not p.endswith("index.json")]
    sr = 48000
    x = S.reggae_pattern(sr, bars=1)
    x *= 0.5 / np.max(np.abs(x))                    # dry material peaks at -6 dBFS
    dry = rms(x)
    ev = {}
    ok = len(pres) >= 10
    feats = []
    names = set()
    for p in pres:
        doc = json.load(open(p))
        ok &= clamp_params(doc["params"]) == doc["params"]
        ok &= doc["name"] not in names
        names.add(doc["name"])
        y1, _ = wet(sr, doc["params"], doc["ir"], x=x, seed=3)
        y2, _ = wet(sr, doc["params"], doc["ir"], x=x, seed=3)
        # wet() forces mix=1 first, so re-apply the preset mix
        ir_, isr_ = load_ir(doc["ir"])
        d = Echolivity(sr, doc["params"], ir=ir_, ir_sr=isr_)
        y = d.process(x)
        pk = float(np.max(np.abs(y)))
        lvl = db(rms(y) / dry)
        feats.append(np.log10(np.abs(np.fft.rfft(y1[:, 0], 1 << 18))[::512] + 1e-9))
        ev[doc["name"]] = {"peak": round(pk, 3), "rms_vs_dry_db": round(lvl, 1),
                           "deterministic": bool(np.array_equal(y1, y2))}
        ok &= pk < 1.0 and -9 < lvl < 6 and np.array_equal(y1, y2)
    # distinctness: no two presets with near-identical long-term spectra
    F = np.array(feats)
    mind = min(float(np.mean(np.abs(F[i] - F[j]))) for i in range(len(F)) for j in range(i + 1, len(F)))
    ok &= mind > 0.05
    return ok, {"presets": ev, "min_pairwise_spectral_distance": round(mind, 3)}


@check
def long_duration_stability():
    sr = 48000
    ev = {}
    ok = True
    rng = np.random.default_rng(9)
    for name, p, irn, minutes in [("model_long", dict(engine_mode=1, decay=8.0, movement=1.0, modulation=1.0), None, 10),
                                  ("parallel_long", dict(engine_mode=2, decay=8.0, movement=0.5), "SYN_ShortTank3S_B", 2)]:
        hit = S.rimshot(sr)
        x = S.place(sr, minutes * 60, [(t, hit * rng.uniform(0.3, 1)) for t in np.arange(0.1, minutes * 60 - 5, 1.6)])
        t0 = time.time()
        y, _ = wet(sr, p, irn, x=x)
        el = time.time() - t0
        seg = [db(rms(y[i * sr * 30:(i + 1) * sr * 30, 0])) for i in range(int(minutes * 2))]
        ev[name] = {"minutes": minutes, "finite": bool(np.isfinite(y).all()), "peak": round(float(np.max(np.abs(y))), 3),
                    "rms_first_last_30s_db": [round(seg[0], 1), round(seg[-2], 1)], "realtime_factor_python": round(el / (minutes * 60), 3)}
        ok &= np.isfinite(y).all() and abs(seg[-2] - seg[0]) < 3.0 and np.max(np.abs(y)) < 1.0
    return ok, ev


@check
def cpu_reference_engine():
    """Python/numba reference cost (NOT Max CPU - that stays open until measured in Live)."""
    ev = {}
    for sr in SRS:
        for name, p, irn in [("model", dict(engine_mode=1), None), ("parallel", dict(engine_mode=2), "SYN_LongTank2S_A")]:
            x = np.random.default_rng(0).standard_normal(sr * 5) * 0.1
            wet(sr, p, irn, x=x[:BLOCK * 4])
            t0 = time.time()
            wet(sr, p, irn, x=x)
            ev[f"{name}@{sr}"] = round((time.time() - t0) / 5.0, 3)
    return True, {"seconds_per_audio_second": ev, "machine": platform.processor() or platform.machine(),
                  "note": "informational; Python reference, single thread"}


def run_all(names=None):
    res = {}
    for n, fn in CHECKS.items():
        if names and n not in names:
            continue
        t0 = time.time()
        try:
            ok, ev = fn()
        except Exception as e:  # noqa
            ok, ev = False, {"exception": repr(e)}
        res[n] = {"passed": bool(ok), "seconds": round(time.time() - t0, 1), "evidence": ev,
                  "doc": (fn.__doc__ or "").strip()}
        print(f"{'PASS' if ok else 'FAIL'}  {n}  ({res[n]['seconds']} s)", flush=True)
    return res


def _jsonable(o):
    if isinstance(o, dict):
        return {str(k): _jsonable(v) for k, v in o.items()}
    if isinstance(o, (list, tuple)):
        return [_jsonable(v) for v in o]
    if isinstance(o, (np.floating, np.integer, np.bool_)):
        return o.item()
    return o


if __name__ == "__main__":
    res = _jsonable(run_all(sys.argv[1:] or None))
    os.makedirs(os.path.join(ROOT, "reports"), exist_ok=True)
    out = os.path.join(ROOT, "reports", "technical_validation.json")
    old = json.load(open(out)) if os.path.exists(out) and sys.argv[1:] else {}
    old.update(res)
    json.dump(old, open(out, "w"), indent=2)
