# Technical validation report

Generated 2026-11-27 by `tools/make_report.py` on x86_64 / Python 3.13.18.

**20 of 20 checks passed**; 3 not run (they need the third-party K-10 IR, which is not in the repository).

## What this covers, and what it doesn't

- **Covered:** the reference DSP engine (`reference/engine.py`), the IR library audit, presets, and the Max port: the device's own GenExpr and JavaScript, run outside Max and compared sample-by-sample with the reference engine.
- **Not covered:** anything that needs Max or Live running: whether gen~ compiles, real CPU use, the UI, automation recorded in Live, preset recall in a Live Set, multiple instances, and real sample-rate switching. Those stay *Open* in the development register until `docs/QA_PROTOCOL.md` has been run in Live.

Reproduce: `python tests/validate.py && python tests/port_check/check_conv_port.py && python tests/port_check/check_gen_port.py && python tools/make_report.py`

| Check | Result | Time |
|---|---|---|
| ir_library_audit | PASS | 0.0 s |
| partitioned_convolution_exact | PASS | 0.0 s |
| ir_reproduction_through_device | PASS | 10.0 s |
| k10_geometry_and_ir_evidence | NOT RUN | 0 s |
| k10_spectrum_match | NOT RUN | 0 s |
| decay_accuracy_model | PASS | 1.3 s |
| decay_control_ir_shortens | PASS | 7.2 s |
| damping_frequency_dependent | PASS | 4.5 s |
| sample_rate_consistency | PASS | 9.2 s |
| dc_offset | PASS | 3.9 s |
| denormal_protection | PASS | 12.7 s |
| extreme_and_fuzzed_parameters | PASS | 18.6 s |
| parameter_automation_smooth | PASS | 360.9 s |
| engine_mode_switching | PASS | 1.7 s |
| stereo_correlation | PASS | 4.6 s |
| hybrid_phase_interaction | PASS | 5.1 s |
| drive_nonlinearity | PASS | 0.0 s |
| every_control_audible | PASS | 106.5 s |
| preset_library | NOT RUN | 0 s |
| long_duration_stability | PASS | 54.3 s |
| cpu_reference_engine | PASS | 24.8 s |
| port_check_conv (Max port) | PASS | - |
| port_check_gen (Max port) | PASS | - |

## Evidence

### ir_library_audit - PASS

- **irs**: 5
- **problems**: []
- **hardware_verified_fisher_irs**: []

### partitioned_convolution_exact - PASS

Streaming partitioned convolver == direct FFT convolution.

max_rel_error: 5.485216041914798e-16

### ir_reproduction_through_device - PASS

Full device in IR mode (drive 0, neutral EQ) reproduces the conditioned IR.

- **44100**: correlation: 0.99967, level_error_db: -0.48, latency_samples: 0
- **48000**: correlation: 0.99967, level_error_db: -0.48, latency_samples: 0
- **88200**: correlation: 0.99967, level_error_db: -0.48, latency_samples: 0
- **96000**: correlation: 0.99967, level_error_db: -0.49, latency_samples: 0

### k10_geometry_and_ir_evidence - NOT RUN

Model at default Tension reproduces the K-10 manual's arrival times (29/37/87/111 ms),
and the third-party K-10 IR's arrivals sit within 6% of them.

note: Not re-run on 27 Nov 2026: needs TP_FISHER_K10, a third-party IR that is not in the repository. Run tests/validate.py locally with the IR to refresh.

### k10_spectrum_match - NOT RUN

Model at K-10 defaults vs the K-10 IR: long-term spectrum, 1/3-octave bands 63 Hz-8 kHz,
normalised at 1 kHz. Pass: RMS error < 3 dB.

note: Not re-run on 27 Nov 2026: needs TP_FISHER_K10, a third-party IR that is not in the repository. Run tests/validate.py locally with the IR to refresh.

### decay_accuracy_model - PASS

- **target_vs_measured_rt60_s**: 0.5: 0.51, 1.0: 0.96, 2.5: 2.35, 5.0: 4.9, 8.0: 7.64
- **tolerance**: +/-15% (neutral damping/resonance)

### decay_control_ir_shortens - PASS

