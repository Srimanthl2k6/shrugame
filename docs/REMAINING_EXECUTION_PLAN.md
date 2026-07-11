# Shrugame Remaining Production And Release Plan

## Summary

The current project already has a working Godot 4.7 foundation, Electron Web wrapper, two difficulty modes, one-save progression, five Shrububu forms, cutscene infrastructure, the birthday ending, and passing smoke tests through Pass 46. Levels 1-4 have detailed environment backplates but remain compressed one-screen prototypes with inconsistent foreground art. Level 5 is still a blockout. Combat, animation, dialogue, audio, level depth, accessibility, website, packaging, and full-game QA remain below the requested release quality.

The finished product will use Godot Web inside Electron, ship unsigned-first Windows and macOS builds, deploy its landing page through GitHub Pages, and preserve the existing Ishiville story.

## Execution Contract

- Complete exactly one pass at a time unless the user explicitly authorizes multiple passes.
- After every pass:
  1. Run its automated tests.
  2. Capture relevant screenshots or recordings.
  3. Report completed work, defects found, and remaining risks.
  4. Stop.
  5. Recommend the intelligence level for the next pass.
- Never call a pass complete based only on files existing. Acceptance requires working runtime behavior.
- Do not preserve obsolete blockout structures merely because old smoke tests expect them; update tests to verify final behavior.
- Keep Shrububu slim in every form. Growth is expressed through height, posture, presence, animation, and equipment, never body width.
- Real-life reference photographs remain private, ignored by Git and Godot, and absent from exports, builds, website media, and release archives.
- Generated art is source material until it passes cleanup, scale, silhouette, animation, and in-game readability review.

## Locked Technical Decisions

- Runtime: Godot 4.7 Web export embedded in Electron.
- Internal game resolution: migrate from `320x180` to `640x360`.
- Default desktop window: `1280x720`; integer scaling; minimum `960x540`.
- World format: multiple connected rooms per level, not one labeled overview screen.
- Tile grid: `16x16`, with selected larger modular environment pieces.
- Save model: one atomic local save with schema migration.
- Difficulty cannot be changed after starting a save.
- Windows release: x64 NSIS installer and portable build.
- macOS release: x64 and arm64 DMG/ZIP builds from a macOS GitHub Actions runner.
- Initial packages are unsigned. Signing and Apple notarization are a later credential-gated upgrade.
- Website: static Vite/TypeScript site deployed to GitHub Pages.
- Public art may reference fried chicken and in-game KFC dialogue, but must not copy official logos, packaging, or imply affiliation.

## Phase A: Production Foundation

### Pass 47: Baseline, Documentation, And Asset Audit

- Record the actual current state instead of the obsolete Pass 29 README status.
- Create a production manifest classifying every scene, sprite, animation, dialogue set, audio file, and cutscene as `blockout`, `draft`, `curated`, or `final`.
- Add a modern-indie gap scorecard for world design, visual clarity, animation, combat, narrative, UI, audio, accessibility, performance, and release readiness.
- Capture baseline screenshots for title, five levels, battle, and ending.
- Preserve the passing Pass 33-46 tests as the migration baseline.

Acceptance: documentation matches the repository, private photos pass an export-leak scan, and the project parses with all current tests passing.

Suggested intelligence: High.

### Pass 48: 640x360 And Multi-Room Architecture

- Migrate viewport, UI anchors, cameras, collision coordinates, and Electron canvas sizing to `640x360`.
- Add reusable level-root, room, spawn-point, room-transition, camera-limit, foreground-occlusion, and ambience components.
- Extend level configuration with room IDs, scene paths, exits, spawn IDs, and room objectives.
- Add a compatibility migration for old saves that only contain level and spawn information.
- Build a two-room technical test district before migrating production levels.

Acceptance: room transitions preserve state and player position, cameras never expose void space, UI remains pixel-sharp at 720p/1080p, and old saves recover to a valid room.

Suggested intelligence: Max.

### Pass 49: Overworld Physics And Interaction Quality

