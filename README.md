![Fisher Spring — Echolivity Tools](assets/fisher-spring-banner.svg)

<div align="center">

![Echolivity Tools](assets/echolivity-tools-mark.svg)

</div>

<div align="center">

# Fisher Spring

**A hybrid spring reverb for Ableton Live.**

Convolution with real spring tanks, a physical spring model voiced from the Fisher K-10 service manual, analogue-style saturation and a dub feedback loop that can be pushed into controlled self-oscillation.

[Features](#features) · [Install](#install) · [Controls](#controls) · [Presets](#presets) · [Validation](#validation-and-known-limitations) · [Developers](#developer-quick-reference)

![Ableton Live 12](https://img.shields.io/badge/Ableton-Live%2012-ff764d)
![Max for Live](https://img.shields.io/badge/Max%20for%20Live-required-cb8b4b)
![Status](https://img.shields.io/badge/status-untested%20in%20Live-d9774a)

</div>

> **Status: not yet tested in Ableton Live.** The DSP is complete and passes its automated tests. The device's own gen~ and JavaScript code produce the same output as the tested reference engine when run outside Max. Nobody has opened it in Max or Live yet, and nobody has listened to it.
>
> **Fisher authenticity:** the physical model's timing and circuit filtering come from the K-10 service manual and the Sams Photofact schematic, and the tank's own response is fitted to a real K-10 IR (within 2.1 dB). The Fisher Reference IR is a third-party K-10 capture (Freesound #528139) whose timing and spectrum match that manual. This project has not captured hardware itself, and the third-party IR licences are **unconfirmed**, so don't redistribute them. See [`docs/FISHER_K10.md`](docs/FISHER_K10.md) and [`DEVELOPMENT_REGISTER.md`](DEVELOPMENT_REGISTER.md).

**Requirements:** Ableton Live 12 Suite, or Live 12 Standard with the Max for Live add-on.

## Features

- **Two engines in one tank:** partitioned convolution with spring IRs, and a physical model with two dispersive springs, coupled loops, a resonant mode, splash, collision and mechanical drift.
- **Five hybrid modes:** IR, Model, Parallel, IR›Model (the real tank feeds the model's sway) and Model›IR (the model excites the real tank).
- **K-10 voicing:** at the default Tension of 0.44, the model's spring arrivals match the service manual's 29 / 37 / 87 / 111 ms within 2 ms.
- **Drive** with pre-emphasis, so highs saturate first, moving from soft to hard clip.
- **Dub feedback:** Feedback, FB Tone, FB Drive, FB Damping and **Self-Osc**, a controlled howl capped by a loop limiter.
- **Open IR library:** 5 synthetic IRs included. Drop any WAV onto the device to use your own.
- **10 factory presets** across reference, dub, texture and percussion.

## Inside the sound

![Signal flow](assets/fisher-spring-signal-flow.svg)

![Dispersion spectrogram](docs/img/dispersion_spectrogram.png)

<sub>The model's impulse response. Every reflection is a downward chirp, the "pew" that makes a spring sound like a spring.</sub>

![Dub feedback](docs/img/dub_feedback.png)

<sub>A single rimshot. Feedback stretches the tail; Self-Osc builds it into a sustained howl that the loop limiter holds near −6 dBFS. Pull Self-Osc back to 0 and it dies away.</sub>

<sub>Both plots are rendered from the Python reference engine by `tools/make_readme_plots.py`. They are simulations, not recordings of the device in Live.</sub>

This is a **character model voiced from published K-10 documentation, not a hardware clone**. It is not affiliated with or endorsed by Fisher or its successors; the name is used only to describe the historical reference.

## Install

1. Copy the whole repository folder somewhere permanent, for example `~/Music/Ableton/User Library/Echolivity/`. The device finds `ir/` relative to itself, so keep the folder structure.
2. In Live 12, drag [`device/Echolivity.amxd`](device/Echolivity.amxd) onto an audio track or a return track.
3. If Live won't open the `.amxd` or crashes, **save your work first** and run the diagnostic ladder (`python tools/make_bisect.py OUT`, then load the test devices from inside `device/`); the first one that crashes shows which part is responsible. The patch structure was aligned with what Max itself saves on 18 Nov 2026, after the same hand-built pattern crashed another Echolivity device. As a fallback, drop an empty *Max Audio Effect* on a track, open it in Max, open [`device/Echolivity.maxpat`](device/Echolivity.maxpat), copy everything into the device, and save. See [`docs/QA_PROTOCOL.md`](docs/QA_PROTOCOL.md), step 1.
4. Before moving the device to another machine, open it in Max and **Freeze** it. That embeds the js files. The IR library still has to sit at `../ir/processed/` relative to the device, or you can drop WAVs onto the IR zone instead.

**Recommended use:** put it on a return track with Mix at 100 %, and send rimshots, snares, skanks and chords to it. Turn Feedback up for regeneration and ride Self-Osc during a performance. More recipes are in [`docs/DUB_WORKFLOW.md`](docs/DUB_WORKFLOW.md).

## Controls

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

## Presets

| # | Preset | Category | IR | What it does |
|---|---|---|---|---|
| 1 | Fisher Reference | REF | Fisher K-10 † | The K-10 IR alone, natural decay |
| 2 | Vintage Splash | REF | Fender Deluxe † | Bright parallel hybrid: tank body with model boing and drip |
| 3 | Deep Dub Spring | DUB | Fisher K-10 † | Long, warm send spring with gentle regeneration |
| 4 | Metallic Resonance | TEX | Short Tank (synthetic) | Model-led singing metallic mode, tuned by Tension |
| 5 | Heavy Pressure | DUB | Dark Tank (synthetic) | Hard-driven tank with saturated feedback |
| 6 | Dark Chamber | REF | Dark Tank (synthetic) | Smooth, dark tank, like a small room |
| 7 | Infinite Dub | DUB | Fisher K-10 † | Feedback at max with some self-oscillation |
| 8 | Broken Spring | TEX | Splash Tank (synthetic) | Jolts, pitch lurches and clatter |
| 9 | Short Percussion Spring | PERC | 70s Stereo Spring † | Short, tight and bright, for hats and percussion |
| 10 | Experimental Mechanical | TEX | Dark Tank (synthetic) | Model›IR with saturated feedback: grinding drones |

<sub>† Third-party IR, not included in this repository because its licence is unconfirmed. These presets need the IR added locally; see [`ir/originals/third_party/README.md`](ir/originals/third_party/README.md).</sub>

## Validation and known limitations

| Area | State |
|---|---|
| Reference engine | Technically validated: convolution exactness, decay, damping, sample rates, denormals, feedback safety, long-duration stability, presets |
| Device code (gen~ and js) | Matches the reference outside Max (correlation 0.99999, convolution error ~1e-15) |
| Max / Live | **Not yet opened**: compiling, loading, UI, CPU and automation are all open |
| Fisher authenticity | Timing and spectrum match the manual and a third-party K-10 IR; no capture of our own yet |
| Musical validation | **Not done**: no listening tests yet |

Main limitations:
- The IR path adds 21–23 ms of latency, which isn't reported to Live; it acts as built-in pre-delay.
- IRs are capped at 4 s.
- Decay can only shorten an IR.
- The convolution FFTs may crackle at very small buffer sizes.
- The third-party IR licences are unconfirmed.

Full lists: [`KNOWN_LIMITATIONS.md`](KNOWN_LIMITATIONS.md) · [`DEVELOPMENT_REGISTER.md`](DEVELOPMENT_REGISTER.md) · [`reports/TECHNICAL_VALIDATION.md`](reports/TECHNICAL_VALIDATION.md) · [`docs/QA_PROTOCOL.md`](docs/QA_PROTOCOL.md).

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
python tools/make_readme_plots.py # the plots on this page (needs matplotlib)
```

Design rule: change DSP in `reference/engine.py` first, port it to `device/gen/*.genexpr`, then run the port checks.

## Project map

| Path | What it is |
|---|---|
| `device/Echolivity.amxd` | The Max for Live device. Keep the folder structure; it finds `ir/` relative to itself. |
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
| `assets/`, `docs/img/` | Images on this page. |
| `DEVELOPMENT_REGISTER.md` | Status, owner and evidence for every feature. |
| `KNOWN_LIMITATIONS.md` | What doesn't work or hasn't been proven yet. |

---

<div align="center">

**ECHOLIVITY TOOLS** · Sound first. Engineering second. Hype last.

</div>