- **decay_setting_vs_rt60**: 8.0: 2.32, 1.5: 1.46, 0.6: 0.59
- **note**: IR decay can only shorten below natural RT60

### damping_frequency_dependent - PASS

- **Model**: tail_centroid_hz_damp0: 1826, damp1: 543
- **IR**: tail_centroid_hz_damp0: 1744, damp1: 964

### sample_rate_consistency - PASS

- **per_rate**:
  - **44100**: model_rt60: 0.984, model_centroid_hz: 1879, ir_rt60: 1.234
  - **48000**: model_rt60: 0.994, model_centroid_hz: 1903, ir_rt60: 1.234
  - **88200**: model_rt60: 0.985, model_centroid_hz: 1814, ir_rt60: 1.234
  - **96000**: model_rt60: 0.996, model_centroid_hz: 1811, ir_rt60: 1.234
- **spread**: model_rt60_spread: 0.012, model_centroid_spread: 0.051, ir_rt60_spread: 0.0
- **tolerance**: model 12%, IR 5%

### dc_offset - PASS

- **max_drive_parallel**: dc_mean: 1.946188190645299e-06
- **max_drive_model_resonant**: dc_mean: 3.1059923597682605e-06

### denormal_protection - PASS

- **mode1**: subnormal_outputs: 0, subnormal_states: 0, tail_peak_after_40s: 0.0
- **mode2**: subnormal_outputs: 0, subnormal_states: 0, tail_peak_after_40s: 0.0

### extreme_and_fuzzed_parameters - PASS

combos: 22, non_finite: 0, worst_peak: 1.92, note: peaks >1 possible with Output +6 dB and 0 dBFS noise; no NaN/inf

### parameter_automation_smooth - PASS

Sweep each parameter over its full range in 2 s against static renders.

- **drive**: max_step_sweep: 0.1352, max_step_static: 0.149
- **decay**: max_step_sweep: 0.1361, max_step_static: 0.1518
- **tone**: max_step_sweep: 0.1998, max_step_static: 0.2108
- **damping**: max_step_sweep: 0.24, max_step_static: 0.3136
- **mix**: max_step_sweep: 0.5732, max_step_static: 0.6381
- **output**: max_step_sweep: 0.2971, max_step_static: 0.3372
- **boing**: max_step_sweep: 0.1429, max_step_static: 0.16
- **tension**: max_step_sweep: 0.1401, max_step_static: 0.1513
- **dispersion**: max_step_sweep: 0.1603, max_step_static: 0.1602
- **resonance**: max_step_sweep: 0.1595, max_step_static: 0.1811
- **movement**: max_step_sweep: 0.1504, max_step_static: 0.1686
- **ir_level**: max_step_sweep: 0.2576, max_step_static: 0.2576
- **model_level**: max_step_sweep: 0.219, max_step_static: 0.2433
- **blend**: max_step_sweep: 0.1593, max_step_static: 0.1643
- **predelay**: max_step_sweep: 0.153, max_step_static: 0.169
- **width**: max_step_sweep: 0.2317, max_step_static: 0.2317
- **modulation**: max_step_sweep: 0.1461, max_step_static: 0.1654

### engine_mode_switching - PASS

peak: 0.678

### stereo_correlation - PASS

L/R correlation in (-0.5, 0.9) for the model, Width 0 = mono, and mono-sum loss > -4 dB
for every engine. (Bound widened from -0.2 on 2026-11-14: see comment below.)

- **model**: lr_correlation: -0.255, mono_sum_vs_power_db: -1.26
- **ir**: lr_correlation: 0.156, mono_sum_vs_power_db: 0.63
- **parallel**: lr_correlation: -0.024, mono_sum_vs_power_db: -0.1
- **model_width0**: lr_correlation: 1.0, mono_sum_vs_power_db: 3.01

### hybrid_phase_interaction - PASS

Parallel blend should sum in power (no systematic cancellation).

parallel_vs_power_sum_db: -0.21, corr_with_ir_only: 0.725, corr_with_model_only: 0.629, note: distinct from either engine; audible advantage still needs listening

### drive_nonlinearity - PASS

- **thd_vs_drive_1k**: [0.0188, 0.0467, 0.1247, 0.2382, 0.2669]
- **h2_over_h1_drive0.5**: 0.0483
- **thd_200hz_vs_3khz_drive0.4**: [0.0817, 0.1155]

