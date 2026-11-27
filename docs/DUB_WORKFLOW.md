# Dub workflow and Ableton routing templates

Owner: Dub Organiser (with the Dub Producer). These are written as step-by-step recipes because `.als` templates couldn't be built or checked without Live. **Status: Implemented as documentation, not tested in a session.** After testing, save each one as a Live template set in `templates/`.

## R1 — Classic spring send (start here)
1. Make a return track called **SPRING**. Add Echolivity → *03 DUB - Deep Dub Spring* and set Mix to 100%.
2. After it, put EQ Eight: high-pass at 150 Hz (keeps the sub clean) and a gentle −3 dB shelf above 8 kHz.
3. On the rimshot, snare and skank tracks, set the send to SPRING at −12 dB. Automate the send ("throws") rather than the reverb.
4. Gain staging: hit the device at around −12 dBFS peaks. Drive is set for that level.

## R2 — Delay into spring (the classic chain)
1. Return **DELAY**: Echo or Delay (dotted 1/8, 30–40% feedback, filtered).
2. On DELAY, turn on the send to **SPRING**. Leave the spring-to-delay send *off* for now.
3. Throw a snare into DELAY. Each repeat now gets the spring, so the repeats bloom.

## R3 — External feedback loop (spring ↔ delay)
1. Use R2, then also turn on SPRING → DELAY at −inf and bring it up slowly.
2. Live allows sends between return tracks. The loop's level is the product of the two send levels. **Safeguards:**
   - Put Limiter on DELAY (ceiling −3 dB).
   - Map both sends to one Macro so you can kill the loop with a single knob.
3. Use Echolivity's Tone to stop the loop building bass. Tilt it to +0.3.

## R4 — Performance dub
1. SPRING return with *07 DUB - Long Dub Tail*.
2. MIDI-map **Mix**, **Decay**, **Tension** and **Boing** to four hardware knobs.
3. Gesture: throw a rimshot, open Decay for a long wash, sweep Tension for a pitch dive, then pull Decay back. For regeneration, use R3 (the delay ↔ spring loop): Fisher Spring has no internal feedback since 27 Nov 2026.

## R5 — Spring in the drum bus (insert)
Use *09 PERC - Short Percussion Spring* at 20–30% Mix directly on the hats or percussion bus. Keep Width at 140% or less for mono compatibility. The stereo correlation check shows 0 to 0.9 correlation and no mono cancellation.

## Interaction notes (to test in session; see `reports/PRODUCTION_USABILITY.md`)
- **Saturation before the spring** (for example Saturator → Echolivity): double drive. Lower Echolivity's Drive.
- **Filter after the spring** (Auto Filter LP sweep on SPRING): the classic dub sweep. It works with every engine mode.
- **Sidechain:** compress SPRING keyed from the kick, so the tail ducks under the beat.

## Portability
- Keep `Echolivity/` (with `device/`, `ir/` and `presets/`) in the User Library. Collect All and Save copies the frozen device into the project, but **not** the IR library. User IRs dropped onto the device should be stored in the project folder before collecting.
