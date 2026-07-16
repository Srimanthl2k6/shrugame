# Shrugame

Shrugame is a five-district 2D pixel RPG about Shrububu's search for KFC through the SRMT-controlled town of Ishiville. It combines connected-room exploration, clue and gear progression, authored cutscenes, command-based encounters, and bullet-dodging enemy phases.

## Release Status

Version **1.0.6** includes:

- 27 connected rooms across Divorcee Harbour, Banana-burbs, Berry Barks, Auticity, and Area 111.
- Ten multi-phase encounters with Strength and Resonance outcomes.
- Two save-locked modes: Shrububu (extremely easy) and SRMT (extremely hard).
- Five slim Shrububu growth forms and four persistent equipment rewards.
- 28 data-driven cutscenes, five stateful dialogue sets, a clue journal, inventory, objectives, settings, controls, and credits.
- Native 640x360 Atkinson Hyperlegible UI text instead of enlarged low-resolution body text.
- First-play overworld and battle tutorials with device-aware prompts and in-game replay.
- Automatic, save-first district transitions, including the repaired post-Satyaki route to Banana-burbs.
- A consistent navigation rule: every new room and district is entered by walking through the far-right screen edge.
- A universal `x=600` transition fallback that does not depend on narrow collision-area overlap.
- Symmetric left/right edge transitions that permit only one room crossing per directional input.
- A linear Banana-burbs route with no hidden north exit or required backward search after the laboratory.
- Reachable visible 165-files and automatic required encounters through the complete Level 2 route.
- A repaired Auticity hospital route: the glowing records terminal now owns the required clue, objective, and atomic save.
- Schema-4 recovery for saves that already read the former hospital-map interaction.
- Centralized, nearest-target interactions with authored footprints, generous padding, a single world marker, and device-aware prompts.
- Correct per-form left/right Shrububu sprites, including repaired Forms 1-2 door-slam and weapon poses with Forms 3-5 unchanged.
- One persistent story song from launch through SRMT's defeat, with all other audio retained as one-shot SFX.
- The supplied birthday photograph and one-shot children-cheering cue on the final card.
- Enter, E, Escape, controller Confirm, and controller Cancel all return from the birthday card to the title.
- A working Electron Quit command with the native Godot fallback retained.
- One atomic, migration-safe save file with corruption fallback.
- Godot 4.7 Web embedded in a hardened Electron desktop shell.
- Windows x64 installer/portable builds and unsigned macOS Intel/Apple-silicon CI targets.
- A Vite/TypeScript landing page for GitHub Pages.
- The exact birthday ending requested for Tingu Verma.

## Play Locally

Godot:

```powershell
.\tools\godot\Godot_v4.7-stable_win64_console.exe --editor --path .
```

Electron:

```powershell
npm ci --prefix electron
npm run export:godot --prefix electron
npm start --prefix electron
```

## Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Move | WASD / arrows | Left stick / D-pad |
| Interact / confirm | E / Enter | South face button |
| Cancel / pause | Escape | East face button |
| Battle commands | 1-4 or menu navigation | D-pad + confirm |
| Fullscreen | F11 or Alt+Enter | Settings menu |

Bindings can be remapped in-game. Flash reduction, screen shake, high-contrast bullets, objective reminders, text speed, and Master/SFX volume controls persist outside the game save.

## Verification

```powershell
.\tools\run_release_tests.ps1
.\tools\run_release_tests.ps1 -IncludeLegacy
npm run build --prefix site
npm run smoke --prefix electron -- level_01
npm run smoke --prefix electron -- transition_level_01
npm run smoke --prefix electron -- right_edge_level_02
npm run smoke --prefix electron -- right_edge_harbour_square
npm run smoke --prefix electron -- level_02_lab_progression
npm run smoke --prefix electron -- level_04_hospital_progression
npm run smoke --prefix electron -- full_progression
npm run smoke --prefix electron -- ending_media
npm run smoke --prefix electron -- quit_button
.\tools\audit_release_files.ps1
```

The 36-test release suite validates story placement, assets, animation contracts, audio, menus, accessibility, save recovery, Electron isolation, website media, room connectivity, progression gates, reachable interaction positions, and a complete ten-boss walkthrough on both modes. See [QA_REPORT.md](docs/QA_REPORT.md).

## Build

```powershell
npm run build:win --prefix electron
```

macOS x64 and arm64 packages are produced by `.github/workflows/release.yml` on a version tag. Initial desktop packages are unsigned; Windows SmartScreen and macOS Gatekeeper may warn on first launch.

## Project Guide

- `assets/`: Runtime art, fonts, the single story track, and one-shot sound effects.
- `source_art/`: Non-exported generated production sources; private identity references are not stored here.
- `scenes/`: Main flow, 27 rooms, five district roots, battle, ending, and UI.
- `scripts/`: State, save, input, dialogue, cutscene, battle, overworld, UI, and presentation systems.
- `data/`: Dialogue, rooms, cutscenes, encounters, clues, items, gear, difficulty, and tuning.
- `electron/`: Desktop shell, Web export target, smoke runner, and packaging configuration.
- `site/`: Responsive release landing page.
- `tests/`: Headless Godot regression and release QA.
- `docs/`: Design, art, production, QA, system, and release documentation.

## Privacy And Attribution

Private real-life character reference folders are ignored by Git, isolated from Godot, and audited out of exports. Shrugame is an independent parody project and is not affiliated with or endorsed by KFC or any other referenced brand. No official logo or packaging is distributed.

Source code and original game assets are provided for inspection only unless a file-specific license says otherwise. See [LICENSE.md](LICENSE.md) and [CREDITS.md](CREDITS.md).
