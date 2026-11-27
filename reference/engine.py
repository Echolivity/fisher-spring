"""Echolivity reference DSP engine (Python + numba).

This is the specification implementation: the gen~ code in device/ is a
line-by-line port of the per-sample kernels below, and the automated tests in
tests/ run against this file.

Signal flow (per block of B samples):

  dry ─┬──────────────────────────────────────────────┐
       └► mono ─► INPUT DRIVE ─► PREDELAY ─► ENGINES ─► wet
                                                        ▼
            TONE ─► WIDTH ─► OUTPUT COLORATION ─► MIX(dry) ─► OUTPUT
"""
import math
import numpy as np
from numba import njit

from .params import clamp_params

BLOCK = 256           # processing block
N_AP = 64             # allpass stages per spring
TINY = 1e-15          # denormal flush threshold
MAX_IR_S = 4.0        # IR length cap (device CPU budget)
# spring geometry: Fisher K-10 manual gives one-way 29 / 37 ms -> round trips 58 / 74 ms.
# Tension 0.44 reproduces it; range 80 ms (slack) .. 30 ms (tight).
LOOP_MAX = 0.080
# Output-side voicing. REC_LP: K-10 recovery amp, closed loop (circuit analysis).
# TANK_HP / TANK_LP: tank transducers, fitted to the K-10 IR (tools/fit_k10_tank.py).
REC_LP = 13000.0
TANK_HP = 200.0
TANK_LP = 8000.0
LOOP_RANGE = 0.050
SPRING_RATIO = 37.0 / 29.0
DECAY_CAL = 1.15      # residual loss compensation (damping LP, interpolation)


def conv_latency(sr):
    """Latency of the device's gen~ convolver: zero (direct-form head + partitions
    whose latency equals their offset in the IR; see device/gen/ech_conv.genexpr)."""
    return 0


# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------
@njit(cache=True, inline="always")
def _onepole_coef(fc, sr):
    return 1.0 - math.exp(-2.0 * math.pi * fc / sr)


@njit(cache=True, inline="always")
def _asym_sat(x, k, b):
    """Asymmetric tanh, unity small-signal gain, zero output at zero input.
    The bias b produces even harmonics (valve/transformer-like), not just odd."""
    tb = math.tanh(k * b)
    sech2 = 1.0 - tb * tb
    return (math.tanh(k * (x + b)) - tb) / (k * sech2)


@njit(cache=True, inline="always")
def _flush(x):
    return 0.0 if abs(x) < TINY else x


@njit(cache=True, inline="always")
def _cubic_read(buf, wpos, d):
    """Read buf (circular, len n) d samples behind write position wpos
    (wpos = index of most recently written sample), cubic Hermite."""
    n = buf.shape[0]
    rp = wpos - d
    i = int(math.floor(rp))
    f = rp - i
    xm1 = buf[(i - 1) % n]
    x0 = buf[i % n]
    x1 = buf[(i + 1) % n]
    x2 = buf[(i + 2) % n]
    c1 = 0.5 * (x1 - xm1)
    c2 = xm1 - 2.5 * x0 + 2.0 * x1 - 0.5 * x2
    c3 = 0.5 * (x2 - xm1) + 1.5 * (x0 - x1)
    return ((c3 * f + c2) * f + c1) * f + x0


# ----------------------------------------------------------------------------
# Input drive stage
# ----------------------------------------------------------------------------
@njit(cache=True)
def input_stage(x, st, sr, drive):
    """x: mono block. st: [pre_lp, deemph_lp, dc_x, dc_y]. Returns driven block.

    Pre-emphasis (HF lifted by up to ~8 dB) -> soft asymmetric tanh blending into
    a harder knee above 60% drive -> matching de-emphasis -> DC block.
    The emphasis/de-emphasis pair makes distortion frequency dependent: treble
    clips first, as in a tank driver feeding a reactive transducer."""
    out = np.empty_like(x)
    a_pe = _onepole_coef(1500.0, sr)
    pe = 1.5 * drive
    k = 10.0 ** (drive * 30.0 / 20.0)
    makeup = k ** -0.8
    h = min(max((drive - 0.6) / 0.4, 0.0), 1.0)
    r_dc = 1.0 - 2.0 * math.pi * 10.0 / sr
    for n in range(x.shape[0]):
        s = x[n]
        st[0] += a_pe * (s - st[0])
        xe = s + pe * (s - st[0])
        soft = _asym_sat(k * xe, 1.0, 0.15)
        kx = k * xe
        hard = kx / (1.0 + abs(kx) ** 6) ** (1.0 / 6.0)
        y = ((1.0 - h) * soft + h * hard) * makeup
        st[1] += a_pe * (y - st[1])
        y = st[1] + (y - st[1]) / (1.0 + pe)
        dc = y - st[2] + r_dc * st[3]
        st[2] = y
        st[3] = _flush(dc)
        out[n] = st[3]
    st[0] = _flush(st[0]); st[1] = _flush(st[1])
    return out


