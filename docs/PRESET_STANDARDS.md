# Preset naming, tagging and gain-staging standards

Owner: Dub Organiser.

## Naming
`NN CAT - Name`, where NN is a two-digit number and CAT is a category code:
- `REF`: reference and authentic tanks.
- `DUB`: dub sends and regeneration.
- `PERC`: drums and percussion.
- `TEX`: texture and experimental.

Names describe the musical use, not the settings. No two presets may share a name.

## Required fields (JSON schema 1)
`name`, `number`, `category`, `tags` (lower case, 2–5 tags drawn from: neutral, authentic, send, bright, dark, splash, drip, warm, long, wash, throw, metallic, resonant, drive, distortion, broken, unstable, short, tight, drone, mechanical, experimental, and an instrument name), `description` (what it's for, then any caveat), `ir` (a catalogue ID), and `params` (every parameter, clamped to range).

## Gain staging
With the reggae test pattern at −6 dBFS peak, the preset's output RMS must be **−6 to +6 dB** relative to the dry signal, and the output peak must stay below 0 dBFS. Current measured values are in the technical report under `preset_library`. Driven and long-tail presets set Output negative.

## Distinctness
The minimum pairwise long-term spectral distance must be greater than 0.05 (automated). The automated test is a floor only. The Dub Organiser and Dub Producer still have to agree that the presets *sound* different in use.

## Current library
| # | Name | Category | IR | Use |
|---|---|---|---|---|
| 01 | Fisher Reference | REF | TP K-10 | The K-10 as captured. Convolution only. |
| 02 | Vintage Splash | REF | TP Fender Deluxe | Amp-style drip with model splash. |
| 03 | Deep Dub Spring | DUB | TP K-10 | The default rimshot/snare send. |
| 04 | Metallic Resonance | TEX | SYN short | A singing mode, tuned with Tension. |
| 05 | Heavy Pressure | DUB | SYN dark | A driven, compressed dub wall. |
| 06 | Dark Chamber | REF | SYN dark | A smooth, dark small space. |
| 07 | Long Dub Tail | DUB | TP K-10 | An 8-second parallel wash for throws. |
| 08 | Broken Spring | TEX | SYN splash | Jolts, lurches and clatter. |
| 09 | Short Percussion Spring | PERC | TP Millertone '70s | Tight and bright, for hats and percussion. |
| 10 | Experimental Mechanical | TEX | SYN dark | Grinding textures from chords and pads. |

The library is **curated** (built and checked by script), not yet **approved**. Approval requires the listening sign-off in `reports/MUSICAL_VALIDATION.md`.