- Rebuild movement around consistent acceleration, deceleration, diagonal normalization, collision sliding, and growth-form collision footprints.
- Add context-sensitive interaction icons, focus highlighting, authored collision shapes, blocked-route feedback, and input-device-aware prompts.
- Add keyboard and controller support with remapping.
- Remove visible route rails, diagnostic frames, legends, numbered steps, and labels that substitute for world art.
- Add idle route reminders only in Shrububu difficulty.

Acceptance: walking, collision, interaction, camera movement, room transitions, and controller switching feel stable without debug text explaining the map.

Suggested intelligence: High.

### Pass 50: Final Art Pipeline And Scale Bible

- Define fixed world-sprite, portrait, prop, boss, cut-in, and battle-animation scales.
- Maintain source art separately from processed runtime sprites.
- Finish Shrububu's five directional forms and action sheets using adult photos for identity and childhood photos only for expression cues.
- Add automated alpha, frame-size, frame-count, private-reference, and nearest-neighbor checks.
- Create final palette ramps, lighting rules, outline rules, and environmental material sheets for all districts.

Acceptance: all five Shrububu forms animate cleanly at runtime, stay slim, remain grounded, and use a consistent pixel density beside NPCs and scenery.

Suggested intelligence: Max.

### Pass 51: Battle Framework Production Upgrade

- Replace the temporary command strip with complete Act, Item, Gear, Guard, back, confirm, and cancel menus.
- Add revolver precision timing, banana-gun spread timing, berry-potion healing/status selection, and guitar rhythm counterpoint.
- Formalize Resonance as the mercy-equivalent outcome.
- Add deterministic phase sequencing, reusable attack timelines, telegraphs, hitboxes, invulnerability feedback, status effects, phase checkpoints, and boss animation hooks.
- Add lanes, rings, sweeps, arcs, ricochets, falling objects, rhythm notes, environmental hazards, and mixed callback patterns.
- Give Shrububu mode slow bullets, generous HP, strong telegraphs, phase checkpoints, and one automatic recovery per boss.
- Give SRMT mode additional variants, strict healing, faster attacks, shorter telegraphs, and no automatic recovery.
- Require every pattern to remain theoretically no-hit and visually readable.

Acceptance: a Poojan vertical-slice fight supports both victory routes, retry, save-safe rewards, controller input, and clearly different difficulty behavior.

Suggested intelligence: Max.

## Phase B: Full Level Production

### Pass 52: Divorcee Harbour World And Story

Build five connected rooms: Ishiville arrival and fake chicken storefront; harbour square and sheriff office; divorcee residences and docks; records alley and property archive; Satyaki waterfront approach.

Add seven distinct residents, environmental storytelling, rainy ambience, opening arrival, door-slam collapse, town reaction, clue chain, save point, optional interactions, and post-boss town variants.

Acceptance: the district feels explorable, its landmarks are recognizable without labels, and every required story step has clear visual guidance.

Suggested intelligence: Max.

### Pass 53: Poojan And Satyaki Final Encounters

- Poojan uses badge lanes, revolver ricochets, strength-test Acts, and awards the revolver.
- Satyaki uses legal-paper walls, broken-ring arcs, property-grid attacks, escalating dialogue, and a district-liberation aftermath.
- Both bosses receive intro, idle, talk, tell, release, hurt, defeat, and aftermath animation.
- Trigger Form 2 and verify revolver persistence.

Acceptance: Level 1 plays from New Game through the Level 2 transition on both difficulties without debug intervention.

Suggested intelligence: Max.

### Pass 54: Banana-Burbs World And Story

Build five connected rooms: identical happy suburb; monkey plaza; abandoned lab approach; 165-files laboratory; monkey rally and mayor complex.

Add eight monkey variants, intentionally uncanny synchronized loops, lab investigation, 165-files puzzle, popcorn spell-break cutscene, monkey-army route change, reactive dialogue, and post-clear behavior.

Acceptance: the lab clue is required, the popcorn scene visibly changes the population, and the mayor route opens through world state rather than labels.

Suggested intelligence: Max.

### Pass 55: Nitin And Deepak Final Encounters