# ----------------------------------------------------------------------------
# Physical spring model
# ----------------------------------------------------------------------------
# state layout (float64 vector, see SpringState)
S_DELAY_SM = 0     # 2: smoothed delay (samples) per spring
S_G_SM = 2         # 1: smoothed loop gain
S_HP = 3           # 2: input band-limit states (hp lp, lp)
S_ENVF = 5
S_ENVS = 6
S_SW_X = 7         # sway oscillator state x
S_SW_V = 8         # sway oscillator state v
S_SLAP = 9
S_WOB = 10         # 2: wobble noise LP per spring
S_WOB2 = 12        # 2: second LP stage
S_LFO = 14         # lfo phase
S_DAMP = 15        # 2: in-loop damping LP
S_PK = 17          # 4: peak biquad states (2 per spring, TDF2)
S_SPL = 21         # 2: splash noise filter states
S_DC = 23          # 4: output dc blockers (x, y) per spring
S_SR = 27          # 2: second tank-feed HP state (59 Hz)
S_RNG = 29         # rng state
S_REC = 30         # 6: tank transducer states per spring (HP, LP, LP)
S_REC2 = 36        # 2: recovery-amp closed-loop LP per spring
S_LEN = 38


@njit(cache=True)
def _rand(st):
    # xorshift-ish LCG in float state, deterministic -> reproducible tests
    v = int(st[S_RNG]) & 0xFFFFFFFF
    v = (1664525 * v + 1013904223) & 0xFFFFFFFF
    st[S_RNG] = v
    return v / 4294967296.0


