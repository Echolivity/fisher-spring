# DSP architecture

Owner: DSP Engineer. The specification is `reference/engine.py`, and the device code is a port of it (`device/gen/`). Parameter names and ranges come from `reference/params.py`.

## Signal flow

```
 dry L/R ───────────────────────────────────────────────────────────────┐
    │                                                                    │
    └─► mono ─► INPUT DRIVE ─► (+) ─► PREDELAY ─┬─► CONVOLUTION ─┐       │
                               ▲                └─► SPRING MODEL ─┤      │
                               │                                  ▼      │
                               │                          ENGINE ROUTER  │
                               │                         (5 modes, blend)│
                               │                                  │ wet  │
                               └──── DUB FEEDBACK LOOP ◄──────────┤      │
                                                                  ▼      ▼
                                   TONE ─► WIDTH ─► OUTPUT COLOUR ─► MIX ─► OUTPUT
```

In the device this is split into three gen~ objects:

- **front:** drive, feedback injection, predelay and the convolution send.
- **conv:** the partitioned convolver.
- **back:** springs, router, feedback and output.

Two `tapin~`/`tapout~` pairs close the loops (dub feedback, and the Model>IR send). Each adds one signal vector of delay. The reference engine processes in 256-sample blocks, so its feedback loop has 256 samples of latency. Feedback timing therefore differs slightly between the two by design.

The tanks are mono-in like real hardware: the stereo input is summed before the drive stage. Stereo comes from the two different springs, or from the two IR channels.

## A. Convolution engine

- **Algorithm:** uniformly partitioned overlap-save convolution. The block size B is 512 at 48 kHz and below, and 1024 at 88.2/96 kHz. FFT size is 2B.
- **Real-time scheduling:** the K partition multiply-accumulates are spread evenly across the B samples of each block. That keeps CPU use per sample flat, except for three FFTs (two inverse, one forward) at each block boundary. The cost is a latency of **2B samples (21.3 ms at 48/96 kHz, 23.2 ms at 44.1/88.2 kHz)**. It behaves as a fixed pre-delay on the IR path. The reference engine adds the same latency, so both produce the same output.
- **IR conditioning** (`prepare_ir`, `ech_ir_loader.js`):
  1. Resample. The reference uses polyphase; the js uses Lanczos-8, and the two differ by ≤0.3% in the port check.
  2. Cap at 4 s with a 50 ms fade.
  3. Apply the Decay envelope. It can only shorten the IR: it adds exponential decay toward the target RT60.
  4. Apply Damping: extra decay on the band above 2 kHz, using a zero-phase one-pole split.
  5. Energy-normalise, so white noise in gives the same RMS out.
- **Mono/stereo IRs:** a mono IR is copied to both channels. A stereo IR convolves the mono tank input separately with each channel.
- **Recompute:** Decay and Damping changes are debounced by 250 ms, and the resampled IR is cached. While H is rewritten, the convolver is muted (`nparts 0`).
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
| Feedback saturation | Asymmetric tanh in the dub loop, gain 1–15 (FB Drive). |
| Loop saturation | tanh inside each spring loop, plus the collision clatter. |

None of these is a hard clip with an "analogue" label. Each curve is smooth and biased, and level-compensated so its small-signal gain doesn't rise with drive.

## Dub feedback

```
wet ─► mono ─► 2-pole HP + 2-pole LP (FB Tone) ─► LP (FB Damping) ─► asym sat (FB Drive)
   ─► × (0.98·Feedback + 0.6·Self-Osc) / engine_peak ─► × guard ─► peak limiter (−6 dBFS) ─► DC block ─► back into the tank
```

- **engine_peak:** an estimate of the active path's loudest spectral peak. For the IR it's measured exactly at load. For the model it's a closed-form estimate (0.4–1× the true peak). For hybrid modes, the peaks are combined by root-sum-square or by the square root of their product. This makes the Feedback knob behave the same on every engine and setting.
- **Runaway guard:** a slow RMS watch on the loop. Above −20 dBFS (or 6 dB above the Self-Osc target) it pulls the loop gain down to as low as 0.4×. It is turned off in proportion to Self-Osc.
- **Self-Osc gain control:** a fixed peak estimate can't guarantee unity loop gain on every engine and IR. In early tests, Parallel and Model>IR wouldn't sustain. So with Self-Osc above 0, a gain control raises loop gain at 2 dB/s, up to 16×, until the loop's fast envelope reaches a target (−30 dBFS + 16 dB × Self-Osc), with a ±3 dB deadband. It backs off at 12 dB/s. In practice, higher Self-Osc builds faster and louder: 0.3 blooms over about 6–8 s, 1.0 locks within about 2 s. At Self-Osc 0 it decays back to 1× and has no effect.
- **Measured:** with Self-Osc at 0, no mode grows after the input stops, even at Feedback 100%. With Self-Osc at 100%, every mode sustains at a steady level, with peaks below 0.75, bounded by the limiter. The full numbers are in the technical validation report.