- Nitin uses mop sweeps, wet-floor lanes, warning signs, and chemical-bottle arcs.
- Deepak uses smile waves, hypnotic patterns, banana motifs, and a moral-twist aftermath.
- Complete the banana-gun attack animation and Form 3 transformation.

Acceptance: Level 2 persists the 165-files clue, Deepak result, banana gun, and growth stage through its complete mystery-to-liberation arc.

Suggested intelligence: Max.

### Pass 56: Berry Barks World And Story

Build five connected rooms: Douglas Fir entrance; mist and berry paths; chef hut; community sharing clearing; Ankit exit route.

Use four substantial collection clusters and optional berry tasks to represent the 1000-berry order without repetitive pickup spam. Add residents, contract clues, potion crafting, sharing event, environmental animation, and post-clear dialogue.

Acceptance: collection is varied and readable, the false promise is staged, and berry potions become a useful persistent system.

Suggested intelligence: Max.

### Pass 57: Nishal And Ankit Final Encounters

- Nishal uses chef-tool patterns, berry baskets, cooking hazards, and promise-related Acts.
- Ankit uses plate volleys, hunger/rage phases, potion counterplay, and a defeat aftermath.
- Portray Nishal respectfully without racial caricature.
- Trigger Form 4 after Level 3.

Acceptance: Level 3 runs from collection through Ankit defeat without grind, softlock, or unusable potion state.

Suggested intelligence: Max.

### Pass 58: Auticity World And Story

Build five connected rooms: pun-heavy main street; hospital reception; Pattern Serum ward; Aeon Festival preparation plaza; festival stage and mayor route.

Preserve names and story functions while implementing the hospital control mechanic as fictional Pattern Serum rather than treating real autism as a curable disease. Add six or more NPCs, evolving autonomy states, hospital records, fireworks reveal, festival transition, and post-clear celebrations.

Acceptance: hospital discovery, serum reveal, town-state transition, festival setup, and boss route form one coherent district arc.

Suggested intelligence: Max.

### Pass 59: Sushan And Mitta Final Encounters

- Sushan uses serum trajectories, clinical grids, a failed-injection reveal, and hospital-machine hazards.
- Mitta uses festival lights, pageant movement, rhythm attacks, and a relationship-motivated confrontation.
- Preserve the relationship plot without making sexuality itself the attack or defeat mechanic.
- Trigger Form 5 and unlock Area 111.

Acceptance: Level 4 completes on both difficulties with readable fictional mechanics, finished spectacle, and persistent progression.

Suggested intelligence: Max.

### Pass 60: Area 111 World, Pub, And Mansion

Build seven connected rooms: ruined pink boulevard; Gummies pub interior; hooligan alley; bike route; fallen mansion foyer; mansion clue chambers; ruined court approach.

Create final cast art for the pub keeper, hooligans, mechanic, vendor, Suhas, SRMT, and IshiYoga. Add the Gummies interaction, bar-fight staging, controlled bike sequence, guitar acquisition, clue-driven mansion puzzles, KFC storage foreshadowing, and save-safe puzzle resets.

Acceptance: Suhas, bike, guitar, and mansion progression use one canonical flag set and cannot be skipped or softlocked.

Suggested intelligence: Max.

### Pass 61: Suhas, SRMT, Rescue, And Ending

- Suhas uses stools, gummy bowls, bike keys, guitar picks, and musical escalation.
- SRMT uses five major phases recalling every previous district and ending with guitar counterpoint.
- Give SRMT unique throne, chicken bucket, transformation, attack, hurt, and defeat art.
- Stage the dungeon reveal, IshiYoga rescue, KFC feast, Ishiville restoration montage, and final growth/victory beat.
- End with the exact text:

```text
Happy Birthday Tingu Verma.
~ Taklu Taklu Chuha.
```

Acceptance: Level 5 plays from entry through credits, requires the guitar, rescues IshiYoga, and shows the exact birthday card in native and Electron builds.

Suggested intelligence: Max.

## Phase C: Global Content And Presentation

### Pass 62: Dialogue And Narrative Editorial Pass

