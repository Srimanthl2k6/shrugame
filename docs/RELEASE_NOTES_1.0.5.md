# Shrugame 1.0.5

Version 1.0.5 repairs Auticity progression, makes interactions predictable, corrects Shrububu's horizontal sprites, and adds an end-to-end route regression.

## Changes

- The glowing hospital records terminal is now the single required Auticity clue and includes SRMT's midnight note.
- Reading the terminal immediately grants `hospital_records`, updates the eastward objective, and atomically saves.
- Version 1.0.0-1.0.4 saves that used the former hospital map automatically recover the required records state under schema 4.
- Nearby interactions are selected centrally by boundary distance, facing, priority, and stable path; only one target receives input.
- Every target keeps its authored footprint with 24x20 pixels of additional padding per side and a visible keyboard/controller marker.
- Interaction prompts remain available when objective reminders are disabled.
- All five Shrububu forms now use the correct left/right source poses; right-facing door-slam and weapon sheets were regenerated.
- Cutscene facing changes update the visible sprite immediately and clear stale horizontal flipping.

## Verification

- 35 Godot release tests pass twice consecutively.
- A deterministic route completes all 27 rooms and ten bosses on Shrububu and SRMT difficulty.
- The route collects required clues and gear, restores one-save progression after every district, rescues IshiYoga, and reaches the birthday ending.
- Navigation reachability checks account for Shrububu's largest collision footprint and verify every critical interaction and east exit.
- Electron probes cover the real Auticity records-to-Sushan keyboard route and the packaged five-level transition/save chain.
- The Windows portable package is launch-tested locally; the installer is built and audited from the same packaged application.

## Platform Notice

Windows and macOS packages are unsigned and may show a first-launch security warning. macOS archives are structurally validated when GitHub's macOS runner is unavailable; this is not represented as a runtime test.
