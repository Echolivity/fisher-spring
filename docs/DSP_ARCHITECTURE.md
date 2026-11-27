# DSP architecture

Owner: DSP Engineer. The specification is `reference/engine.py`, and the device code is a port of it (`device/gen/`). Parameter names and ranges come from `reference/params.py`.

## Signal flow

```
 dry L/R ─────────────────────────────────────────────────────────────┐
    │                                                                  │
    └─► mono ─► INPUT DRIVE ─► PREDELAY ─┬─► CONVOLUTION ─┐            │
                                         └─► SPRING MODEL ─┤           │
                                                           ▼           │
                                                    ENGINE ROUTER      │
                                                   (5 modes, blend)    │
                                                           │ wet       │
                                                           ▼           ▼
                            TONE ─► WIDTH ─► OUTPUT COLOUR ─► MIX ─► OUTPUT
```

In the device this is split into three gen~ objects:

- **front:** drive, predelay and the convolution send.
- **conv:** the zero-latency convolver.
- **back:** springs, router and output.

One `tapin~`/`tapout~` pair carries the Model>IR send back from the springs (in back) to the convolver input (in front), because IR>Model needs the opposite order. It adds one signal vector of delay in Model>IR only; the reference engine has none, so Model>IR differs slightly between the two. The dub feedback loop was removed on 27 Nov 2026.

The tanks are mono-in like real hardware: the stereo input is summed before the drive stage. Stereo comes from the two different springs, or from the two IR channels.

## A. Convolution engine

- **Algorithm (since 27 Nov 2026): zero-latency, three stages.** Each stage's latency equals its offset in the IR, so the sum is exact convolution with no delay:

  | Stage | IR segment | Method | Latency |
  |---|---|---|---|
  | Head | 0–127 samples | direct-form FIR | 0 |
  | Mid | 128 to 4B | overlap-save, 64-sample partitions, FFT 128 | 128 |
  | Tail | 4B to end | overlap-save, B-sample partitions, FFT 2B | 4B |

  B is 512 at 48 kHz and below, 1024 at 88.2/96 kHz.
- **Real-time scheduling:** the tail is pipelined one stage per block (forward FFT → multiply-accumulate → inverse FFT → play), and each stage's work is spread evenly over the block's samples, so no sample carries a whole FFT. Both output channels share one inverse FFT (L + iR). The mid stage runs its two 128-point FFTs at its own 64-sample boundary. Counted work for a 4 s IR: the heaviest sample does about 1,900 operations against 16,000 (48 kHz) / 34,500 (96 kHz) before, for about 25–33% more average work.
- **Verified outside Max:** `tests/port_check/check_conv_port.py` runs the actual `ech_conv.genexpr` (translated line by line) against direct convolution with no delay: error ~1e-15 at 44.1, 48 and 96 kHz, and with an IR shorter than the tail offset. **Max CPU has not been measured.**
- **Before 27 Nov 2026:** uniform partitions from sample 0, three FFTs in one sample at every block boundary, and 2B samples (21.3–23.2 ms) of latency on the IR path.
- **IR conditioning** (`prepare_ir`, `ech_ir_loader.js`):
  1. Resample. The reference uses polyphase; the js uses Lanczos-8, and the two differ by ≤0.3% in the port check.
  2. Cap at 4 s with a 50 ms fade.
  3. Apply the Decay envelope. It can only shorten the IR: it adds exponential decay toward the target RT60.
  4. Apply Damping: extra decay on the band above 2 kHz, using a zero-phase one-pole split.
  5. Energy-normalise, so white noise in gives the same RMS out.
- **Mono/stereo IRs:** a mono IR is copied to both channels. A stereo IR convolves the mono tank input separately with each channel.
- **Recompute:** Decay and Damping changes are debounced by 250 ms, and the resampled IR is cached. While H is rewritten, the convolver is muted (`nparts -1`).
- **CPU (the analysis):** the multiply-accumulate rate is SR × K × 2 channels complex MACs per second. For a 4 s IR at 48 kHz (K = 375) that's about 36 M complex MACs per second (~144 MFLOP/s). **Real cost in Max has not been measured yet** (it's in the register).

## B. Physical spring model

The two springs follow the **Fisher K-10** (`docs/FISHER_K10.md`): one-way travel of 29 ms and 37 ms at the default Tension of 0.44, with the K-10's tank-feed filters and recovery stage taken from its component values, and the tank's own transducer response fitted to the real K-10 IR. Each spring runs this loop:

