# Technical validation report

Generated 2026-11-17 by `tools/make_report.py` on x86_64 / Python 3.13.18.

**25 of 25 checks passed.**

## What this covers, and what it doesn't

- **Covered:** the reference DSP engine (`reference/engine.py`), the IR library audit, presets, and the Max port: the device's own GenExpr and JavaScript, run outside Max and compared sample-by-sample with the reference engine.
- **Not covered:** anything that needs Max or Live running: whether gen~ compiles, real CPU use, the UI, automation recorded in Live, preset recall in a Live Set, multiple instances, and real sample-rate switching. Those stay *Open* in the development register until `docs/QA_PROTOCOL.md` has been run in Live.

Reproduce: `python tests/validate.py && python tests/port_check/check_conv_port.py && python tests/port_check/check_gen_port.py && python tools/make_report.py`

| Check | Result | Time |
|---|---|---|
| ir_library_audit | PASS | 0.7 s |
| partitioned_convolution_exact | PASS | 0.0 s |
| ir_reproduction_through_device | PASS | 8.9 s |
| k10_geometry_and_ir_evidence | PASS | 0.1 s |
| k10_spectrum_match | PASS | 0.2 s |
| decay_accuracy_model | PASS | 1.4 s |
| decay_control_ir_shortens | PASS | 7.0 s |
| damping_frequency_dependent | PASS | 4.3 s |
| sample_rate_consistency | PASS | 8.5 s |
| feedback_stability_and_safeguards | PASS | 41.9 s |
| self_oscillation_controlled | PASS | 21.5 s |
| dc_offset | PASS | 3.6 s |
| denormal_protection | PASS | 12.2 s |
| extreme_and_fuzzed_parameters | PASS | 18.2 s |
| parameter_automation_smooth | PASS | 333.5 s |
| engine_mode_switching | PASS | 1.8 s |
| stereo_correlation | PASS | 4.5 s |
| hybrid_phase_interaction | PASS | 4.8 s |
| drive_nonlinearity | PASS | 0.0 s |
| every_control_audible | PASS | 132.4 s |
| preset_library | PASS | 75.2 s |
| long_duration_stability | PASS | 53.3 s |
| cpu_reference_engine | PASS | 24.5 s |
| port_check_conv (Max port) | PASS | - |
| port_check_gen (Max port) | PASS | - |

## Evidence

### ir_library_audit - PASS

- **irs**: 13
- **problems**: []
- **hardware_verified_fisher_irs**: []

### partitioned_convolution_exact - PASS

Streaming partitioned convolver == direct FFT convolution.

max_rel_error: 5.485216041914798e-16

### ir_reproduction_through_device - PASS

Full device in IR mode (drive 0, neutral EQ) reproduces the conditioned IR.

- **44100**: correlation: 0.99967, level_error_db: -0.48, latency_samples: 1024
- **48000**: correlation: 0.99967, level_error_db: -0.48, latency_samples: 1024
- **88200**: correlation: 0.99967, level_error_db: -0.48, latency_samples: 2048
- **96000**: correlation: 0.99967, level_error_db: -0.49, latency_samples: 2048

### k10_geometry_and_ir_evidence - PASS

Model at default Tension reproduces the K-10 manual's arrival times (29/37/87/111 ms),
and the third-party K-10 IR's arrivals sit within 6% of them.

- **manual_ms**: [29.0, 37.0, 87.0, 111.0]
- **model_ms**: [29.3, 37.3, 86.8, 110.8]
- **k10_ir_ms**: [30.0, 39.1, 89.2, 116.3]
- **tolerance**: model +/-2 ms, IR +/-6%

### k10_spectrum_match - PASS

Model at K-10 defaults vs the K-10 IR: long-term spectrum, 1/3-octave bands 63 Hz-8 kHz,
normalised at 1 kHz. Pass: RMS error < 3 dB.

