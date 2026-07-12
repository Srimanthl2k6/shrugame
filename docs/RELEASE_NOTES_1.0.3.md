# Shrugame 1.0.3

Version 1.0.3 fixes movement-only room transitions at the far-right edge.

## Changes

- Reaching `x=600` now directly activates the current room's east exit.
- Room changes no longer depend solely on Shrububu overlapping a narrow Area2D beside the boundary wall.
- Harbour Square now reliably continues to the residences and docks by walking right.
- The same fallback applies to every room in all five districts.
- No interaction key is required to move between locations.
- Existing clue, boss, and story requirements remain intact.
- Existing save files remain compatible.

## Verification

- The 31-test Godot suite drives the far-right threshold through every canonical room-to-room transition.
- A dedicated Electron probe starts in Harbour Square at the position shown in the bug report, walks right, and must arrive in `residences_docks`.
- Existing Level 1-to-2 and Level 2 laboratory transition probes remain active.
- Tagged Windows and macOS packages include SHA-256 manifests.

## Platform Notice

Windows and macOS packages remain unsigned and may show a first-launch security warning.
