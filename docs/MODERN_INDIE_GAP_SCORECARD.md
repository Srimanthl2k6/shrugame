# Shrugame Modern Indie Gap Scorecard

## Scoring

- `0`: absent
- `1`: prototype only
- `2`: functional but visibly underproduced
- `3`: coherent internal alpha
- `4`: polished small-indie release quality
- `5`: standout signature quality

The target is not AAA scale. It is a short game whose small scope feels deliberate, expressive, responsive, and complete.

| Area | Pass 47 | Release target | Evidence | Blocking work |
| --- | ---: | ---: | --- | --- |
| World and level design | 1.5 | 4.5 | Five single-screen route maps; little spatial exploration | 640x360 multi-room architecture and five district rebuilds |
| Visual clarity | 2.5 | 4.5 | Strong backplates in Levels 1-4, but mismatched foreground scale and Level 5 blocks | Scale bible, foreground replacement, room composition |
| Character animation | 2.0 | 4.5 | Shrububu sheets exist; most NPCs are static and bosses use offset-based animation | Authored NPC, boss-tell, reaction, and cutscene animation |
| Combat depth | 2.0 | 4.5 | Commands, dodge arena, phases, and difficulty multipliers work | Active weapon attacks, Resonance outcomes, timelines, status, boss identities |
| Narrative and dialogue | 2.5 | 4.5 | Canon and level dialogue exist; state depth and editorial consistency are incomplete | Multi-state NPC writing, boss dialogue, clue/item prose, continuity edit |
| Cutscenes | 2.0 | 4.5 | Data director supports core sequencing and safe skip state | Camera, animation, music-state, actor lifecycle, cinematic timing |
| UI and onboarding | 2.5 | 4.0 | Functional title, dialogue, objectives, journal, pause, and settings | 640x360 migration, final menus, remapping, onboarding, credits |
| Audio and game feel | 1.5 | 4.0 | Placeholder loops and basic event SFX exist | Intentional score, ambience, mix, footsteps, tells, impact and ducking |
| Accessibility | 2.0 | 4.0 | Volume, text speed, flash, shake, and objective toggles exist | Remapping, controller glyphs, contrast bullets, hold-to-skip, complete coverage |
| Performance and stability | 3.0 | 4.0 | Current small scenes run and Web export boots | Multi-room budgets, profiling, atomic saves, transition and memory targets |
| Desktop release | 2.5 | 4.0 | Electron/Web spike and Windows packaging config exist | Hardened save/runtime integration, icons, CI, Windows/macOS artifacts |
| Marketing and delivery | 0.5 | 4.0 | No landing page or release media set | Vite site, actual screenshots, media kit, Pages and GitHub Release |

## Highest-Risk Gaps

1. The current one-screen map architecture cannot deliver the requested exploration or visual density.
2. Detailed environment backplates are carrying crude or oversized foreground sprites.
3. Battles have structural breadth but insufficient interaction and attack identity.
4. Area 111 is not a production level.
5. There is no end-to-end release path proven for macOS.

## Review Rule

Update this scorecard after every major phase. Scores may only increase when runtime evidence, tests, and screenshots support the change. Documentation or asset counts alone do not increase a score.

## 1.0.0 Release-Candidate Review

| Area | Pass 47 | 1.0.0 RC | Runtime evidence |
| --- | ---: | ---: | --- |
| World and level design | 1.5 | 4.0 | 27 connected rooms with validated exits, spawns, gates, interactions, and district state changes |
| Visual clarity | 2.5 | 4.0 | Detailed 640x360 backplates, final title/ending treatment, scale contract, multi-resolution captures |
| Character animation | 2.0 | 3.8 | Five directional Shrububu forms, action sheets, boss animation hooks, cutscene actions |
| Combat depth | 2.0 | 4.0 | Ten three-to-five-phase bosses, active weapons, Resonance, readable tells, two difficulty variants |
| Narrative and dialogue | 2.5 | 4.1 | Five stateful dialogue sets, 28 cutscenes, clue continuity, controlled catchphrase placement |
| Cutscenes | 2.0 | 4.0 | Camera, actor, music, checkpoint, deterministic skip, reward, battle, and scene steps |
| UI and onboarding | 2.5 | 4.0 | Complete title, pause, controls, settings, journal, inventory, battle, retry, and ending flows |
| Audio and game feel | 1.5 | 3.8 | Nine release music loops, weapon/boss/UI SFX, crossfades, ducking, shake, flash, and particles |
| Accessibility | 2.0 | 4.0 | Remapping, controller glyph logic, text speed, flash/shake/contrast/objective controls |
| Performance and stability | 3.0 | 4.0 | Atomic persistence, Web/Electron offline smoke, 640x360 integer scaling, 29 active tests |
| Desktop release | 2.5 | 4.0 | Windows installer/portable built; macOS x64/arm64 automated on native CI |
| Marketing and delivery | 0.5 | 4.0 | Responsive Vite site, actual media, press kit, release workflows, checksums, release notes |