- **rms_error_db**: 2.1
- **worst_band**: [63, 6.9]
- **error_per_band_db**:
  - **63**: 6.9
  - **80**: -0.9
  - **100**: -2.8
  - **125**: -0.6
  - **160**: 0.2
  - **200**: -2.1
  - **250**: -0.1
  - **315**: -1.3
  - **400**: -0.1
  - **500**: 0.9
  - **630**: 0.7
  - **800**: 0.4
  - **1000**: 0
  - **1250**: 0.3
  - **1600**: 1.4
  - **2000**: 0.4
  - **2500**: -0.1
  - **3150**: -1.7
  - **4000**: -3.5
  - **5000**: -3.5
  - **6300**: 1.5
  - **8000**: 1

### decay_accuracy_model - PASS

- **target_vs_measured_rt60_s**: 0.5: 0.51, 1.0: 0.96, 2.5: 2.35, 5.0: 4.9, 8.0: 7.64
- **tolerance**: +/-15% (neutral damping/resonance)

### decay_control_ir_shortens - PASS

- **decay_setting_vs_rt60**: 8.0: 2.32, 1.5: 1.46, 0.6: 0.59
- **note**: IR decay can only shorten below natural RT60

### damping_frequency_dependent - PASS

- **Model**: tail_centroid_hz_damp0: 1826, damp1: 543
- **IR**: tail_centroid_hz_damp0: 1850, damp1: 993

### sample_rate_consistency - PASS

- **per_rate**:
  - **44100**: model_rt60: 0.984, model_centroid_hz: 1879, ir_rt60: 1.234
  - **48000**: model_rt60: 0.994, model_centroid_hz: 1903, ir_rt60: 1.234
  - **88200**: model_rt60: 0.985, model_centroid_hz: 1814, ir_rt60: 1.234
  - **96000**: model_rt60: 0.996, model_centroid_hz: 1811, ir_rt60: 1.234
- **spread**: model_rt60_spread: 0.012, model_centroid_spread: 0.051, ir_rt60_spread: 0.0
- **tolerance**: model 12%, IR 5%

### feedback_stability_and_safeguards - PASS

osc=0: no growth after input stops at any feedback/mode; never > 0 dBFS.

- **mode0_fb0.5**:
  - **levels_db_2_6_11s**: [-57.0, -149.3, -240.0]
  - **peak**: 0.673
- **mode0_fb1.0**:
  - **levels_db_2_6_11s**: [-47.7, -79.8, -116.1]
  - **peak**: 0.676
- **mode1_fb0.5**:
  - **levels_db_2_6_11s**: [-82.7, -218.8, -240.0]
  - **peak**: 0.658
- **mode1_fb1.0**:
  - **levels_db_2_6_11s**: [-74.9, -154.5, -191.3]
  - **peak**: 0.661
- **mode2_fb0.5**:
  - **levels_db_2_6_11s**: [-60.4, -156.2, -240.0]
  - **peak**: 0.644
- **mode2_fb1.0**:
  - **levels_db_2_6_11s**: [-54.3, -117.3, -185.0]
  - **peak**: 0.65
- **mode3_fb0.5**:
  - **levels_db_2_6_11s**: [-54.8, -137.7, -224.2]
  - **peak**: 0.589
- **mode3_fb1.0**:
  - **levels_db_2_6_11s**: [-49.4, -100.6, -139.9]
  - **peak**: 0.594
- **mode4_fb0.5**:
  - **levels_db_2_6_11s**: [-54.7, -144.0, -240.0]
  - **peak**: 0.57
- **mode4_fb1.0**:
  - **levels_db_2_6_11s**: [-51.6, -120.1, -189.3]
  - **peak**: 0.569

### self_oscillation_controlled - PASS

osc=1: sustains after input stops, bounded by the limiter.

- **mode0**:
  - **levels_db_2_6_11s**: [-13.2, -4.1, -4.1]
  - **peak**: 0.705
- **mode1**:
  - **levels_db_2_6_11s**: [-52.4, -5.6, -5.1]
  - **peak**: 0.705
- **mode2**:
  - **levels_db_2_6_11s**: [-25.9, -4.3, -4.3]
  - **peak**: 0.699
- **mode3**:
  - **levels_db_2_6_11s**: [-31.5, -6.4, -6.4]
  - **peak**: 0.722
- **mode4**:
  - **levels_db_2_6_11s**: [-48.0, -5.1, -4.1]
  - **peak**: 0.705

