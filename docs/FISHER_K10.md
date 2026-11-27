# Fisher K-10 Dynamic Spacexpander: reference dossier

Owner: DSP Engineer, with the Dub Organiser for provenance. This file records what is known about the reference hardware and how each fact is used in Echolivity. Every claim names its source.

## Sources
1. **Fisher K-10 owner/service manual with schematic and parts list.** This is the PDF supplied by the project owner, kept in the project archive (`docs/sources/`; not redistributed). It includes "How the Spacexpander works", the technical specifications, schematic AW#1824B / P846 and the parts description list.
2. **radiomuseum.org, model 27137** (citing VDRG Handbuch 1967/68): years 1960–1971, 3 tubes, selenium rectifier, delay 33 ms, decay up to 2 s at 300 Hz, gain 0 dB.
3. **Sams Photofact Folder 12, Set 562** (© Howard W. Sams 1962, thetubestore.com; PDF supplied by the project owner). An independent schematic with DC voltages and resistance readings. **Its part numbers differ from the Fisher manual's**; this file gives both where it matters.
4. **dubcarrier.com (2019).** Says the unit was used in King Tubby's studios, among others. It gives no technical detail.
5. **Freesound #528139 "fisher-k10-stereo" by derickgtwk.** The only K-10 IR we have (license **unverified**).

## Facts from the manual, and how they are used

| Fact (source 1) | Used in Echolivity |
|---|---|
| Two springs that are deliberately not identical (different wire gauge and turns per inch). One-way travel **29 ms and 37 ms**. Echoes return to the input after 58 / 74 ms. Second arrivals at the output come **87 and 111 ms** after the dry signal. | Model geometry: round trips 58 / 74 ms at Tension 0.44 (the default), length ratio 37:29. The output pickup reads the one-way delay including half the dispersion. **Measured in the model: 29.2 / 37.2 / 86.8 / 110.7 ms.** |
| Specs: delay 33 ms (the average of the two springs), decay 2 s maximum at 300 Hz. | Default Decay is 2.0 s. The synthetic stand-in `SYN_K10Spec_2S` is matched to these figures. |
| One reverb path: inputs A and B are summed (R1, R2 470 kΩ) into V1. The tank is mono. The mono reverb is mixed into **both** channels (R26 / R25, 220 kΩ). | The model is mono-in like the hardware. The Width control can recreate the K-10's mono return (Width 0). Two springs to L/R remain as an option beyond the hardware. |
| Tank feed: C1 220 pF into R3 2.2 MΩ → **first-order high-pass at ~300 Hz**. C3 2.7 nF into R7 1 MΩ → 59 Hz. | Model tank-feed filters: 300 Hz and 59 Hz first-order high-passes. |
| Recovery: V2 (12AX7), two stages. Interstage: 470 pF into 2.2 MΩ (150 Hz high-pass), then a 100 kΩ / 270 pF ×2 ladder (2252 Hz and 15.4 kHz poles on paper). **Both schematics also show global negative feedback:** 680 kΩ ∥ 12 pF from V2b's output (after its coupling cap) back to V2a's unbypassed 2.7 kΩ cathode. Fisher numbering R17/C8 to R14; Photofact R15/C14 to R14. | Nodal analysis (`tests/k10_recovery_circuit.py`) gives about **15 dB of feedback**, which flattens those interstage filters: the whole recovery stage is within 0.5 dB from 63 Hz to 4 kHz and −2 dB at 8 kHz. The model uses that (a 13 kHz low-pass). **Correction (17 Nov):** the first version applied the open-loop 150 / 2252 Hz filters, having missed this loop. |
| Driver: V1 = 7247 (one 12AX7 section plus one 12AU7 section). The 12AX7 has a bypassed 3.3 kΩ cathode (plate 105 V, cathode 1.3 V per the Photofact), so it has high gain. Its 12AU7 cathode follower (cathode 8.5 V, 680 Ω bypassed by 25 µF) drives the tank's matching transformer T2 directly (300 Ω / 175 Ω windings). The Photofact also shows mild shunt feedback from the follower's output to V1a's grid (10 MΩ via 0.01 µF; roughly 5 dB). Maximum input 5 V. | This justifies a hot, saturating drive stage before the tank. A follower driving a low-impedance transformer clips asymmetrically when it runs out of current, which matches the biased (asymmetric) curve Drive uses. Calibrating Drive in volts is still open; the Photofact voltages are the starting point. |
| Output: each channel goes through a 12AX7 stage (V3a/V3b) carrying dry plus wet. Overall gain is unity. | Output colour stage (asymmetric, follows Drive). |
| Control unit: R24, a 250 kΩ wet-level pot with a push-pull on/off switch. Modes NORMAL (stereo dry + mono wet), REVERB ONLY (mono wet), CENTER (mono dry + wet). | Mix (NORMAL), Mix 100% (REVERB ONLY). There is no CENTER-mode preset yet. |
| The manual warns that the tank can howl from speaker feedback (acoustic feedback). | Not modelled. The device had a dub feedback loop for this until 27 Nov 2026; for regeneration now, loop it with a delay return (`docs/DUB_WORKFLOW.md`, R3). |