@njit(cache=True)
def spring_process(x, outL, outR, st, bufs, wpos_arr, apbuf, apidx, sr, prm):
    """Two coupled dispersive springs, mono in, stereo out.

    prm: [decay_s, damping, boing, tension, dispersion, resonance, movement, modulation]
    bufs: (2, Nbuf) loop delay lines; apbuf: (2, N_AP, Kmax) stretched-allpass states.
    """
    decay, damping, boing, tension, dispersion, resonance, movement, modulation = (
        prm[0], prm[1], prm[2], prm[3], prm[4], prm[5], prm[6], prm[7])
    tank_hp, tank_lp, rec_lp = prm[8], prm[9], prm[10]
    K = max(1, int(round(sr / 22050.0)))          # stretch keeps chirp shape SR-independent
    nb = bufs.shape[1]
    a0 = -(0.45 + 0.35 * dispersion)
    loop_s = LOOP_MAX - LOOP_RANGE * tension
    ratios = (1.0, SPRING_RATIO)
    ap_dc = N_AP * K * (1.0 - a0) / (1.0 + a0)    # group delay of cascade at DC
    # effective loop time at 400 Hz (the cascade delays lows far more than mids)
    cw = math.cos(K * 2.0 * math.pi * 400.0 / sr)
    tau_1k = K * (1.0 - a0 * a0) / (1.0 + 2.0 * a0 * cw + a0 * a0)
    loop_eff = (max(loop_s * sr - ap_dc, 8.0) + N_AP * tau_1k) / sr
    g_t = 10.0 ** (-3.0 * loop_eff / (DECAY_CAL * decay))
    # resonant mode (gain-normalised peak inside the loop => loop gain never > g)
    fr = 900.0 + 2100.0 * tension
    # resonance = how much faster everything *except* the mode decays:
    # off-mode RT60 = decay / (1 + 2*resonance). Per-pass extra loss in dB:
    gdb = 60.0 * loop_eff * 2.0 * resonance / decay
    A = 10.0 ** (gdb / 40.0)
    w0 = 2.0 * math.pi * fr / sr
    alpha = math.sin(w0) / (2.0 * 1.5)
    b0 = 1 + alpha * A; b1 = -2 * math.cos(w0); b2 = 1 - alpha * A
    a1 = -2 * math.cos(w0); a2 = 1 - alpha / A; a0n = 1 + alpha / A
    norm = 1.0 / (A * A)                          # peak gain = A^2
    b0 /= a0n; b1 /= a0n; b2 /= a0n; a1 /= a0n; a2 /= a0n
    c_damp = _onepole_coef(1500.0 + 9500.0 * (1.0 - damping) ** 2, sr)
    # Fisher K-10 voicing (service manual component values, see docs/FISHER_K10.md)
    c_hp = _onepole_coef(300.0, sr)     # C1 220 pF -> R3 2.2 M (tank feed)
    c_lp = _onepole_coef(59.0, sr)      # C3 2.7 nF -> R7 1 M
    # Output side. The K-10 recovery amp (V2a/V2b) has ~15 dB of global feedback
    # (680 k || 12 pF to V2a's cathode), which flattens its interstage filters: the
    # whole stage is ~flat, -2 dB at 8 kHz (tests/k10_recovery_circuit.py). The
    # treble loss heard in the real K-10 IR comes from the tank's transducers, so
    # that part is a fitted filter (TANK_*), not a circuit value.
    c_r1 = _onepole_coef(tank_hp, sr)
    c_r2 = _onepole_coef(min(tank_lp, 0.45 * sr), sr)
    c_r3 = _onepole_coef(min(rec_lp, 0.45 * sr), sr)
    c_envf = _onepole_coef(1.0 / (2 * math.pi * 0.001), sr)
    c_envs = _onepole_coef(1.0 / (2 * math.pi * 0.060), sr)
    slap_dec = math.exp(-1.0 / (0.12 * sr))
    # sway: damped oscillator at 6 Hz, ~0.4 s decay (spring swinging in the can)
    w_sw = 2 * math.pi * 6.0 / sr
    r_sw = math.exp(-1.0 / (0.4 * sr))
    c_wob = _onepole_coef(0.7, sr)
    lfo_inc = 2 * math.pi * (0.2 + 0.9 * modulation) / sr
    c_spl_hp = _onepole_coef(2500.0, sr)
    c_spl_lp = _onepole_coef(6000.0, sr)
    theta = 0.12
    cth, sth = math.cos(theta), math.sin(theta)
    cw1 = math.cos(K * 2.0 * math.pi * 1000.0 / sr)
    ap_1k = N_AP * K * (1.0 - a0 * a0) / (1.0 + 2.0 * a0 * cw1 + a0 * a0)
    out_scale = math.sqrt(max(1.0 - g_t * g_t, 1e-4)) * 5.5
    r_dc = 1.0 - 2.0 * math.pi * 10.0 / sr
    sm = 1.0 - math.exp(-1.0 / (0.02 * sr))       # 20 ms parameter smoothing
    jolt_p = movement * 0.4 / sr
    wpos = wpos_arr[0]
    api = apidx[0]

    for n in range(x.shape[0]):
        s_in = x[n]
        # tank feed high-passes (K-10: ~300 Hz and 59 Hz, first order)
        st[S_HP] += c_hp * (s_in - st[S_HP])
        hp = s_in - st[S_HP]
        st[S_SR] += c_lp * (hp - st[S_SR])
        xin = hp - st[S_SR]
        # transient detector -> slap + sway excitation
        ax = abs(s_in)
        st[S_ENVF] += c_envf * (ax - st[S_ENVF])
        st[S_ENVS] += c_envs * (ax - st[S_ENVS])
        tr = st[S_ENVF] - 1.5 * st[S_ENVS]
        if tr < 0.0:
            tr = 0.0
        hit = min(tr * 8.0, 1.0)
        if _rand(st) < jolt_p:                    # mechanical jolt (instability)
            hit = max(hit, 0.3 + 0.4 * _rand(st))
        st[S_SLAP] = max(st[S_SLAP] * slap_dec, hit)
        slap = st[S_SLAP]
        # sway oscillator (rotation, decaying), kicked by hits
        sx = st[S_SW_X]; sv = st[S_SW_V]
        nx = r_sw * (math.cos(w_sw) * sx - math.sin(w_sw) * sv) + hit * 0.02
        nv = r_sw * (math.sin(w_sw) * sx + math.cos(w_sw) * sv)
        st[S_SW_X] = _flush(nx); st[S_SW_V] = _flush(nv)
        sway = min(max(nx * 10.0, -1.0), 1.0)
        # LFO
        st[S_LFO] += lfo_inc
        if st[S_LFO] > 2 * math.pi:
            st[S_LFO] -= 2 * math.pi
        # smoothed loop gain
        st[S_G_SM] += sm * (g_t - st[S_G_SM])
        g = st[S_G_SM]
        # splash noise (band-passed, gated by slap and input level)
        nz = _rand(st) * 2.0 - 1.0
        st[S_SPL] += c_spl_hp * (nz - st[S_SPL])
        st[S_SPL + 1] += c_spl_lp * ((nz - st[S_SPL]) - st[S_SPL + 1])
        splash = st[S_SPL + 1] * boing * slap * st[S_ENVS] * 1.5
        # wobble noise per spring (two-pole LP random walk)
        for sp in range(2):
            st[S_WOB + sp] += c_wob * ((_rand(st) * 2 - 1) - st[S_WOB + sp])
            st[S_WOB2 + sp] += c_wob * (st[S_WOB + sp] - st[S_WOB2 + sp])

        # read both delay lines, couple them (orthogonal rotation = lossless)
        ys = np.empty(2)
        outs = np.empty(2)
        ds = np.empty(2)
        for sp in range(2):
            wob = st[S_WOB2 + sp] * 40.0          # ~unit range
            lfo = math.sin(st[S_LFO] + sp * 0.5 * math.pi)
            mod = (1.0 + 0.006 * movement * wob + 0.004 * modulation * lfo
                   + 0.03 * boing * sway * (1.0 if sp == 0 else -0.8))
            d_t = loop_s * ratios[sp] * sr * mod - ap_dc
            if d_t < 8.0:
                d_t = 8.0
            if d_t > nb - 8:
                d_t = nb - 8.0
            st[S_DELAY_SM + sp] += sm * (d_t - st[S_DELAY_SM + sp])
            ds[sp] = st[S_DELAY_SM + sp]
            ys[sp] = _cubic_read(bufs[sp], wpos, ds[sp])
            # output transducer: one-way trip = half the round trip incl. half the dispersion
            outs[sp] = _cubic_read(bufs[sp], wpos, max(1.0, 0.5 * (ds[sp] - ap_1k)))
        c0 = cth * ys[0] + sth * ys[1]
        c1 = -sth * ys[0] + cth * ys[1]
        cs = (c0, c1)

        wpos = (wpos + 1) % nb
        a_mod = a0 * (1.0 + 0.04 * movement * st[S_WOB2] * 40.0)
        if a_mod < -0.9:
            a_mod = -0.9
        for sp in range(2):
            v = xin + g * cs[sp] + splash
            # dispersion: cascade of stretched allpasses (a + z^-K)/(1 + a z^-K)
            for i in range(N_AP):
                wd = apbuf[sp, i, api]                # w[n-K]
                w = v - a_mod * wd
                v = a_mod * w + wd
                apbuf[sp, i, api] = _flush(w)
            # frequency-dependent damping
            st[S_DAMP + sp] += c_damp * (v - st[S_DAMP + sp])
            v = st[S_DAMP + sp]
            # resonant mode (TDF2 biquad), normalised
            z1 = st[S_PK + 2 * sp]; z2 = st[S_PK + 2 * sp + 1]
            yb = b0 * v + z1
            st[S_PK + 2 * sp] = _flush(b1 * v - a1 * yb + z2)
            st[S_PK + 2 * sp + 1] = _flush(b2 * v - a2 * yb)
            v = yb * norm
            # loop nonlinearity + collision: saturation threshold drops on hard hits
            thr = 1.0 - 0.7 * boing * slap
            if thr < 0.25:
                thr = 0.25
            v = thr * math.tanh(v / thr)
            bufs[sp, wpos] = _flush(v)
            # recovery amplifier voicing (K-10 V2 interstage network)
            r = S_REC + 3 * sp
            o = outs[sp]
            st[r] += c_r1 * (o - st[r]); o = o - st[r]                 # transducer HP
            st[r + 1] += c_r2 * (o - st[r + 1]); o = st[r + 1]         # transducer LP (2nd order)
            st[r + 2] += c_r2 * (o - st[r + 2]); o = st[r + 2]
            q = S_REC2 + sp
            st[q] += c_r3 * (o - st[q]); o = st[q]                     # recovery amp (closed loop)
            # output DC block
            o = o * out_scale
            dc = o - st[S_DC + 2 * sp] + r_dc * st[S_DC + 2 * sp + 1]
            st[S_DC + 2 * sp] = o
            st[S_DC + 2 * sp + 1] = _flush(dc)
            if sp == 0:
                outL[n] = dc
            else:
                outR[n] = dc
        api = (api + 1) % K
    wpos_arr[0] = wpos
    apidx[0] = api
    for i in range(S_LEN - 1):
        st[i] = _flush(st[i])