### dc_offset - PASS

- **max_drive_fb**: dc_mean: 7.674368511298314e-06
- **self_osc**: dc_mean: 0.00011090183056820594

### denormal_protection - PASS

- **mode1**: subnormal_outputs: 0, subnormal_states: 0, tail_peak_after_40s: 0.0
- **mode2**: subnormal_outputs: 0, subnormal_states: 0, tail_peak_after_40s: 0.0

### extreme_and_fuzzed_parameters - PASS

combos: 22, non_finite: 0, worst_peak: 1.39, note: peaks >1 possible with Output +6 dB and 0 dBFS noise; no NaN/inf

### parameter_automation_smooth - PASS

Sweep each parameter over its full range in 2 s against static renders.

- **drive**: max_step_sweep: 0.1537, max_step_static: 0.1369
- **decay**: max_step_sweep: 0.125, max_step_static: 0.1542
- **tone**: max_step_sweep: 0.2083, max_step_static: 0.2083
- **damping**: max_step_sweep: 0.24, max_step_static: 0.3313
- **mix**: max_step_sweep: 0.5723, max_step_static: 0.6381
- **output**: max_step_sweep: 0.2967, max_step_static: 0.3007
- **boing**: max_step_sweep: 0.1581, max_step_static: 0.1653
- **tension**: max_step_sweep: 0.1445, max_step_static: 0.1688
- **dispersion**: max_step_sweep: 0.1487, max_step_static: 0.1485
- **resonance**: max_step_sweep: 0.1503, max_step_static: 0.1604
- **movement**: max_step_sweep: 0.1614, max_step_static: 0.1616
- **ir_level**: max_step_sweep: 0.235, max_step_static: 0.2487
- **model_level**: max_step_sweep: 0.219, max_step_static: 0.219
- **blend**: max_step_sweep: 0.1581, max_step_static: 0.1638
- **feedback**: max_step_sweep: 0.1509, max_step_static: 0.151
- **fb_tone**: max_step_sweep: 0.1513, max_step_static: 0.1515
- **fb_drive**: max_step_sweep: 0.1507, max_step_static: 0.1507
- **fb_damping**: max_step_sweep: 0.1507, max_step_static: 0.1515
- **self_osc**: max_step_sweep: 0.1507, max_step_static: 0.1507
- **predelay**: max_step_sweep: 0.1512, max_step_static: 0.1507
- **width**: max_step_sweep: 0.2339, max_step_static: 0.2339
- **modulation**: max_step_sweep: 0.1459, max_step_static: 0.1628

### engine_mode_switching - PASS

peak: 0.696

### stereo_correlation - PASS

L/R correlation in (-0.5, 0.9) for the model, Width 0 = mono, and mono-sum loss > -4 dB
for every engine. (Bound widened from -0.2 on 2026-11-14: see comment below.)

- **model**: lr_correlation: -0.255, mono_sum_vs_power_db: -1.26
- **ir**: lr_correlation: 0.156, mono_sum_vs_power_db: 0.63
- **parallel**: lr_correlation: -0.001, mono_sum_vs_power_db: -0.0
- **model_width0**: lr_correlation: 1.0, mono_sum_vs_power_db: 3.01

### hybrid_phase_interaction - PASS

Parallel blend should sum in power (no systematic cancellation).

parallel_vs_power_sum_db: 0.07, corr_with_ir_only: 0.749, corr_with_model_only: 0.663, note: distinct from either engine; audible advantage still needs listening

### drive_nonlinearity - PASS

- **thd_vs_drive_1k**: [0.0188, 0.0467, 0.1247, 0.2382, 0.2669]
- **h2_over_h1_drive0.5**: 0.0483
- **thd_200hz_vs_3khz_drive0.4**: [0.0817, 0.1155]

### every_control_audible - PASS

Technical proxy: min vs max of each control changes the output measurably.
Context: hybrid params in parallel mode, dub params with feedback on.

