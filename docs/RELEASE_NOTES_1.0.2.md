# Shrugame 1.0.2

Version 1.0.2 is a navigation-focused update.

## Changes

- Every forward room transition is now activated by walking through the far-right edge of the screen.
- The roads from Levels 1 through 4 use the same right-edge rule to reveal the next district.
- Banana-burbs now follows one clear route: suburb, plaza, laboratory, Nitin and the popcorn event, then Deepak's mayor complex.
- The hidden north exit from Monkey Plaza has been removed.
- Side collision margins are narrower, allowing Shrububu to reach edge triggers naturally.
- Existing save files remain compatible.

## Verification

- The 30-test Godot release suite covers all 27 rooms and the complete Level 1-5 progression graph.
- Electron starts each smoke test in isolated storage, preventing old saves or cached exports from changing the result.
- A dedicated runtime test loads the Level 2 laboratory, walks right without interaction input, and verifies arrival in the lab approach.
- Windows and macOS packages are generated from the tagged source and include SHA-256 manifests.

## Platform Notice

Windows and macOS packages remain unsigned and may show a first-launch security warning.