- Expand every minor NPC to pre-event, mid-event, post-boss, and optional states.
- Give major bosses 15-25 lines across introductions, phase changes, Acts, defeat, and aftermath.
- Rewrite clue text, item flavor text, objective copy, journal entries, and transition dialogue for clarity and eerie Pacific Northwest tone.
- Keep branching shallow and progression deterministic.
- Use `Unprovoked` after the building incident and Suhas accusation.
- Use `Ek Bihari, Sab pe Bhaari` during a justified strength declaration and the SRMT climax.
- Use `ehehehe` only at mischievous reward or KFC moments.
- Use `Shruti` only as an intentional nickname or NPC mistake.

Acceptance: a complete script read finds no filler, duplicated voices, random catchphrases, unclear objectives, or contradictions.

Suggested intelligence: Max.

### Pass 63: Global Art, Cutscene, And Animation Polish

- Replace all remaining crude, mismatched, or generated-looking foreground sprites.
- Add NPC idle/talk/reaction loops, boss tells, environment movement, foreground depth, particles, weather, and lighting changes.
- Extend cutscenes with camera pan/zoom, actor animation and facing, spawn/despawn, music-state changes, waits, signals, fades, and deterministic skip state.
- Produce cut-ins for the door collapse, weapon rewards, transformations, boss intros, throne reveal, and rescue.
- Remove every visible placeholder polygon and diagnostic label.

Acceptance: screenshot review at 720p and 1080p finds no block art, scale mismatch, overlap, missing animation, or debug presentation.

Suggested intelligence: Max.

### Pass 64: Music, Sound, And Game Feel

- Replace temporary loops with intentional district, boss, cutscene, menu, and ending music.
- Add ambience, footsteps, UI feedback, weapon sounds, clue cues, transitions, boss tells, impacts, and transformation stingers.
- Add ducking, fades, music-state transitions, spatial ambience, hit pause, restrained screen shake, flashes, and particles.
- Ensure flash-reduction and screen-shake settings affect every relevant effect.

Acceptance: no critical moment is silent, clipping, abruptly cut, or dependent on placeholder audio.

Suggested intelligence: High.

### Pass 65: Menus, Accessibility, Onboarding, And Credits

- Replace the sparse title screen with final key art and complete New Game, Continue, Settings, Controls, Credits, and Quit flows.
- Keep difficulty descriptions explicit: Shrububu is extremely easy; SRMT is extremely hard.
- Finish pause, journal, inventory, gear, objectives, battle menus, save confirmation, defeat/retry, and ending credits.
- Add remapping, controller glyphs, text speed, volume controls, flash reduction, shake toggle, objective toggle, high-contrast bullets, and hold-to-skip.
- Add playable onboarding instead of visible instructions covering the world.

Acceptance: all flows work with keyboard and controller, no text clips at supported resolutions, and settings persist independently of the save.

Suggested intelligence: High.

## Phase D: Desktop, Website, And Release

### Pass 66: Save And Electron Hardening

- Introduce a versioned save schema with level, room, spawn, difficulty, flags, inventory, gear, clues, bosses, growth, objective, and playtime.
- Use atomic writes, corruption fallback, migration tests, and explicit New Game overwrite confirmation.
- Harden Electron with context isolation, no renderer Node access, strict CSP, safe preload APIs, offline local loading, and controlled external links.
- Synchronize fullscreen/window state between Electron and Godot.
- Unify Godot, Electron, site, and release versioning through one source of truth.

Acceptance: save/load survives relaunch, malformed saves fail safely, Electron works offline, and no private/source-only files enter its package.

Suggested intelligence: High.

### Pass 67: Landing Page And Media Kit

- Build a responsive Vite/TypeScript site under `site/`.
- Use full-bleed actual game key art with `Shrugame` as the first-viewport signal.
- Add story, actual screenshots, a short gameplay clip, five districts, two difficulty modes, system requirements, accessibility, credits, and GitHub Release links.
- Avoid nested cards, fake screenshots, and unsupported claims.
- Add favicon, social preview, press kit, screenshot set, and trailer storyboard.
- Configure GitHub Pages with the repository base path.

Acceptance: desktop and mobile visual tests pass, all links work, and the site represents the actual release candidate.