# ----------------------------------------------------------------------------
# Output section
# ----------------------------------------------------------------------------
@njit(cache=True)
def output_stage(wL, wR, dL, dR, oL, oR, st, sr, tone, width, drive, mix, out_db):
    """st: [tiltL, tiltR, dcxL, dcyL, dcxR, dcyR]"""
    c_t = _onepole_coef(900.0, sr)
    gl = 10.0 ** (-6.0 * tone / 40.0)
    gh = 10.0 ** (6.0 * tone / 40.0)
    k = 1.0 + 2.0 * drive
    gw = math.sin(0.5 * math.pi * mix)
    gd = math.cos(0.5 * math.pi * mix)
    go = 10.0 ** (out_db / 20.0)
    r_dc = 1.0 - 2.0 * math.pi * 10.0 / sr
    for n in range(wL.shape[0]):
        st[0] += c_t * (wL[n] - st[0])
        st[1] += c_t * (wR[n] - st[1])
        l = st[0] * gl + (wL[n] - st[0]) * gh
        r = st[1] * gl + (wR[n] - st[1]) * gh
        m = 0.5 * (l + r); s = 0.5 * (l - r) * width
        l = m + s; r = m - s
        # output coloration (transformer-ish even harmonics, scales with drive)
        l = _asym_sat(l, k, 0.1)
        r = _asym_sat(r, k, 0.1)
        dcl = l - st[2] + r_dc * st[3]; st[2] = l; st[3] = _flush(dcl)
        dcr = r - st[4] + r_dc * st[5]; st[4] = r; st[5] = _flush(dcr)
        oL[n] = (gd * dL[n] + gw * st[3]) * go
        oR[n] = (gd * dR[n] + gw * st[5]) * go
    for i in range(6):
        st[i] = _flush(st[i])