```
x ─► K-10 feed HP 300 Hz + 59 Hz ─► (+) ─► 64 × stretched allpass (a + z^-K)/(1 + a z^-K) ─► damping LP
                                 ▲          (dispersion: lows delayed more → chirps)            │
                                 │                                                              ▼
              coupling rotation ◄┴── g · delay(T ± movement ± sway ± LFO) ◄── sat (collision) ◄─ mode peak
                                 │
                                 └─► output transducer (one-way tap) ─► tank transducer HP 200 Hz + LP 8 kHz (fitted) ─► K-10 recovery amp, closed loop (LP 13 kHz)
```

| Spec item | How it's implemented |
|---|---|
| Dispersive propagation | 64 first-order allpasses with stretch K = round(SR/22050), so the chirp shape is the same at every sample rate. The coefficient runs from −0.45 to −0.80 (Dispersion). Each round trip adds more chirp, as on a real spring. |
| Coupled delay structures | Two loops with the K-10's length ratio (37 : 29), coupled by a 0.12 rad orthogonal rotation. The rotation loses no energy, so the coupling never adds gain. Round trip is 80 ms (slack) to 30 ms (tight); Tension 0.44 gives the K-10's 58 / 74 ms. The output tap reads the one-way delay, so arrivals come at T, 3T, 5T… Measured: 29.2 / 37.2 / 86.8 / 110.7 ms against the manual's 29 / 37 / 87 / 111 ms. |
| Frequency-dependent damping | A one-pole low-pass in the loop (1.5–11 kHz, set by Damping; 0.8 is the K-10 fit), plus the K-10 feed filters and the fitted transducer response. Long-term spectrum at K-10 defaults is within 2.1 dB RMS of the real K-10 IR, 63 Hz–8 kHz (`k10_spectrum_match`). |
| Resonant modes | A gain-normalised peak filter in the loop at 900–3000 Hz (set by Tension). Everything except the mode decays up to 3× faster, and loop gain never goes above g. |
| Mechanical instability | Two-pole random-walk drift of delay length and allpass stiffness, plus Poisson "jolts" (Movement). |
| Splash / collision | A transient detector (fast versus slow envelope) drives three things: a 6 Hz decaying sway oscillator (pitch swing, the "boing"), band-passed splash noise injected into the loop, and a saturation threshold that drops on hard hits (clatter). |
| Nonlinear behaviour | tanh saturation in the loop, plus the collision threshold. |
| Variable decay | Loop gain is calculated from the target RT60 using the loop's effective round-trip time at 400 Hz, because the allpass cascade delays lows far more than mids. Measured RT60 is within about ±17% of target across the Tension and Dispersion ranges, and within ±15% at default settings. |

Loop delay changes are smoothed over 20 ms, so Tension sweeps glide in pitch instead of clicking. Denormals are flushed (`|x| < 1e-15 → 0` in the reference, `fixdenorm` in gen~).

## C. Hybrid engine

| Mode | Routing | Why it exists |
|---|---|---|
| IR | conv(e) | The captured tank, untouched. |
| Model | spring(e) | Fully adjustable spring. |
| Parallel | cos(b)·IR·conv(e) + sin(b)·M·spring(e) | Tank body plus model boing and movement. Equal-power blend; the engines are uncorrelated, so they sum in power (measured −0.4 dB versus the ideal, no cancellation). |
| IR>Model | (1−b)·conv(e) + b·spring₀.₃(conv(e)) | Model decay is scaled ×0.3 so its resonances don't double the IR's. The model then adds sway, splash and movement to a real tank. |
| Model>IR | (1−b)·spring₀.₃(e) + b·conv(spring₀.₃(e) + ½e) | The model "drives" the tank. Half of the direct signal keeps the IR's own attack. |

**Parallel versus serial:** both were built, and both stay because they sound different. Parallel keeps the IR's transient intact and adds movement on top. The serial modes put the motion inside the tank's resonance, which suits drones and *Broken Spring*. **Whether hybrid sounds better than either engine alone is not proven yet.** The tests show it measurably differs from both (correlation < 0.95 with each), but that's no substitute for listening. It's a Dub Producer acceptance item.

Tone, Width and output colour are shared post-processing. Damping and Decay are applied to each engine, in each engine's own way.

## Nonlinear processing

| Stage | Implementation |
|---|---|
| Input drive | Pre-emphasis (up to +8 dB treble) → asymmetric tanh (bias 0.15, so even harmonics) → crossfade into a hard knee (x/(1+\|x\|⁶)^⅙) above 60% → de-emphasis → DC block. Treble distorts first, so the distortion depends on frequency (measured: THD at 3 kHz is greater than at 200 Hz). |
| Output colour | Asymmetric tanh with unity small-signal gain. Its strength follows Drive. |
| Loop saturation | tanh inside each spring loop, plus the collision clatter. |

None of these is a hard clip with an "analogue" label. Each curve is smooth and biased, and level-compensated so its small-signal gain doesn't rise with drive.
