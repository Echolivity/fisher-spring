# QA protocol: validating the device in Max and Live

Owner: QA / Validation Engineer. Nothing in the Max device counts as *Technically validated* until the step below for it passes and the evidence is saved under `qa/results/`. Record each result in `DEVELOPMENT_REGISTER.md`.

| # | Step | Pass criterion | Evidence to save |
|---|---|---|---|
| 1 | Open `device/Echolivity.amxd` in Live 12. If that fails, rebuild it from `Echolivity.maxpat` in a new Max Audio Effect. Open the Max editor and check the Max console. | No red errors. All three gen~ compile (double-click each one; no codebox errors). | Screenshot of the console |
| 2 | IR menu: pick each library IR. | The status line shows channels, RT60 and length. Audio passes in IR mode with no audible delay against the dry signal. | Status text |
| 3 | `python tools/compare_render.py --make-inputs`, then bounce `impulse.wav` through each factory preset at 48 kHz with Movement = Boing = 0, and compare. | Correlation ≥ 0.99 and level within ±0.5 dB, for every preset except Model>IR ones (the spring→IR send is one buffer late in Live) | JSON output |
| 4 | Repeat step 3 at 44.1, 88.2 and 96 kHz (Live: Preferences > Audio). Change the rate while the device is running. | Same criteria. The IR is rebuilt automatically after the rate change. | JSON output |
| 5 | CPU: one instance on a 48 kHz project at 128-sample buffer, each engine mode, with a 4 s IR. Read Live's CPU meter and Max's CPU (Options > Audio Status). | Note the numbers. Target is under 5% of one core per instance on a 2020-era laptop. No dropouts at a 128 buffer. | Table |
| 6 | Multiple instances: 8 instances on returns and tracks in a realistic set (drums, bass, keys, 2 delays). | No dropouts at a 256 buffer. Each instance keeps its own IR, which proves `---` buffer names are unique per device. | Set + notes |
| 7 | Automation: record sweeps of every dial, the Engine Mode and the IR menu, then play them back. | No clicks beyond the reference behaviour, and no stuck states. | Bounce |
| 8 | Preset recall: save a Live Set with 3 instances on different presets plus one User IR, then reopen it. Save and reload Live `.adv` presets. | Every parameter recalls. The User IR path is restored (pattrstorage). | Notes |
| 9 | Zero latency: on a track, Mix 100%, IR mode, Fisher K-10 IR. Record an impulse through it next to the dry impulse. | The first spring arrival lands where the IR has it (about 29 ms for the K-10), not 21 ms later. | Bounce |
| 10 | Long run: the reggae loop through *Long Dub Tail* for 2 hours. | No CPU creep, no denormal spikes, no level drift. | CPU log |
| 11 | Portability: freeze, copy to a second machine and a second user account. | Loads, finds `ir/processed`, the presets work. | Notes |
| 12 | Port drift: after any DSP change, `python tests/port_check/check_gen_port.py` | PASS | Log |

Known risks to watch in steps 1, 5 and 6:

- **GenExpr compile errors.** The code was only run through a Python translator here.
- **CPU spike at each convolution block boundary.** Three FFTs happen within one sample.
- **Unique buffer names.** Whether `---` names resolve inside `js` arguments and the gen~ `H` rebinding message.
- **User IR recall.** The `pattrstorage` parameter-blob storage of the User IR path.