# ----------------------------------------------------------------------------
# Convolution: uniformly partitioned overlap-save (same algorithm as the
# Max pfft~ engine), zero added latency in offline block processing.
# ----------------------------------------------------------------------------
class PartitionedConvolver:
    def __init__(self, ir, B=BLOCK, latency=0):
        """ir: (n,) or (n, 2) float array at engine sample rate.
        latency: optional extra output delay in samples (the device adds none)."""
        self.lat = np.zeros((latency, 2))
        ir = np.atleast_2d(np.asarray(ir, dtype=np.float64).T).T
        if ir.shape[1] == 1:
            ir = np.repeat(ir, 2, axis=1)
        self.B = B
        K = int(math.ceil(ir.shape[0] / B))
        padded = np.zeros((K * B, 2))
        padded[: ir.shape[0]] = ir
        parts = padded.reshape(K, B, 2)
        z = np.zeros((K, 2 * B, 2))
        z[:, :B] = parts
        self.H = np.fft.rfft(z, axis=1)               # (K, B+1, 2)
        self.fdl = np.zeros((K, B + 1), dtype=np.complex128)
        self.prev = np.zeros(B)
        self.K = K
        self.pos = 0

    def process(self, x):
        B = self.B
        X = np.fft.rfft(np.concatenate([self.prev, x]))
        self.prev = x.copy()
        self.pos = (self.pos - 1) % self.K
        self.fdl[self.pos] = X
        idx = (self.pos + np.arange(self.K)) % self.K
        F = self.fdl[idx]
        Y = np.einsum("kb,kbc->bc", F, self.H)
        y = np.fft.irfft(Y, axis=0)[B:]
        if self.lat.shape[0]:
            buf = np.concatenate([self.lat, y])
            y, self.lat = buf[:B], buf[B:]
        return y[:, 0], y[:, 1]


