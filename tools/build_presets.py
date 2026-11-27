"""Factory preset library -> presets/*.json + presets/index.json

Naming standard:  <NN> <Category> - <Name>
Categories (by musical application, Dub Organiser taxonomy):
  REF  Reference / authentic tank      PERC Drums & percussion
  DUB  Dub sends        TEX  Texture / experimental
Every preset states which IR it expects. IR-dependent presets fall back to the
model (hybrid modes) if the IR is missing; that fallback is documented.
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

P = [
    dict(n=1, cat="REF", name="Fisher Reference", ir="TP_FISHER_K10_derickgtwk_STEREO_96k",
         desc="Fisher K-10 Dynamic Spacexpander IR, convolution only, natural decay. Third-party IR (Freesound 528139); its arrival times (within 6%) and spectrum (within ~2 dB below 4 kHz) match the K-10 service manual, but it was not captured by this project.",
         tags=["neutral", "authentic", "send"],
         p=dict(engine_mode=0, drive=0.15, decay=8.0, damping=0.0, tone=0.0, mix=1.0, ir_level=0.0, predelay=0, width=1.0, tension=0.44, output=-2.0)),
    dict(n=2, cat="REF", name="Vintage Splash", ir="TP_BF_FenderDeluxe_MONO_44k",
         desc="Bright parallel hybrid: real-tank body with model boing and splash on hits. Guitar-amp style drip.",
         tags=["bright", "splash", "drip", "guitar"],
         p=dict(engine_mode=2, blend=0.45, drive=0.35, decay=2.2, damping=0.15, tone=0.35, boing=0.8, tension=0.55, dispersion=0.7, resonance=0.3, movement=0.25, mix=0.4, output=-3.0)),
    dict(n=3, cat="DUB", name="Deep Dub Spring", ir="TP_FISHER_K10_derickgtwk_STEREO_96k",
         desc="Long, warm send spring. The default rimshot/snare send.",
         tags=["send", "warm", "rimshot", "snare"],
         p=dict(engine_mode=2, blend=0.4, drive=0.3, decay=4.5, damping=0.45, tone=-0.25, boing=0.55, tension=0.35, dispersion=0.6, resonance=0.4, movement=0.3, mix=1.0, predelay=12, output=-6.0)),
    dict(n=4, cat="TEX", name="Metallic Resonance", ir="SYN_ShortTank3S_B",
         desc="Model-led, high resonance and dispersion: singing metallic mode, tuned by Tension.",
         tags=["metallic", "resonant", "synth"],
         p=dict(engine_mode=1, drive=0.2, decay=4.5, damping=0.1, tone=0.2, boing=0.3, tension=0.7, dispersion=0.9, resonance=0.95, movement=0.15, modulation=0.1, mix=0.4)),
    dict(n=5, cat="DUB", name="Heavy Pressure", ir="SYN_DarkTank2S_C",
         desc="Hard-driven tank - thick, compressed, distorted dub wall.",
         tags=["drive", "distortion", "bass", "loud"],
         p=dict(engine_mode=4, blend=0.6, drive=0.85, decay=3.5, damping=0.5, tone=-0.1, boing=0.5, tension=0.4, dispersion=0.5, resonance=0.5, movement=0.35, mix=0.45, output=-4.0)),
    dict(n=6, cat="REF", name="Dark Chamber", ir="SYN_DarkTank2S_C",
         desc="Dark, smooth tank - spring as a small room. Low splash, low movement.",
         tags=["dark", "smooth", "vocal", "keys"],
         p=dict(engine_mode=2, blend=0.3, drive=0.1, decay=3.0, damping=0.75, tone=-0.55, boing=0.1, tension=0.25, dispersion=0.4, resonance=0.15, movement=0.1, modulation=0.25, width=1.3, mix=0.35, predelay=25, output=-4.0)),
    dict(n=7, cat="DUB", name="Long Dub Tail", ir="TP_FISHER_K10_derickgtwk_STEREO_96k",
         desc="Longest decay on the K-10 tank in parallel with the model: an 8-second dub wash for throws. Ride Mix or the send.",
         tags=["long", "wash", "throw", "send"],
         p=dict(engine_mode=2, blend=0.5, drive=0.3, decay=8.0, damping=0.35, tone=-0.1, boing=0.45, tension=0.45, dispersion=0.6, resonance=0.45, movement=0.3, mix=1.0, output=-6.0)),
    dict(n=8, cat="TEX", name="Broken Spring", ir="SYN_SplashTank1S_D",
         desc="Max movement and boing: jolts, pitch lurches and clatter, like a tank on a shaking amp.",
         tags=["broken", "unstable", "lo-fi", "fx"],
         p=dict(engine_mode=3, blend=0.75, drive=0.55, decay=2.0, damping=0.3, tone=0.1, boing=1.0, tension=0.3, dispersion=0.8, resonance=0.6, movement=1.0, modulation=0.4, mix=0.5, output=-5.0)),
    dict(n=9, cat="PERC", name="Short Percussion Spring", ir="TP_MT_70sStereoSpring_01",
         desc="Short, tight, bright tank for hats, shakers and percussion loops. Keeps transients.",
         tags=["short", "tight", "percussion", "hats"],
         p=dict(engine_mode=2, blend=0.35, drive=0.15, decay=0.7, damping=0.25, tone=0.3, boing=0.35, tension=0.85, dispersion=0.45, resonance=0.25, movement=0.15, mix=0.3, width=1.4)),
    dict(n=10, cat="TEX", name="Experimental Mechanical", ir="SYN_DarkTank2S_C",
         desc="Model > IR with high resonance and slow modulation: grinding, mechanical textures from chords and pads.",
         tags=["drone", "mechanical", "experimental", "pads"],
         p=dict(engine_mode=4, blend=0.5, drive=0.6, decay=7.0, damping=0.2, tone=0.0, boing=0.7, tension=0.15, dispersion=1.0, resonance=0.8, movement=0.6, modulation=0.8, width=1.6, mix=0.5, output=-6.0)),
]


def main():
    import sys
    sys.path.insert(0, ROOT)
    from reference.params import defaults, clamp_params
    d = os.path.join(ROOT, "presets")
    os.makedirs(d, exist_ok=True)
    index = []
    for pr in P:
        full = clamp_params({**defaults(), **pr["p"]})
        fname = f"{pr['n']:02d} {pr['cat']} - {pr['name']}.json"
        doc = {"name": pr["name"], "number": pr["n"], "category": pr["cat"], "tags": pr["tags"],
               "description": pr["desc"], "ir": pr["ir"], "params": full, "schema": 1}
        with open(os.path.join(d, fname), "w") as fh:
            json.dump(doc, fh, indent=2)
        index.append({k: doc[k] for k in ("number", "name", "category", "tags", "ir", "description")} | {"file": fname})
    with open(os.path.join(d, "index.json"), "w") as fh:
        json.dump(index, fh, indent=2)
    print(f"{len(index)} presets written")


if __name__ == "__main__":
    main()
