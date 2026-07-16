# Shrugame 1.0.6 QA Report

Date: 2026-07-16
Engine: Godot 4.7 stable
Desktop shell: Electron 43.1.0

## Automated Baseline

- All 36 active release tests pass in two consecutive final runs after the final Electron input repair.
- Pass 75 verifies the Auticity terminal, schema-4 migration, authored interaction geometry, four-direction approach positions, deterministic focus, and state suppression.
- Pass 76 compares every horizontal frame against its per-form source map, verifies Forms 1-2 were corrected, and confirms Forms 3-5 stayed unchanged.
- Pass 77 drives live district scenes through all 27 rooms and ten battle scenes on both difficulties, including required clues, gear, growth, saves, restarts, IshiYoga's rescue, and the birthday ending.
- Pass 78 verifies the two imported MP3s, imported birthday photograph, both SRMT outcomes, completed-save silence, New Game restart, ending actions, and secure Electron Quit contract.
- The reachability audit expands blockers by Shrububu's largest collision footprint and verifies activation positions for every critical interaction and east exit.

## Ten QA Passes

| # | Scope | Result | Evidence |
| ---: | --- | --- | --- |
| 1 | Resource, JSON, scene, script, and version parsing | Pass | 36-test suite twice; editor/script parse contracts; synchronized `1.0.6` metadata |
| 2 | Save migration, atomic writes, restart, and Continue | Pass | Passes 31, 66, 71, 75, and 77; schema-4 rewrite fixture |
| 3 | Complete progression graph and softlock search | Pass | Pass 77 on both modes; all 27 rooms and ten bosses |
| 4 | Interactions, clues, items, rewards, and room exits | Pass | Passes 74, 75, and 77; collision-footprint reachability audit |
| 5 | Ten encounters on Shrububu difficulty | Pass | Passes 51, 69, and 77 |
| 6 | Ten encounters on SRMT difficulty | Pass | Passes 32, 41, 51, 69, and 77 |
| 7 | Shrububu orientation and action-sheet consistency | Pass | Pass 76 pixel comparisons; only the 12 requested Forms 1-2 sheets changed |
| 8 | Keyboard/controller focus, pause, dialogue, cutscene, and locked states | Pass | Pass 75 plus existing input, tutorial, and accessibility contracts |
| 9 | Electron Web runtime, story-music lifecycle, ending keys, and Quit | Pass | Default, Level 2, Auticity, progression, three ending sizes, and real Quit probes |
| 10 | Packages, checksums, versions, website, and private-file leak audit | Pass | Windows package smokes; macOS structure checks; Vite build; release audit |

## Runtime Evidence

- Source Electron smokes pass independently for default boot, Level 2, Auticity, the five-level transition chain, the birthday ending, and the title Quit command.
- Ending captures at `960x540`, `1280x720`, and `1920x1080` show the complete 1194x1600 photograph without cropping or text overlap.
- The packaged Windows app verifies that Enter returns the ending to title with story music stopped and `children_yay` played once.
- The packaged Windows app also receives the secure `app:quit` IPC command and terminates within the smoke timeout.
- The active suite performs four complete deterministic gameplay routes through live scenes and interactions across its two final runs, split evenly across both difficulties.

## Artifacts

- `Shrugame-1.0.6-windows-x64-Setup.exe`
- `Shrugame-1.0.6-windows-x64-Portable.exe`
- `Shrugame-1.0.6-macos-x64.zip`
- `Shrugame-1.0.6-macos-arm64.zip`
- `SHA256SUMS.txt`, `ARTIFACTS.txt`, and `artifact-manifest.json`

The macOS archives pass CRC checks and contain the correct x86_64/arm64 Mach-O executables, `1.0.6` plist metadata, executable modes, 14 safe framework symlinks, and all three new media markers. This is structural Windows-side validation, not a native macOS runtime test.

## Residual Limitations

- All desktop builds are unsigned and may trigger platform security warnings.
- Native macOS runtime CI depends on the GitHub-hosted macOS runner. If the repository billing lock prevents that job from starting, macOS validation remains structural-only for this release.
- Historical Pass 1-29 prototype tests remain excluded because they assert retired blockout behavior.