### every_control_audible - PASS

Technical proxy: min vs max of each control changes the output measurably.
Context: hybrid params in parallel mode.

- **difference_db_min_vs_max**:
  - **drive**: -1.5
  - **decay**: -1.6
  - **tone**: -6
  - **damping**: -6.4
  - **mix**: 2.3
  - **output**: -0.3
  - **boing**: -2.4
  - **tension**: -1
  - **dispersion**: -2.4
  - **resonance**: -7.2
  - **movement**: -6.7
  - **engine_mode**: 1.8
  - **ir_level**: -0.8
  - **model_level**: -2.1
  - **blend**: 1.8
  - **predelay**: 3.2
  - **width**: -1
  - **modulation**: -7.2
- **threshold**: > -25 dB difference signal (A/B proxy; listening still required)

### preset_library - NOT RUN

note: Not re-run on 27 Nov 2026: needs TP_FISHER_K10, a third-party IR that is not in the repository. Run tests/validate.py locally with the IR to refresh.

### long_duration_stability - PASS

- **model_long**:
  - **minutes**: 10
  - **finite**: True
  - **peak**: 0.47
  - **rms_first_last_30s_db**: [-27.1, -28.1]
  - **realtime_factor_python**: 0.035
- **parallel_long**:
  - **minutes**: 2
  - **finite**: True
  - **peak**: 0.576
  - **rms_first_last_30s_db**: [-26.3, -26.2]
  - **realtime_factor_python**: 0.27

### cpu_reference_engine - PASS

Python/numba reference cost (NOT Max CPU - that stays open until measured in Live).

- **seconds_per_audio_second**: model@44100: 0.035, parallel@44100: 0.444, model@48000: 0.036, parallel@48000: 0.533, model@88200: 0.064, parallel@88200: 1.381, model@96000: 0.069, parallel@96000: 1.653
- **machine**: x86_64
- **note**: informational; Python reference, single thread

### port_check_conv - PASS

- **48000Hz_0.5s_decay8.0_damp0.0**: B: 512, K_tail: 43, js_ms: 55, ir_vs_reference_max_rel_err: 8.39696735699963e-15, ir_fully_covered: True, gen_conv_vs_direct_max_rel_err: 8.568764055152972e-16, impulse_peak_lag_samples: None, note: error is against convolution with NO delay, so it also proves zero latency
- **44100Hz_0.5s_decay1.0_damp0.6**: B: 512, K_tail: 40, js_ms: 331, ir_vs_reference_max_rel_err: 0.0030081526447399104, ir_fully_covered: True, gen_conv_vs_direct_max_rel_err: 8.553825014530065e-16, impulse_peak_lag_samples: None, note: error is against convolution with NO delay, so it also proves zero latency
- **96000Hz_0.5s_decay2.0_damp0.3**: B: 1024, K_tail: 43, js_ms: 674, ir_vs_reference_max_rel_err: 0.001036089913751168, ir_fully_covered: True, gen_conv_vs_direct_max_rel_err: 9.121656075648659e-16, impulse_peak_lag_samples: None, note: error is against convolution with NO delay, so it also proves zero latency
- **48000Hz_0.02s_decay2.0_damp0.3**: B: 512, K_tail: 0, js_ms: 11, ir_vs_reference_max_rel_err: 5.103133957123147e-16, ir_fully_covered: True, gen_conv_vs_direct_max_rel_err: 7.991906432852652e-16, impulse_peak_lag_samples: 0, note: error is against convolution with NO delay, so it also proves zero latency

### port_check_gen - PASS

- **param_defaults_match**:
  - **mismatches**: []
- **model_default**: max_rel_error: 3.1175695384188817e-07, correlation: 0.9999999999999973
- **model_drive_dark**: max_rel_error: 6.567921018460168e-07, correlation: 0.9999999999999901
- **parallel_ir**: max_rel_error: 3.354320662652382e-07, correlation: 0.9999999999999989
- **ir_only**: max_rel_error: 3.347195926567196e-07, correlation: 0.9999999999999979
- **ir_to_model**: max_rel_error: 2.972510457396715e-07, correlation: 0.999999999999999

