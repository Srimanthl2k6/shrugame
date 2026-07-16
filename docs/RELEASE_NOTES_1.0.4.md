# Shrugame 1.0.4

Version 1.0.4 repairs the complete Banana-burbs laboratory route and prevents reverse navigation from skipping rooms.

## Changes

- The visible 165-files on the laboratory floor are now the required story evidence.
- The files sit on walkable ground, collect the canonical clue, update the objective, and save immediately.
- Walking right after the discovery reliably reaches Nitin.
- Nitin, the popcorn spell-break, and Deepak now start automatically when reached on the required route.
- Left and right room exits share one directional transition coordinator.
- Holding a direction can cross only one room; release and press again to cross another.
- Every west exit targets the immediate previous room and uses consistent edge geometry.
- Existing version 1.0.0-1.0.3 saves remain compatible.

## Verification

- The 32-test Godot suite exercises the real laboratory interaction, save persistence, Nitin startup, all forward routes, and every reverse route.
- A tagged Windows Electron probe starts with no laboratory progress and must reach the Nitin encounter through player input.
- Windows and macOS packages include SHA-256 and artifact manifests.

## Platform Notice

Windows and macOS packages remain unsigned and may show a first-launch security warning.