Suggested intelligence: High.

### Pass 68: CI, Windows, And macOS Packaging

- Add GitHub Actions for Godot tests, Web export, Electron smoke tests, site build, Pages deployment, and tagged releases.
- Build Windows x64 NSIS and portable artifacts.
- Build separate unsigned macOS x64 and arm64 DMG/ZIP artifacts on macOS runners.
- Generate SHA-256 checksums, release notes, artifact manifests, and license notices.
- Launch-test the packaged Windows app locally.
- Smoke-test macOS packages in CI and document the unsigned Gatekeeper warning.

Acceptance: a version tag creates all expected artifacts and a deployable site without tests, source art, private photos, or development tools.

Suggested intelligence: High.

### Pass 69: Ten Explicit Debug And QA Passes

1. Resource, JSON schema, and scene parsing.
2. New Game, Continue, overwrite, migration, and corrupt-save recovery.
3. Complete progression graph and softlock search.
4. Every interaction, clue, item, gear reward, and room transition.
5. Every boss, pattern, retry, defeat, and reward on Shrububu.
6. Every boss, pattern, retry, defeat, and reward on SRMT.
7. Visual QA at 960x540, 1280x720, 1920x1080, windowed, and fullscreen.
8. Keyboard, controller, remapping, pause, accessibility, and focus handling.
9. Electron Windows package, macOS CI package, offline boot, and clean-install state.
10. Landing page, downloads, checksums, credits, ending, and private-file leak audit.

Targets: stable 60 FPS, no sustained drop below 58 FPS on the reference PC, desktop boot within 10 seconds, room transitions within 1.2 seconds, Electron working set below 700 MB, no overlapping UI, no unreadable text, no unavoidable boss damage, and no editor-only step.

Acceptance: all defects are fixed or explicitly classified as release-blocking, with no open release blocker remaining.

Suggested intelligence: Max.

### Pass 70: Release Candidate And Release

- Perform uninterrupted Shrububu and SRMT playthroughs.
- Verify every save point, boss flag, growth form, clue gate, weapon, cutscene skip, ending scene, and birthday message.
- Set version `1.0.0` and update README, changelog, credits, requirements, limitations, and release notes.
- Build final Windows and macOS artifacts from the tagged commit.
- Deploy GitHub Pages and publish the GitHub Release with checksums and unsigned-build disclosure.
- Launch the final Windows executable for user inspection.

Acceptance: the game is completable from launch to birthday ending on both difficulties, all artifacts match checksums, and the website points to the final release.

Suggested intelligence: Max.

## Interface And Data Changes

- `GameState` gains `schema_version`, `current_room_id`, `playtime_seconds`, and migration-safe serialization.
- Level configuration gains room definitions, exits, spawn points, objective stages, ambience, and state variants.
- Dialogue data gains state conditions, completion flags, alternate lines, speaker portraits, and post-boss variants.
- Encounter data gains pattern timelines, animation cues, phase checkpoints, Act results, Resonance outcomes, difficulty overrides, and accessibility hints.
- Cutscene steps gain camera control, animation control, music states, waits, signals, actor lifecycle, checkpointing, and deterministic skip application.
- Electron preload exposes only safe version, platform, fullscreen, quit, and external-link operations.
- A shared version file becomes the source for Godot, Electron, website, and artifact naming.

## Final Definition Of Done

- Five genuinely explorable multi-room levels replace the one-screen prototypes.
- All ten bosses have distinct mechanics, finished animation, and difficulty variants.
- Shrububu mode is extremely easy and story-first.
- SRMT mode is extremely hard, fair, and no-hit-capable.
- Art, animation, dialogue, cutscenes, level design, UI, audio, and game feel are consistently production-quality.
- No debug labels, colored block stand-ins, private photographs, or source-only assets ship.
- The exact birthday message appears after the complete ending.
- One save file works reliably.
- Electron packages work on Windows and macOS.
- The GitHub Pages landing page is live and references real release media.
- Automated tests, ten QA passes, and both full playthroughs pass.
- Signing and notarization are deferred from the unsigned-first `1.0.0` release.
