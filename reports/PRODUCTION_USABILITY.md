# Production usability report (Dub Organiser)

**Status: preliminary desk review only.** Not yet tested in real sessions (see `docs/DUB_WORKFLOW.md` for the session plan).

## Asset organisation
- **IRs:** 13 catalogued. 1 duplicate was found by the hash audit and removed. 5 non-spring files and 1 non-IR recording were rejected (logged in `ir/rejected/REJECTED.md`). Provenance and license status are recorded for every entry. 8 third-party IRs have an **unconfirmed license**, so they're flagged non-redistributable.
- **Naming:** `TP_`/`SYN_` prefixes, maker, model, channel count and sample rate. The Fisher entry carries timing evidence.
- **Two BF "Bird-Verb" files are probably mislabelled.** Each one's statistics match the *other* amp's mono IR. They're kept, with a note in their descriptions. Ask the pack's author.
- **Presets:** 10 presets in 4 categories, all gain-staged by the automated check.

## Controls: desk review
| Finding | Recommendation |
|---|---|
| IR Level, Model Level and Hybrid Blend overlap in Parallel mode (three ways to set one balance). | Keep for now. If sessions show the levels are never touched, hide IR/Model Level behind Blend. |
| Damping (core) and FB Damping (dub) can be confused. | The label is "FB Damp". Keep it in the DUB section. |
| Movement and Modulation can be confused (random versus periodic). | Keep both. Movement is the "broken spring", Modulation is a slow chorus. Revisit after listening. |
| Engine Mode has 5 options. | Session test: do the serial modes earn their place? |
| No CENTER/REVERB ONLY mode switch like the K-10. | Covered by Mix 100% and Width 0. Add a "K-10 mono return" preset if users want it. |

## Workflow
Routing recipes R1–R5 are documented. Live templates (`.als`) are **not built**. Build them in Live after session testing.

## Sign-off
Open, pending session tests.