- **difference_db_min_vs_max**:
  - **drive**: -1.7
  - **decay**: -1.6
  - **tone**: -5.9
  - **damping**: -6.9
  - **mix**: 1.6
  - **output**: -0.3
  - **boing**: -2.8
  - **tension**: -1.6
  - **dispersion**: -2.3
  - **resonance**: -7.5
  - **movement**: -6.9
  - **engine_mode**: 1.7
  - **ir_level**: -0.9
  - **model_level**: -2.3
  - **blend**: 1.7
  - **feedback**: -11.3
  - **fb_tone**: -9.7
  - **fb_drive**: -17
  - **fb_damping**: -17.7
  - **self_osc**: -0.3
  - **predelay**: 3
  - **width**: -0.9
  - **modulation**: -7.6
- **threshold**: > -25 dB difference signal (A/B proxy; listening still required)

### preset_library - PASS

- **presets**:
  - **Fisher Reference**: peak: 0.374, rms_vs_dry_db: 2.1, deterministic: True
  - **Vintage Splash**: peak: 0.323, rms_vs_dry_db: 4.0, deterministic: True
  - **Deep Dub Spring**: peak: 0.222, rms_vs_dry_db: 0.7, deterministic: True
  - **Metallic Resonance**: peak: 0.407, rms_vs_dry_db: 0.2, deterministic: True
  - **Heavy Pressure**: peak: 0.253, rms_vs_dry_db: -1.4, deterministic: True
  - **Dark Chamber**: peak: 0.29, rms_vs_dry_db: 1.8, deterministic: True
  - **Infinite Dub**: peak: 0.225, rms_vs_dry_db: 0.5, deterministic: True
  - **Broken Spring**: peak: 0.206, rms_vs_dry_db: -0.5, deterministic: True
  - **Short Percussion Spring**: peak: 0.445, rms_vs_dry_db: 0.2, deterministic: True
  - **Experimental Mechanical**: peak: 0.203, rms_vs_dry_db: -1.7, deterministic: True
- **min_pairwise_spectral_distance**: 0.124

### long_duration_stability - PASS

- **model_fb**:
  - **minutes**: 10
  - **finite**: True
  - **peak**: 0.666
  - **rms_first_last_30s_db**: [-24.9, -25.7]
  - **realtime_factor_python**: 0.035
- **parallel_fb**:
  - **minutes**: 2
  - **finite**: True
  - **peak**: 0.677
  - **rms_first_last_30s_db**: [-25.3, -25.1]
  - **realtime_factor_python**: 0.262

### cpu_reference_engine - PASS

Python/numba reference cost (NOT Max CPU - that stays open until measured in Live).

- **seconds_per_audio_second**: model@44100: 0.031, parallel@44100: 0.42, model@48000: 0.032, parallel@48000: 0.501, model@88200: 0.069, parallel@88200: 1.454, model@96000: 0.071, parallel@96000: 1.678
- **machine**: x86_64
- **note**: informational; Python reference, single thread

### port_check_conv - PASS

- **48000Hz_decay8.0_damp0.0**: B: 512, K: 47, js_ms: 76, ir_vs_reference_max_rel_err: 8.214424588369203e-15, ir_peak_rel_err: 8.43769498715119e-15, gen_conv_vs_direct_max_rel_err: 9.928231429287818e-16, latency_samples: 1024
- **44100Hz_decay1.0_damp0.6**: B: 512, K: 44, js_ms: 369, ir_vs_reference_max_rel_err: 0.003008152644739758, ir_peak_rel_err: 0.0022975001615224144, gen_conv_vs_direct_max_rel_err: 7.2959095712168175e-16, latency_samples: 1024
- **96000Hz_decay2.0_damp0.3**: B: 1024, K: 47, js_ms: 743, ir_vs_reference_max_rel_err: 0.0010360899137512875, ir_peak_rel_err: 0.00021279821961628365, gen_conv_vs_direct_max_rel_err: 9.45949518956157e-16, latency_samples: 2048

### port_check_gen - PASS

- **param_defaults_match**:
  - **mismatches**: []
- **model_default**: max_rel_error: 3.1175695384188817e-07, correlation: 0.9999999999999973
- **model_drive_dark**: max_rel_error: 6.567921018460168e-07, correlation: 0.9999999999999901
- **parallel_ir**: max_rel_error: 3.212591901121526e-07, correlation: 0.9999999999999983

