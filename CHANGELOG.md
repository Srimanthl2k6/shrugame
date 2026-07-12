# Changelog

## 1.0.3 - 2026-07-12

- Fixed Harbour Square and other rooms where collision geometry could stop Shrububu before the edge Area2D activated.
- Added a universal far-right threshold that directly activates each room's east exit at `x=600`.
- Kept story and boss requirements intact while ensuring movement is the only input needed to change rooms.
- Added a 27-room engine regression and a dedicated Harbour Square Electron runtime probe.

## 1.0.2 - 2026-07-12

- Anchored every forward room and district transition to the far-right edge of the screen.
- Reduced side-wall collision margins so the player can physically reach edge triggers.
- Reordered Banana-burbs into a linear plaza, laboratory, Nitin/popcorn, and mayor route.
- Removed the hidden north mayor exit and all required north/south progression exits.
- Added clean-session Electron smoke coverage that walks across a real Level 2 edge transition.
- Fixed Electron smoke failures so they return a nonzero process status instead of being masked by application shutdown.

## 1.0.1 - 2026-07-12

- Replaced functional Silkscreen body text with native-resolution Atkinson Hyperlegible UI typography.
- Added first-play controls, movement, interaction, battle-command, and dodge tutorials with replay support.
- Replaced direct post-boss scene links with automatic, atomic, save-first Level 1-5 transitions.
- Fixed the post-Satyaki road so walking east reliably enters and saves Banana-burbs.
- Removed all looping music and ambience; retained non-looping gameplay and interface SFX.
- Added packaged Electron regression routes for tutorial input, three desktop sizes, SFX-only diagnostics, and Level 1 progression.

## 1.0.0 - 2026-07-11

- Rebuilt five prototype maps as 27 connected 640x360 rooms.
- Added the complete Ishiville story from Shrububu's arrival through IshiYoga's rescue.
- Added ten three-to-five-phase boss encounters, active weapons, Resonance, and two extreme difficulty modes.
- Added five Shrububu growth forms, room art, cast art, cutscenes, music, sound, menus, remapping, and accessibility settings.
- Added atomic save/settings/input persistence with migration and corruption fallback.
- Added Electron Windows/macOS packaging, release CI, checksums, and a GitHub Pages landing site.
- Added the exact birthday message: `Happy Birthday Tingu Verma. ~ Taklu Taklu Chuha.`
