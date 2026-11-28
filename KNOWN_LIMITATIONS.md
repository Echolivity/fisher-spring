# Known limitations

## Not tested in Max or Live
- The device was built and checked **outside Max**. Its GenExpr was run through a translator, and its js under Node.
- These are unproven: gen~ compiling, the hand-built `.amxd` header loading in Live, the UI, real CPU use, the `---` per-instance buffer names, and the pattrstorage recall of the User IR path.
- The fallback if the `.amxd` won't load is to open the `.maxpat` (see the README).
- **Fixed 19 Nov — no audio in Live (first real test):** the patch used `plugin~ 2` / `plugout~ 2`. In Max the number selects one channel, so the device only received the right input, and a mono or left-only source arrived as silence. Now `plugin~` / `plugout~` (channels 1 and 2). The IR loader also read the file's sample rate from the wrong `info~` outlet (6 instead of 0), which would have mis-resampled every IR. `tests/test_patch.py` now checks both, plus every connection into the IR loader.
- **Fixed 19 Nov — gen~ didn't compile (Max console from the first test):**
  - "function definitions not allowed here": gen~ wants helper functions before every other statement, including `Param` declarations. Moved to the top of each gen~ file.
  - "variable m is not defined": variables first created inside loops in the convolution code. Every such variable is now declared at the top level.
  - "can't find file ech_ir_loader.js / ech_ui.js": both scripts are now embedded in the device (`v8.codebox`, needs Max 9). The buffer names reach them as a load-time message.
  - `tests/test_patch.py` checks all three.
- **Panel (19 Nov redesign):** colours are fixed to the Echolivity palette, so the panel won't follow Live's theme. Percent controls run 0–100 on the dial and are scaled to 0–1 before the DSP. `docs/img/panel_preview.png` is an approximate render made without Live (`tools/preview_panel.py`); a few colour attributes may be named differently in Max and fall back to defaults.
- Each of these was invisible outside Max. More gen~ compile errors may surface once these are cleared; the Max console will name them.
- **Load-crash risk (mitigated, unverified):** a hand-built patch with the same structure crashed Live 12.4.15 / Max 9.1.5 inside the gen~ compiler (Twin Phasor 76, Nov 2026). On 18 Nov the build was changed to match Max's own conventions: `obj-N` ids inside the gen~ objects, a root parameter table with Push banks, and the root keys and `project` block Max writes. That fixed Twin Phasor; it hasn't been tested on this device yet. `tools/make_bisect.py` builds a 4-step diagnostic ladder.

## DSP
- **Convolution latency:** none since 27 Nov 2026 (three-stage convolver; verified outside Max to 1e-15 against convolution with no delay). Confirmed by ear in Live on 28 Nov 2026 (no gap between dry and spring at Mix 50%).
- **CPU:** the long-block FFTs are now spread across samples; the heaviest sample does about 1,900 operations instead of 16,000–34,500. The convolver does about 25–33% more work on average than before. Real Max CPU is unmeasured.
- **IR length:** IRs are capped at 4 s (longer files are truncated with a 50 ms fade). The two BF "Bird-Verb" files (6–8 s) are affected.
- **Decay on IRs:** Decay can only shorten an IR. To lengthen one, use the Model, or loop it with a delay return (`docs/DUB_WORKFLOW.md`, R3).
- **Decay accuracy:** the model's Decay is within about ±17% of target at extreme Tension/Dispersion combinations.
- **Resampling:** the device's js uses Lanczos-8, the reference uses polyphase. They differ by up to 0.3%.
- **Model>IR send:** the spring output reaches the convolver one Live audio buffer late (tapin~/tapout~), so Model>IR differs slightly from the reference, which has no delay there.
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
