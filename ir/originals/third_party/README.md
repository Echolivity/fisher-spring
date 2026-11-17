# Third-party IRs (audio not in this repository)

The WAV files for these IRs are **not published**: their licenses are unconfirmed.
Their provenance records (`*.json` sidecars) are kept here so the catalogue stays complete.

To use them locally, put each file next to its sidecar under the sidecar's name, then run
`python tools/ir_catalogue.py` to rebuild `ir/processed/`.

| Sidecar | Original file | Where it came from |
|---|---|---|
| `fisher/TP_FISHER_K10_derickgtwk_STEREO_96k` | `fisher-k10-stereo.wav` | Freesound #528139 (derickgtwk) |
| `bf/TP_BF_*` | `Fender Deluxe Spring.wav`, `Supro Spring.wav`, `Bird-Verb *.wav` | "BF Spring Reverb Samples Only" pack |
| `millertone/TP_MT_*` | `70's Stereo Spring (01).wav`, `Spring + Webcor.wav`, `Silver Face + Spring Reverb (01).wav` | Millertone free IR collection |

Without them the library still has 5 synthetic IRs. Presets 01, 02, 03, 07 and 09 expect a
third-party IR: without it the device falls back to the physical model in hybrid modes, and is silent in IR mode.
The K-10 checks, the preset check and the renders need the K-10 IR in place; pytest skips them otherwise.
