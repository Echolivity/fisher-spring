# Musical validation report

Owners: Dub Producer, Dub Organiser, and the Sound Designer for textures.

**Status: OPEN. No listening has taken place.** Every row below is unscored. Nothing in this project is *Musically validated* until the Dub Producer and Dub Organiser sign it off here.

## Material
- **Renders:** `renders/` holds every preset × rimshot, snare, reggae pattern, dub-techno chords, bass stab and sustained synth.
  - `renders/engines/` is the hybrid A/B set: the same rimshot through IR, Model, Parallel, IR>Model and Model>IR, with the K-10 IR.
  - `renders/feedback/` covers Feedback 0 / 0.6 / 1.0 and Self-Osc 0.5.
- **Test material is synthesised** (`reference/signals.py`). It has to be repeated with real stems: your own rimshots, snares, hi-hats, percussion loops, reggae and dub-techno sessions, and full mixes.

## Protocol
1. Level-match (all renders are peak-safe; match loudness by ear or LUFS).
2. A/B **blind** wherever possible (shuffle file names).
3. Reference: the K-10 IR in *Fisher Reference*. Compare *Deep Dub Spring* and the model at the K-10 Tension of 0.44.
4. Score each criterion 1–5, and write one sentence of evidence for each score.

## Scoresheet

| Criterion | Rimshot | Snare | Hats | Perc loop | Reggae | Dub-techno | Bass stab | Synth | Full mix |
|---|---|---|---|---|---|---|---|---|---|
| Authenticity (vs K-10 IR) | | | | | | | | | |
| Transient response | | | | | | | | | |
| Metallic character | | | | | | | | | |
| Splash | | | | | | | | | |
| Decay | | | | | | | | | |
| Feedback musicality | | | | | | | | | |
| Tonal depth | | | | | | | | | |
| Stereo image | | | | | | | | | |
| Mix usability | | | | | | | | | |

## Specific acceptance questions (from the brief)
- [ ] Does a simple rimshot become a serious dub event? (*Deep Dub Spring*, *Infinite Dub*)
- [ ] Is hybrid audibly better than either engine alone? (`renders/engines/`) **This is the open question in the architecture.**
- [ ] Does the model at the K-10 Tension of 0.44 sound like a spring and not like an algorithmic reverb?
- [ ] Do Drive and the saturation stages respond musically, or do they just get louder and dirtier?
- [ ] Is feedback controllable during a performance? Is the guard too eager or too lax?
- [ ] Which of the 23 controls go unused in real sessions? (Feeds the production usability report.)
- [ ] Are the 10 presets genuinely different in use?

## Sign-off
| Role | Name | Date | Verdict |
|---|---|---|---|
| Dub Producer | | | |
| Dub Organiser | | | |
| Sound Designer (textures) | | | |