## Checking the third-party K-10 IR against the manual

The stereo IR (96 kHz, 5 s) contains a dry spike at t=0, because the unit's dry path is captured too. The processed variant removes the first 3 ms. Measured with envelope peaks in the 200 Hz–4 kHz band:

| | 1st spring | 2nd spring | 2nd arrival, spring 1 | 2nd arrival, spring 2 |
|---|---|---|---|---|
| Manual | 29 ms | 37 ms | 87 ms | 111 ms |
| IR, L | 30.0 | 39.1 | 89.2 | 116.3 |
| IR, R | 30.9 | 39.2 | 91.7 | 116.4 |

All four arrivals are 3–6% later than the manual (the largest gap is 39.1 against 37 ms). A slightly slower, aged or cooler tank, or production tolerance, would explain that.

Spectrum. Long-term energy of the IR, against the circuit alone (tank-feed high-passes plus the recovery stage with its feedback), in dB relative to 1 kHz:

| Hz | 63 | 125 | 250 | 500 | 1k | 2k | 3k | 4k | 6k | 8k |
|---|---|---|---|---|---|---|---|---|---|---|
| IR | −25.8 | −10.2 | −3.9 | −0.9 | 0 | −3.1 | −5.3 | −6.7 | −13.6 | −20.9 |
| Circuit (with feedback) | −15.7 | −8.1 | −3.5 | −0.9 | 0 | +0.2 | +0.1 | −0.1 | −0.7 | −1.6 |

The circuit is nearly flat, so the IR's treble loss (and its extra bass loss below ~100 Hz) comes from the tank itself: transducers, springs and their faster high-frequency decay. That tank part can't be read off a schematic, so it is **fitted** (`tools/fit_k10_tank.py`): rendering the model at K-10 settings and matching its long-term spectrum to the IR gives a transducer high-pass at 200 Hz, a second-order transducer low-pass at 8 kHz, and in-loop Damping 0.8 (now the default). Result: **2.1 dB RMS** across 1/3-octave bands from 63 Hz to 8 kHz. The largest residual is +6.9 dB at 63 Hz (the model keeps more sub-bass than the real tank) and about −3.5 dB at 4–5 kHz. Checked automatically by `k10_spectrum_match`.

RT60 at 300 Hz is 2.32 s, against the manual's "2 s maximum".

**Conclusion.** The IR is very likely a genuine K-10, and it's the best reference available. It is catalogued as `THIRD-PARTY` with this evidence, not `HARDWARE-VERIFIED`. That status needs a capture made by this project (`docs/IR_CAPTURE.md`).

## Still open
- Confirm the Freesound license before redistributing anything.
- The model keeps about 7 dB more energy at 63 Hz than the real K-10 IR; a steeper (2nd-order) transducer high-pass would close it.
- Calibrate Drive in volts against V1's real overdrive (needs hardware, or a SPICE run of V1 with the 7247 model).
- A blind A/B between the model at K-10 settings and the K-10 IR (Dub Producer).
