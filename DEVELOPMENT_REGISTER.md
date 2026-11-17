# Central development register

**Statuses (four only):**
- **Implemented:** the code exists and runs.
- **Technically validated:** passes a reproducible automated check, with evidence.
- **Musically validated:** signed off by the Dub Producer and Dub Organiser.
- **Open:** unresolved, or not yet checked.

**Scope column:**
- **REF:** the Python reference engine. Its checks run here.
- **MAX:** the device code. Its "validation" here is limited to running the actual GenExpr and js outside Max and matching them against the reference.

Anything that needs Max or Live running is **Open** until `docs/QA_PROTOCOL.md` has been run.

Evidence: `reports/TECHNICAL_VALIDATION.md` (check names below), `reports/port_check_*.json`, `docs/FISHER_K10.md`.

| Feature | Owner | Scope | Status | Evidence | Known limitations / outstanding |
|---|---|---|---|---|---|
| Partitioned convolution | DSP | REF | Technically validated | `partitioned_convolution_exact` (error ~1e-16), `ir_reproduction_through_device` at 44.1–96 kHz | — |
| Convolution in gen~ (time-distributed) + js IR builder | DSP / M4L | MAX | Implemented. Port matched. | `port_check_conv`: the js IR matches the reference to 1e-14 at the same SR and 0.3% when resampling; the gen~ convolver matches direct convolution to 1e-15 | **Open:** compiling in Max, real CPU use, the FFT spike at each block boundary, js speed on a 4 s / 96 kHz IR in Max's engine |
| Mono/stereo IRs, user IRs, SR conversion, pre-delay, level, normalisation | DSP / M4L | REF + MAX | Technically validated (REF) | `ir_reproduction_through_device`, `sample_rate_consistency` | The IR is capped at 4 s. Latency of 21–23 ms is not reported to Live. |
| Physical spring model (dispersion, coupled loops, damping, modes, instability, splash/collision, nonlinearity, decay) | DSP | REF | Technically validated | `decay_accuracy_model`, `damping_frequency_dependent`, `sample_rate_consistency`, `denormal_protection`, `every_control_audible` | Decay accuracy is about ±17% at extreme Tension and Dispersion |
| K-10 geometry and voicing in the model | DSP | REF + MAX | Technically validated (timing, spectrum) | `k10_geometry_and_ir_evidence`: model 29.2 / 37.2 / 86.8 / 110.7 ms against the manual's 29 / 37 / 87 / 111 ms. `k10_spectrum_match`: 2.1 dB RMS against the K-10 IR (circuit from both schematics, tank part fitted). 17 Nov: corrected the recovery stage after finding its feedback loop in the Photofact. | **Open:** whether it sounds authentic; Drive calibrated in volts; +7 dB excess at 63 Hz |
| Spring model in gen~ | DSP / M4L | MAX | Implemented. Port matched. | `port_check_gen`: correlation 0.99999…, error ≤ 1e-6 against the reference, 3 cases; gen~ defaults are checked against params.py | **Open:** compiling in Max, CPU. The feedback path is not covered by the port check (loop latency differs by design). |
| Hybrid modes (Parallel, IR>Model, Model>IR), blend, levels | DSP | REF | Technically validated | `hybrid_phase_interaction` (power sum within 2 dB, distinct from either engine), `engine_mode_switching` | **Open:** whether hybrid is audibly better (Dub Producer) |
| Nonlinear stages (input drive, pre-emphasis, hard knee, output colour, loop/feedback saturation) | DSP | REF | Technically validated | `drive_nonlinearity` (THD rises with drive, H2 present, 3 kHz distorts more than 200 Hz), `dc_offset` | **Open:** whether it responds musically |
| Dub feedback, guard, limiter, Self-Osc gain control | DSP | REF | Technically validated | `feedback_stability_and_safeguards`, `self_oscillation_controlled` | **Open:** whether it plays well live. The Self-Osc gain-control constants haven't been tuned by ear. |
| Parameters: 23 dials + 2 menus, automation | M4L | REF | Technically validated (REF) | `parameter_automation_smooth`, `extreme_and_fuzzed_parameters` | **Open:** automation in Live (QA step 7) |
| Device UI and patch | M4L | MAX | Implemented | Patch lint: 0 broken connections, 25 unique parameters | **Open:** loading the `.amxd` (its binary header was written by hand), the UI, the `---` naming, pattrstorage recall of the User IR |
| Factory presets (10) | Producer / Sound Designer / Organiser | REF | Technically validated (gain, determinism, distinctness) | `preset_library` | **Open:** musical approval |
| IR library (13) and audit | Dub Organiser | — | Technically validated (audit) | `ir_library_audit`; `ir/CATALOGUE.md`; 1 duplicate and 6 non-spring/non-IR files rejected | **Open:** licenses for all 8 third-party IRs, a capture of our own (`docs/IR_CAPTURE.md`), the BF "Bird-Verb" naming |
| Fisher authenticity | DSP / Organiser | — | Open | `docs/FISHER_K10.md`: the third-party IR matches the manual (timing within 6%, spectrum within about 2 dB) | Not `HARDWARE-VERIFIED`: needs our own capture and an A/B |
| Sample rates 44.1 / 48 / 88.2 / 96 kHz | QA | REF | Technically validated | `sample_rate_consistency`, `ir_reproduction_through_device` | **Open:** SR switching in Live |
| Long-duration stability | QA | REF | Technically validated | `long_duration_stability` (10 min model + feedback, 2 min parallel) | **Open:** the 2-hour Live run |
| CPU / memory | QA | REF only | Open | `cpu_reference_engine` (Python numbers only, informational) | **Open:** Max CPU, multiple instances |
| Routing templates and dub workflows | Dub Organiser | — | Implemented (as docs) | `docs/DUB_WORKFLOW.md` | **Open:** `.als` templates, session testing |
| Musical validation | Dub Producer / Organiser | — | Open | `reports/MUSICAL_VALIDATION.md`, `renders/` | No listening has taken place yet |
| Production usability | Dub Organiser | — | Open | `reports/PRODUCTION_USABILITY.md` (desk review only) | Needs session testing |

## Stage gates
| Stage | State |
|---|---|
| A: research and architecture | Done (`docs/DSP_ARCHITECTURE.md`, `docs/FISHER_K10.md`) |
| B: independent engines | Technically validated (REF); the Max port is matched outside Max. **Gate open** until QA steps 1–3 pass in Live. |
| C: hybrid integration | Technically validated (REF). The audible advantage is **open**. |
| D: dub feedback | Technically validated (REF). **Open** for live playing. |
| E: musical refinement | **Open**: presets are curated but not approved by ear. |
| F: release validation | **Open**: depends on Live QA, the licenses and musical sign-off. |
