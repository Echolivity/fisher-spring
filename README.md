# ECHOLIVITY — Fisher Spring Hybrid

A hybrid spring reverb for Ableton Live 12 (Max for Live audio effect). It combines convolution with spring impulse responses, a physical spring model, analogue-style saturation and a dub feedback loop.

> **Status: not yet tested in Ableton Live.** The DSP is done and passes its automated tests. The device's own gen~ and JavaScript code produce the same output as the tested reference engine when run outside Max. Nobody has opened it in Max or Live yet, and nobody has listened to it.
>
> **Fisher authenticity:** the physical model's timing and circuit filtering come from the K-10 service manual and the Sams Photofact schematic; the tank's own response is fitted to a real K-10 IR (within 2.1 dB). The Fisher Reference IR is a third-party K-10 capture (Freesound #528139) whose timing and spectrum match that manual. This project has not captured hardware itself, and the third-party IR licenses are **unconfirmed**, so don't redistribute them. See `docs/FISHER_K10.md` and `DEVELOPMENT_REGISTER.md`.

## What's in the box

| Path | What it is |
|---|---|
| `device/Echolivity.amxd` | The Max for Live device. Keep the folder structure (it finds `ir/` relative to itself). |
| `device/Echolivity.maxpat` | The same patch, for opening in Max directly. |
| `device/gen/*.genexpr` | The DSP code inside the device's three gen~ objects (front, convolution, back). |
| `device/ech_ir_loader.js`, `device/ech_ui.js` | IR conditioning and partitioning, and the IR browser. |
| `reference/` | Reference DSP engine (Python + numba). The specification the device is ported from. |
| `ir/` | IR library: `originals/` (never modified), `processed/` (what the device loads), `CATALOGUE.md`. **This repository holds only the 5 synthetic IRs.** The third-party IRs (including the Fisher K-10) aren't published because their licenses are unconfirmed; their provenance records are here, and `ir/originals/third_party/README.md` says how to add the audio locally. |
| `presets/` | 10 factory presets as JSON plus `index.json`. They're also built into the device's preset menu. |
| `renders/` | Not in the repository. Generate with `python tools/render_demos.py` (needs the third-party IRs). |
| `tests/` | Automated validation suite and the Max port checks. |
| `tools/` | Builders (device, presets, IR catalogue, synthetic IRs), report generator and a Live-vs-reference comparison tool. |
| `docs/` | DSP architecture, IR capture procedure, Live QA protocol, dub workflow and routing, preset standards. |
| `reports/` | Technical validation report, musical validation protocol, production usability report. |
| `DEVELOPMENT_REGISTER.md` | Status, owner and evidence for every feature. |
| `KNOWN_LIMITATIONS.md` | What doesn't work or hasn't been proven yet. |

## Install

1. Copy the whole `echolivity` folder somewhere permanent, for example `~/Music/Ableton/User Library/Echolivity/`.
2. In Live 12, drag `device/Echolivity.amxd` onto an audio track or a return track.
3. If Live won't open the `.amxd`, the hand-built file header is the likely cause. Instead, drop an empty *Max Audio Effect* on a track, open it in Max, open `device/Echolivity.maxpat`, copy everything into the device, and save. See `docs/QA_PROTOCOL.md`, step 1.
4. Before moving the device to another machine, open it in Max and **Freeze** it. That embeds the js files. The IR library still has to sit at `../ir/processed/` relative to the device, or you can drop WAVs onto the IR zone instead.

## User guide

**Recommended use:** put Echolivity on a return track with Mix at 100%, and send rimshots, snares, skanks and chords to it. Turn Feedback up for regeneration. Ride Self-Osc during a performance.

### Core
- **Drive:** input saturation into the tank driver. Highs saturate first (pre-emphasis). Above about 60% it moves from soft to a harder clip. It also adds even-harmonic colour at the output.
- **Decay:** the spring model's RT60, from 0.3 to 8 s. On the IR engine it can only *shorten* the IR from its natural length.
- **Tone:** ±6 dB tilt EQ on the wet signal, pivoting at 900 Hz.
- **Damping:** how much faster the highs decay than the lows, on both engines. The default, 0.8, matches the K-10.
- **Mix:** equal-power dry/wet.
- **Output:** output level, −24 to +6 dB.

### Spring
- **Boing:** how hard the spring reacts to transients: pitch sway, splash noise and collision clatter on hard hits.
- **Tension:** short, tight springs (high) versus long, slack springs (low). **0.44 is the Fisher K-10** (29 and 37 ms springs). It also moves the resonant mode.
- **Dispersion:** strength of the chirp, the characteristic "pew" of each spring reflection.
- **Resonance:** makes the spring's main mode ring while everything else decays faster.
- **Movement:** random mechanical instability: slow drift, stiffness wobble and occasional jolts.

### Hybrid
- **Engine Mode:**
  - *IR*: convolution only.
  - *Model*: physical model only.
  - *Parallel*: both, blended.
  - *IR>Model*: the real tank feeds the model, which adds sway and movement.
  - *Model>IR*: the model excites the real tank.
- **IR Level / Model Level:** the level of each engine.
- **Hybrid Blend:**
  - In Parallel, an equal-power crossfade from IR to Model.
  - In the serial modes, a crossfade from the first engine alone to the signal through both engines.

### Dub
- **Feedback:** returns the wet signal into the tank. It's scaled to the active engine's loudest resonance, so 100% sits just below sustained howl.
- **FB Tone:** where the feedback band sits: dark and thin at −1, bright at +1.
- **FB Drive:** saturation inside the loop. Repeats get denser and grittier.
- **FB Damping:** treble lost on every pass.
- **Self-Osc:** turns the loop into a controlled howl. Low settings bloom slowly; high settings lock in within about 2 s and sit louder. It turns the runaway guard off proportionally. A limiter caps the loop at about −6 dBFS. Pull it back to 0 and the howl dies away.

### Advanced
- **IR menu:** the library IRs (Fisher K-10 first, then other third-party tanks, then synthetic), plus *User IR*. Drop any mono or stereo WAV onto the zone below the menu. The device resamples it and caps it at 4 s.
- **Pre-delay:** 0 to 250 ms before both engines, inside the feedback loop.
- **Width:** mid/side width of the wet signal, from 0 to 200%.
- **Modulation:** a slow periodic chorus on spring length. It's separate from Movement, which is random.

The **PRESET** menu loads the factory presets. The IR each preset expects is loaded with it. Live's own device presets (`.adv`) work as usual.

**Latency:** the convolution engine adds a fixed ~21–23 ms to the IR path. It acts as built-in pre-delay and is not reported to Live. The dry path has no added latency.

## Developer quick reference

```bash
pip install numpy scipy numba soundfile pytest
python tools/synth_ir.py          # regenerate synthetic IRs
python tools/ir_catalogue.py      # processed IRs + catalogue + audit
python tools/build_presets.py     # presets/*.json
python tools/build_device.py      # device/Echolivity.maxpat + .amxd
python tests/validate.py          # technical validation (~15 min)
python tests/port_check/check_conv_port.py && python tests/port_check/check_gen_port.py
python tools/make_report.py       # reports/TECHNICAL_VALIDATION.md
python tools/render_demos.py      # renders/
```

Design rule: change DSP in `reference/engine.py` first, port it to `device/gen/*.genexpr`, then run the port checks.

*ECHOLIVITY — Sound first. Engineering second. Hype last.*
