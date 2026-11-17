# Known limitations

## Not tested in Max or Live
- The device was built and checked **outside Max**. Its GenExpr was run through a translator, and its js under Node.
- These are unproven: gen~ compiling, the hand-built `.amxd` header loading in Live, the UI, real CPU use, the `---` per-instance buffer names, and the pattrstorage recall of the User IR path.
- The fallback if the `.amxd` won't load is to open the `.maxpat` (see the README).

## DSP
- **Convolution latency:** 21–23 ms on the IR path, not reported to Live. It acts as pre-delay. The dry path has no added latency.
- **CPU spike:** three FFTs (N = 1024/2048) run in a single sample at every convolution block boundary (every 512/1024 samples). This could crackle at very small buffer sizes.
- **IR length:** IRs are capped at 4 s (longer files are truncated with a 50 ms fade). The two BF "Bird-Verb" files (6–8 s) are affected.
- **Decay on IRs:** Decay can only shorten an IR. To lengthen one, use Feedback or the Model.
- **Decay accuracy:** the model's Decay is within about ±17% of target at extreme Tension/Dispersion combinations.
- **Resampling:** the device's js uses Lanczos-8, the reference uses polyphase. They differ by up to 0.3%.
- **Feedback loop latency:** one Live audio buffer in the device, 256 samples in the reference. Feedback renders therefore differ slightly from the reference.
- **Self-Osc character:** the gain control can let the level swell a little before it settles. The constants haven't been tuned by ear.
- **Stereo:** the K-10 returns the same mono reverb to both channels. Echolivity sends its two springs to L and R by default; Width 0 recreates the K-10. A CENTER-mode equivalent (mono dry + wet) isn't provided.
- **Drive** isn't calibrated in volts against the K-10's 7247 driver stage.

## Assets
- **Licenses:** all 8 third-party IRs (Fisher K-10, BF, Millertone) have **unconfirmed licenses**. They are flagged non-redistributable. Don't publish the device with them until their licenses are confirmed.
- **No Echolivity-made hardware capture exists.** The Fisher IR is third-party, with evidence but not verified by us.
- Two BF files appear to be **name-swapped** in the source pack.
- **Test material is synthetic.** Musical tests with real stems haven't been done.
- **Ableton `.als` routing templates** haven't been built; they exist as written recipes only.

## Process
- **No musical validation has happened.** That needs human listening (Dub Producer and Dub Organiser).
