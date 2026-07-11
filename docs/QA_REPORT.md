# Shrugame 1.0.0 QA Report

Date: 2026-07-11  
Engine: Godot 4.7 stable  
Desktop shell: Electron 43.1.0

## Automated Baseline

- 29 active headless Godot tests pass.
- 28 release-contract tests pass in the standard suite.
- 76 Pass 1–29 files were moved to `tests/legacy_obsolete/` because they assert retired 320x180 blockout behavior, visible route labels, and historical README text.
- All JSON parses, all active scripts load, and the editor parse completes without errors.

## Ten QA Passes

| # | Scope | Result | Evidence |
| ---: | --- | --- | --- |
| 1 | Resource, JSON, scene, and script parsing | Pass | Editor parse log; all `data/**/*.json`; Passes 47, 52–68 |
| 2 | New Game, Continue, difficulty lock, migration, atomic write, corrupt-save recovery | Pass | Passes 31, 48, 66 |
| 3 | Five-level progression graph and softlock search | Pass | Pass 69 validates every room graph, exit target, spawn, gate, boss flag, clue, gear reward, and ending route |
| 4 | Every interaction, dialogue ID, visual, clue, save point, and room transition | Pass | Passes 52–63 and 69 |
| 5 | All ten bosses on Shrububu mode | Pass | Passes 51 and 69; phase recovery and easy multipliers verified |
| 6 | All ten bosses on SRMT mode | Pass | Passes 32, 41, 51, and 69; no automatic recovery and hard multipliers verified |
| 7 | Visual QA at minimum/default/1080p | Pass | Electron captures at 960x540, 1280x720, and 1920x1080; ending blockout found and replaced during review |
| 8 | Keyboard, controller, remapping, pause, settings, accessibility, focus | Pass | Passes 37, 41, 65, and 66 |
| 9 | Electron offline boot, packaged Windows runtime, audio, canvas, persistence | Pass | Packaged runtime report: canvas 640x360, audio running, IndexedDB writable, zero console errors |
| 10 | Landing site, artifacts, version, checksums, credits, ending, private-file leak audit | Pass | Passes 33, 62, 67, 68; Vite production build; release-file audit |

## Runtime Route Smoke

Electron smoke routes passed for title/New Game, Levels 1–5, Poojan battle, and ending. Each route found a focused 640x360 canvas, initialized audio, wrote IndexedDB, accepted input, and produced no renderer console errors.

## Windows Artifacts

- `Shrugame-1.0.0-windows-x64-Setup.exe`
- `Shrugame-1.0.0-windows-x64-Portable.exe`

Both are unsigned. Final SHA-256 checksums are generated after the last package build and attached to the GitHub Release.

## macOS

The release workflow builds unsigned Intel and Apple-silicon DMG/ZIP artifacts on `macos-14`. These packages are smoke-checked by CI; signing and notarization are intentionally deferred.

## Residual Limitations

- Initial builds are unsigned and may trigger platform security warnings.
- Automated tests validate complete progression state and every boss contract; they do not substitute for external usability testing by multiple new players.
- Historical prototype tests are retained but excluded because their expected behavior no longer exists in the production game.
