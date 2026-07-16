# Shrugame 1.0.5 QA Report

Date: 2026-07-16
Engine: Godot 4.7 stable
Desktop shell: Electron 43.1.0

## Automated Baseline

- All 35 active release tests pass in two consecutive final runs.
- Pass 75 verifies the Auticity terminal, schema-4 migration, authored interaction geometry, four-direction approach positions, deterministic focus, and state suppression.
- Pass 76 compares every regenerated horizontal frame against the correct source pose for all five Shrububu forms and checks runtime facing updates.
- Pass 77 drives live district scenes through all 27 rooms and ten battle scenes on both difficulties, including required clues, gear, growth, saves, restarts, IshiYoga's rescue, and the birthday ending.
- The reachability audit expands blockers by Shrububu's largest collision footprint and verifies activation positions for every critical interaction and east exit.

## Ten QA Passes

| # | Scope | Result | Evidence |
| ---: | --- | --- | --- |
| 1 | Resource, JSON, scene, script, and version parsing | Pass | 35-test suite; editor/script parse contracts; synchronized `1.0.5` metadata |
| 2 | Save migration, atomic writes, restart, and Continue | Pass | Passes 31, 66, 71, 75, and 77; schema-4 rewrite fixture |
| 3 | Complete progression graph and softlock search | Pass | Pass 77 on both modes; all 27 rooms and ten bosses |
| 4 | Interactions, clues, items, rewards, and room exits | Pass | Passes 74, 75, and 77; collision-footprint reachability audit |
| 5 | Ten encounters on Shrububu difficulty | Pass | Passes 51, 69, and 77 |
| 6 | Ten encounters on SRMT difficulty | Pass | Passes 32, 41, 51, 69, and 77 |
| 7 | Shrububu orientation and action-sheet consistency | Pass | Pass 76 pixel comparisons and runtime-facing assertions |
| 8 | Keyboard/controller focus, pause, dialogue, cutscene, and locked states | Pass | Pass 75 plus existing input, tutorial, and accessibility contracts |
| 9 | Electron Web runtime, offline persistence, and SFX-only audio | Pass | Default, Level 2, Auticity, and full-progression Electron probes |
| 10 | Packages, checksums, versions, website, and private-file leak audit | Pass | Release audit; four staged artifacts; Vite build |

## Runtime Evidence

- Source Electron smokes pass independently for default boot, the full Level 2 laboratory route, Auticity records-to-Sushan, and the five-level save/transition chain.
- The final Windows portable executable completes the Auticity keyboard route in `serum_ward`, focuses `DoctorSushan`, and launches `doctor_sushan_boss`.
- The same portable executable verifies four persisted district transitions and reaches `level_05/ruined_boulevard` with no reported failures.
- Both portable probes find a focused `640x360` canvas, writable IndexedDB, changing frames after input, zero renderer console errors, and zero continuous audio players.
- The active suite performs two complete deterministic gameplay routes through live scenes and interactions, one per difficulty, and reloads the save after each district transition.

## Artifacts

- `Shrugame-1.0.5-windows-x64-Setup.exe`
- `Shrugame-1.0.5-windows-x64-Portable.exe`
- `Shrugame-1.0.5-macos-x64.zip`
- `Shrugame-1.0.5-macos-arm64.zip`
- `SHA256SUMS.txt`, `ARTIFACTS.txt`, and `artifact-manifest.json`

The macOS archives contain the correct x86_64/arm64 Mach-O executables, `1.0.5` plist metadata, executable modes, and 14 framework symlinks. They were structurally validated on Windows with WSL; this is not a native macOS runtime test.

## Residual Limitations

- All desktop builds are unsigned and may trigger platform security warnings.
- Native macOS runtime CI depends on the GitHub-hosted macOS runner. If the repository billing lock prevents that job from starting, macOS validation remains structural-only for this release.
- Historical Pass 1-29 prototype tests remain excluded because they assert retired blockout behavior.