def prepare_ir(ir, ir_sr, sr, decay, damping, predelay_ms=0.0, normalize="energy"):
    """IR conditioning (mirrored by device/code/ir_loader.js):
    resample -> decay/damping envelope -> normalisation.
    Decay can only shorten: extra exponential decay toward target RT60.
    Damping adds extra decay to the band above 2 kHz."""
    from scipy.signal import resample_poly
    ir = np.atleast_2d(np.asarray(ir, dtype=np.float64).T).T
    if ir_sr != sr:
        g = math.gcd(int(ir_sr), int(sr))
        ir = resample_poly(ir, int(sr) // g, int(ir_sr) // g, axis=0)
    if ir.shape[0] > int(MAX_IR_S * sr):          # device cap: 4 s, 50 ms fade
        ir = ir[: int(MAX_IR_S * sr)].copy()
        f = int(0.05 * sr)
        ir[-f:] *= (np.arange(f)[::-1] / f)[:, None]
    n = ir.shape[0]
    t = np.arange(n) / sr
    rt_ir = estimate_rt60(ir.mean(axis=1), sr)
    extra = max(0.0, 6.91 * (1.0 / decay - 1.0 / max(rt_ir, 1e-3)))
    # band split with forward-backward one-pole (zero phase)
    c = 1.0 - math.exp(-2 * math.pi * 2000.0 / sr)
    lo = _fb_onepole(ir, c)
    hi = ir - lo
    env_lo = np.exp(-extra * t)[:, None]
    env_hi = np.exp(-(extra + damping * 6.91 / 0.6) * t)[:, None]
    out = lo * env_lo + hi * env_hi
    if normalize == "energy":
        out /= math.sqrt(np.sum(out ** 2) / out.shape[1]) + 1e-12
    elif normalize == "peak":
        out /= np.max(np.abs(out)) + 1e-12
    return out, rt_ir


def _fb_onepole(x, c):
    y = np.empty_like(x)
    s = np.zeros(x.shape[1])
    for i in range(x.shape[0]):
        s += c * (x[i] - s); y[i] = s
    s = np.zeros(x.shape[1])
    for i in range(x.shape[0] - 1, -1, -1):
        s += c * (y[i] - s); y[i] = s
    return y


def estimate_rt60(x, sr):
    """Schroeder backward integration, T20 fit (-5 .. -25 dB) extrapolated."""
    e = np.cumsum((x[::-1] ** 2))[::-1]
    if e[0] <= 0:
        return 0.0
    edc = 10 * np.log10(e / e[0] + 1e-30)
    i5 = np.argmax(edc <= -5.0)
    i25 = np.argmax(edc <= -25.0)
    if i25 <= i5:
        return len(x) / sr
    t = np.arange(i5, i25) / sr
    slope = np.polyfit(t, edc[i5:i25], 1)[0]
    return -60.0 / slope if slope < 0 else float("inf")


# ----------------------------------------------------------------------------
# Device
# ----------------------------------------------------------------------------
class Echolivity:
    def __init__(self, sr, params=None, ir=None, ir_sr=None, seed=1):
        self.sr = float(sr)
        self.p = clamp_params(params or {})
        self.ir_raw = ir
        self.ir_sr = ir_sr or sr
        self.max_loop = int(LOOP_MAX * SPRING_RATIO * sr * 1.1) + 64
        self.bufs = np.zeros((2, self.max_loop))
        K = max(1, int(round(sr / 22050.0)))
        self.apbuf = np.zeros((2, N_AP, K))
        self.apidx = np.zeros(1, dtype=np.int64)
        self.wpos = np.zeros(1, dtype=np.int64)
        self.sst = np.zeros(S_LEN)
        self.sst[S_RNG] = seed * 2654435761 % 4294967296
        self.sst[S_G_SM] = 0.0
        self.ist = np.zeros(4)
        self.ost = np.zeros(6)
        self.pd_buf = np.zeros(int(0.26 * sr) + BLOCK)
        self.pd_w = 0
        self._init_delay_sm()
        self.conv = None
        self._ir_key = None
        self._update_ir()

    def _init_delay_sm(self):
        t = self.p["tension"]; a0 = -(0.45 + 0.35 * self.p["dispersion"])
        K = max(1, int(round(self.sr / 22050.0)))
        apdc = N_AP * K * (1 - a0) / (1 + a0)
        loop_s = LOOP_MAX - LOOP_RANGE * t
        self.sst[S_DELAY_SM] = loop_s * self.sr - apdc
        self.sst[S_DELAY_SM + 1] = loop_s * SPRING_RATIO * self.sr - apdc

    def _update_ir(self):
        if self.ir_raw is None:
            self.conv = None
            return
        key = (round(self.p["decay"], 3), round(self.p["damping"], 3))
        if key == self._ir_key:
            return
        ir, self.ir_rt60 = prepare_ir(self.ir_raw, self.ir_sr, self.sr,
                                      self.p["decay"], self.p["damping"])
        self.conv = PartitionedConvolver(ir, latency=conv_latency(self.sr))
        self._ir_key = key

    def set(self, **kw):
        p = dict(self.p); p.update(kw)
        self.p = clamp_params(p)
        self._update_ir()

    def _spring(self, x, decay_scale=1.0):
        p = self.p
        oL = np.empty_like(x); oR = np.empty_like(x)
        prm = np.array([p["decay"] * decay_scale, p["damping"], p["boing"], p["tension"],
                        p["dispersion"], p["resonance"], p["movement"], p["modulation"],
                        TANK_HP, TANK_LP, REC_LP])
        spring_process(x, oL, oR, self.sst, self.bufs, self.wpos, self.apbuf, self.apidx,
                       self.sr, prm)
        return oL, oR

    def _predelay(self, x):
        n = self.pd_buf.shape[0]
        d = int(round(self.p["predelay"] * 1e-3 * self.sr))
        idx = (self.pd_w + np.arange(len(x))) % n
        self.pd_buf[idx] = x
        out = self.pd_buf[(idx - d) % n]
        self.pd_w = (self.pd_w + len(x)) % n
        return out

    def process_block(self, L, R):
        p = self.p
        mono = 0.5 * (L + R)
        e = input_stage(mono, self.ist, self.sr, p["drive"])
        e = self._predelay(e)
        mode = p["engine_mode"]
        irg = 10 ** (p["ir_level"] / 20); mdg = 10 ** (p["model_level"] / 20)
        b = p["blend"]
        have_ir = self.conv is not None
        if not have_ir and mode != 1:
            # no IR loaded: IR mode is silent, hybrid modes fall back to the model
            if mode == 0:
                wL, wR = np.zeros_like(e), np.zeros_like(e)
            else:
                wL, wR = self._spring(e); wL = wL * mdg; wR = wR * mdg
        elif mode == 0:
            wL, wR = self.conv.process(e); wL = wL * irg; wR = wR * irg
        elif mode == 1:
            wL, wR = self._spring(e); wL = wL * mdg; wR = wR * mdg
        elif mode == 2:
            cL, cR = self.conv.process(e)
            sL, sR = self._spring(e)
            gi = math.cos(0.5 * math.pi * b) * irg
            gm = math.sin(0.5 * math.pi * b) * mdg
            wL = gi * cL + gm * sL; wR = gi * cR + gm * sR
        elif mode == 3:   # IR -> Model: model adds sway/splash/movement to the real tank
            cL, cR = self.conv.process(e)
            cL *= irg; cR *= irg
            sL, sR = self._spring(0.5 * (cL + cR), decay_scale=0.3)
            sL *= mdg; sR *= mdg
            wL = (1 - b) * cL + b * sL; wR = (1 - b) * cR + b * sR
        else:             # Model -> IR: model excites the real tank
            sL, sR = self._spring(e, decay_scale=0.3)
            sL *= mdg; sR *= mdg
            cL, cR = self.conv.process(0.5 * (sL + sR) + 0.5 * e)
            cL *= irg; cR *= irg
            wL = (1 - b) * sL + b * cL; wR = (1 - b) * sR + b * cR
        oL = np.empty_like(e); oR = np.empty_like(e)
        output_stage(wL, wR, L, R, oL, oR, self.ost, self.sr, p["tone"], p["width"],
                     p["drive"], p["mix"], p["output"])
        return oL, oR

    def process(self, x, automation=None):
        """x: (n,) or (n,2). automation: optional callable(block_index, self)."""
        x = np.asarray(x, dtype=np.float64)
        if x.ndim == 1:
            x = np.stack([x, x], axis=1)
        n = x.shape[0]
        nb = int(math.ceil(n / BLOCK))
        pad = np.zeros((nb * BLOCK, 2)); pad[:n] = x
        out = np.zeros_like(pad)
        for i in range(nb):
            if automation is not None:
                automation(i, self)
            s = slice(i * BLOCK, (i + 1) * BLOCK)
            oL, oR = self.process_block(pad[s, 0].copy(), pad[s, 1].copy())
            out[s, 0] = oL; out[s, 1] = oR
        return out[:n]
