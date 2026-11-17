"""Echolivity parameter table: the single source of truth.

Shared by the Python reference engine, the preset files, and the
Max for Live device (exported to device/params.json by tools/export_params.py).

Each entry: name -> (min, max, default, unit, section, description)
"""

PARAMS = {
    # --- Core -----------------------------------------------------------
    "drive":       (0.0, 1.0, 0.25, "",   "Core", "Input drive into the tank driver stage. Pre-emphasised: highs saturate first, hard-clip character above ~60%."),
    "decay":       (0.3, 8.0, 2.0,  "s",  "Core", "RT60 of the spring model. For the IR engine it shortens the IR below its natural length (it can't lengthen it)."),
    "tone":        (-1.0, 1.0, 0.0, "",   "Core", "Wet tilt EQ around 900 Hz, +/-6 dB."),
    "damping":     (0.0, 1.0, 0.8,  "",   "Core", "High-frequency decay: in-loop low-pass for the model, faster HF fade on the IR."),
    "mix":         (0.0, 1.0, 0.35, "",   "Core", "Equal-power dry/wet. Use 100% on a return track."),
    "output":      (-24.0, 6.0, 0.0, "dB", "Core", "Output level after coloration."),
    # --- Spring character ----------------------------------------------
    "boing":       (0.0, 1.0, 0.4,  "",   "Spring", "Transient-triggered spring sway (pitch swing), splash noise and collision clatter."),
    "tension":     (0.0, 1.0, 0.44, "",   "Spring", "Spring length/tension: round trip 80 ms (slack) to 30 ms (tight); 0.44 = Fisher K-10 (58 / 74 ms). Also moves the resonant mode."),
    "dispersion":  (0.0, 1.0, 0.55, "",   "Spring", "Strength of the dispersive chirp (64 stretched allpasses, coefficient -0.45 to -0.80)."),
    "resonance":   (0.0, 1.0, 0.35, "",   "Spring", "Emphasis of the dominant spring mode: everything else decays up to 3x faster than the mode."),
    "movement":    (0.0, 1.0, 0.3,  "",   "Spring", "Mechanical instability: random drift of length and stiffness plus occasional jolts."),
    # --- Hybrid ----------------------------------------------------------
    "engine_mode": (0, 4, 2, "enum", "Hybrid", "0 IR, 1 Model, 2 Parallel, 3 IR>Model, 4 Model>IR."),
    "ir_level":    (-24.0, 6.0, 0.0, "dB", "Hybrid", "Convolution engine level."),
    "model_level": (-24.0, 6.0, 0.0, "dB", "Hybrid", "Physical model level."),
    "blend":       (0.0, 1.0, 0.5,  "",   "Hybrid", "Parallel: equal-power IR<->Model crossfade. Serial: unprocessed 1st engine <-> through both."),
    # --- Dub -------------------------------------------------------------
    "feedback":    (0.0, 1.0, 0.0,  "",   "Dub", "Regenerative return of the wet signal into the tank."),
    "fb_tone":     (-1.0, 1.0, 0.0, "",   "Dub", "Feedback band position: dark/thin (-1) to bright (+1)."),
    "fb_drive":    (0.0, 1.0, 0.2,  "",   "Dub", "Asymmetric saturation inside the feedback loop."),
    "fb_damping":  (0.0, 1.0, 0.3,  "",   "Dub", "Per-repeat high-frequency loss in the feedback loop."),
    "self_osc":    (0.0, 1.0, 0.0,  "",   "Dub", "Lifts loop gain above unity and disables the runaway guard proportionally."),
    # --- Advanced --------------------------------------------------------
    "predelay":    (0.0, 250.0, 0.0, "ms", "Advanced", "Delay before both engines (inside the feedback loop)."),
    "width":       (0.0, 2.0, 1.0,  "",   "Advanced", "Wet stereo width (mid/side)."),
    "modulation":  (0.0, 1.0, 0.15, "",   "Advanced", "Periodic, quadrature LFO on spring length (slow chorus) - distinct from Movement's random drift."),
}

ENGINE_MODES = ["IR", "Model", "Parallel", "IR>Model", "Model>IR"]


def defaults():
    return {k: v[2] for k, v in PARAMS.items()}


def clamp_params(p):
    out = defaults()
    for k, v in p.items():
        if k not in PARAMS:
            raise KeyError(f"unknown parameter {k}")
        lo, hi = PARAMS[k][0], PARAMS[k][1]
        out[k] = min(max(v, lo), hi)
    out["engine_mode"] = int(round(out["engine_mode"]))
    return out
