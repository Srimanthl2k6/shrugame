# Changelog

## 1.0.5 - 2026-07-16

- Consolidated Auticity's optional hospital map and required records into one visible progression terminal.
- Added schema-4 migration that recovers existing saves which already read the old hospital map.
- Centralized interaction selection so one nearest, faced object receives input and a visible device-aware marker.
- Preserved authored interaction footprints and added 24x20 pixels of approach padding on every side.
- Kept prompts available when objectives are hidden and suppressed targeting during dialogue, cutscenes, pause, battles, and transitions.
- Corrected Shrububu's left/right turnaround mapping and regenerated all five forms, door slams, and weapon attacks.
- Added a 27-room, ten-boss deterministic walkthrough on both difficulties with save/restart checks after every district.
- Added reachability audits and packaged Electron probes for Auticity records-to-Sushan and the complete level-transition chain.

## 1.0.4 - 2026-07-16

- Made the visible, reachable laboratory files the canonical Level 2 progression interaction.
- Persisted the 165-files clue and story flag before the discovery cutscene, with existing-save compatibility.
- Automatically trigger the required Nitin, popcorn, and Deepak sequences when Shrububu reaches them.
- Centralized left and right edge transitions and consume one horizontal input per room crossing.
- Fixed held-left input skipping two rooms and normalized every west-edge trigger across all five districts.
- Added engine and packaged Electron regressions for the laboratory-to-Nitin path and reverse navigation.

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
