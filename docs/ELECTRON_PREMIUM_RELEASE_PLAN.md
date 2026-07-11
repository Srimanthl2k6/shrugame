# Shrugame Electron Premium Release Plan

## Purpose

This document is the next major production plan for turning the current Godot prototype into a polished Electron-distributed game with richer art, animation, cutscenes, dialogue, gameplay depth, a landing page, two difficulty modes, and Windows/macOS releases.

The current codebase is a Godot 4.7 project with five playable levels, JSON-driven story/combat data, generated placeholder art/audio, smoke tests, a Windows export preset, and a recently repaired presentation layer. It is not yet an Electron app. It does not yet have final art, final animation, modern-grade level composition, a landing page, macOS release packaging, difficulty selection, or the requested final birthday message.

The implementation rule for future agents is:

> Do not add surface features on top of weak presentation. Every pass must improve the weakest current production area before expanding scope.

## Non-Negotiable Product Goals

1. Keep the existing Shrububu/Ishiville story canon.
2. Convert the shipped desktop experience into an Electron app.
3. Preserve Godot as the game runtime unless a later technical spike proves the web export cannot support the game reliably inside Electron.
4. Add two difficulty modes:
   - **Shrububu**: extremely easy.
   - **SRMT**: extremely hard.
5. Upgrade every weak part of the game: art, animation, cutscenes, dialogue, level design, battle design, UI, audio, menus, save flow, release packaging, and marketing.
6. Build and release for:
   - Windows.
   - macOS.
7. Build a landing page for the game.
8. Add the exact post-win ending message:

```text
Happy Birthday Tingu Verma.
~ Taklu Taklu Chuha.
```

9. Compare the current game against modern game expectations and close the gaps with concrete production passes.
10. Keep verification mandatory. Every pass needs automated checks where possible and manual playthrough gates where automation is insufficient.

## Current Codebase Snapshot

### Existing Stack

- Engine: Godot 4.7.
- Language: GDScript.
- Current app type: Native Godot desktop game.
- Current export: Windows only, `export_presets.cfg` has one `Windows Desktop` preset.
- Main scene: `scenes/main.tscn`.
- Autoloads:
  - `GameState`: `scripts/core/game_state.gd`
  - `DialogueManager`: `scripts/dialogue/dialogue_manager.gd`
  - `SaveSystem`: `scripts/core/save_system.gd`
  - `AudioManager`: `scripts/core/audio_manager.gd`
  - `PresentationGuide`: `scripts/visual/presentation_guide.gd`
- Base resolution: `320x180`.
- PC window override: `1280x720`.
- Stretch mode: `canvas_items`, integer scaling.
- Current release metadata: `0.29.0`.

### Existing Content

- Five level scenes:
  - `scenes/levels/level_01.tscn`
  - `scenes/levels/level_02.tscn`
  - `scenes/levels/level_03.tscn`
  - `scenes/levels/level_04.tscn`
  - `scenes/levels/level_05.tscn`
- Ending scene:
  - `scenes/ending.tscn`
- Battle scene:
  - `scenes/battle/battle_scene.tscn`
- Data folders:
  - `data/dialogue/`
  - `data/encounters/`
  - `data/items/`
  - `data/gear/`
  - `data/clues/`
  - `data/levels/`
  - `data/tuning/`
- Existing smoke tests:
  - `tests/`

### Existing Systems

- Single save file via `scripts/core/save_system.gd`.
- Story flags and progression via `scripts/core/game_state.gd`.
- Gear, clues, inventory, defeated bosses, growth stage, and current objective exist.
- Basic battle manager supports:
  - Act.
  - Item.
  - Gear.
  - Guard.
  - Encounter JSON.
  - Boss phases.
  - Rewards.
  - Growth stage reward.
  - Required weapon gates.
- Presentation guide exists but should now be treated as temporary development assistance, not final game UI.

### Current Weaknesses

- No Electron app shell.
- No `package.json`.
- No web export preset.
- No macOS export preset.
- No `site/` or landing page.
- No difficulty selection UI.
- No difficulty state in save files.
- No difficulty tuning model.
- No final birthday message in `scenes/ending.tscn`.
- Art is still generated/placeholder-heavy.
- Level 1 and Level 2 have some readable assets, but Levels 3-5 remain visually underproduced.
- Cutscenes are not cinematic enough.
- NPC dialogue exists but is not yet dense, optional, reactive, or polished enough.
- Boss fights are structurally present but not modern-grade in animation, readability, mechanical variety, or dramatic escalation.
- Audio exists but is generated placeholder audio.
- UI is functional, not final.
- No installer, app icon, notarization/signing plan, or release notes.

## Modern Game Comparison

The target is not AAA scope. The target is a small, expressive indie game that feels intentional. The current project should be compared against modern indie expectations from games such as **Undertale**, **Deltarune**, **OMORI**, **Night in the Woods**, **Eastward**, **Celeste**, **Pizza Tower**, and **Hades** in terms of clarity, punch, animation feedback, tone consistency, and content polish.

### What Modern Players Expect

| Area | Modern Indie Expectation | Current State | Required Upgrade |
| --- | --- | --- | --- |
| First screen | Clear title, identity, options, difficulty, continue/new game, polished controls | Functional menu | Add final title screen, difficulty selection, settings, visual identity |
| Visual identity | Strong palette, readable silhouettes, cohesive world style | Mixed placeholder/generator assets | Full art bible execution, scene-by-scene art replacement |
| Animation | Idle loops, walk cycles, interact animations, boss tells, hit reactions | Mostly static sprites | Add animation state machines and finished sprite sheets |
| Dialogue | Memorable voices, optional lines, post-event changes, jokes with clue value | Basic JSON lines | Rewrite and expand dialogue per NPC state |
| Cutscenes | Staged camera, timing, character blocking, sound cues | Mostly direct interactions | Add cutscene director and authored sequences |
| Combat | Clear phases, readable bullets, meaningful choices, difficulty tuning | Basic phase/command system | Build difficulty-aware boss encounters with strong attack identities |
| Level design | Routes that feel like places, not labeled object clusters | Playable but still route-marker-heavy | Compose each level as a real environment with landmarks and affordances |
| UI | Diegetic/polished menus, legible pixel font, pause/settings | Functional panels | Final UI style, accessibility, controls, difficulty labels |
| Audio | Strong motifs, stingers, boss cues, impact feedback | Placeholder/generated loops | Final music and SFX pass |
| Release | Installer/app bundle, app icons, versioning, crash-free exports | Windows Godot exe only | Electron packaging for Windows/macOS plus release checklist |
| Marketing | Landing page, screenshots, trailer/gif, feature copy | None | Build landing page and media kit |

## Architecture Decision: Electron App

### Recommended Electron Strategy

Use **Electron as the desktop shell** and run a **Godot Web export** inside it.

Planned structure:

```text
electron/
├── package.json
├── electron-builder.yml
├── main.js
├── preload.js
├── renderer/
│   ├── index.html
│   ├── styles.css
│   └── loading.js
├── godot-export/
│   └── web/
│       ├── index.html
│       ├── Shrugame.js
│       ├── Shrugame.wasm
│       └── Shrugame.pck
└── assets/
    ├── icon.ico
    ├── icon.icns
    └── icon.png
```

The Electron shell should:

- Open a fixed minimum window size that respects the 16:9 game frame.
- Display a loading screen before the Godot Web runtime is ready.
- Disable browser chrome and devtools in release builds.
- Support fullscreen toggle.
- Support windowed mode.
- Store Electron-specific settings separately from the Godot save file.
- Package the Godot Web export as local app files, not as a remote website.
- Avoid Node integration in the renderer.
- Use a preload script only for safe window/app APIs.

### Electron Technical Spike

Before committing fully, run a short spike:

1. Add a Godot Web export preset.
2. Export the game to `electron/godot-export/web/`.
3. Create a minimal Electron shell that loads the exported `index.html`.
4. Verify:
   - Game boots.
   - Keyboard input works.
   - Audio works.
   - Save/load behavior works or has a clear path.
   - Fullscreen works.
   - No CORS/local file issue blocks the Godot Web runtime.
5. If Godot Web export cannot meet the requirement, document the exact blocker and switch to an Electron shell that launches embedded native Godot binaries per platform. That fallback is less clean, but still satisfies "Electron app" at the launcher level.

## Target Directory Structure

Add the following high-level folders:

```text
Shrugame/
├── electron/
│   ├── package.json
│   ├── package-lock.json
│   ├── electron-builder.yml
│   ├── main.js
│   ├── preload.js
│   ├── renderer/
│   │   ├── index.html
│   │   ├── styles.css
│   │   └── loading.js
│   ├── godot-export/
│   │   └── web/
│   │       └── .gitkeep
│   └── assets/
│       ├── icon.png
│       ├── icon.ico
│       └── icon.icns
├── site/
│   ├── package.json
│   ├── index.html
│   ├── src/
│   │   ├── main.ts
│   │   ├── styles.css
│   │   └── content.ts
│   └── public/
│       ├── screenshots/
│       ├── key-art/
│       └── favicon.png
├── marketing/
│   ├── screenshots/
│   ├── gifs/
│   ├── trailer-notes.md
│   └── press-kit.md
└── release/
    ├── windows/
    ├── mac/
    ├── checksums/
    └── RELEASE_NOTES.md
```

Update `.gitignore` so generated exports and packaged releases stay out of source control unless intentionally attached to GitHub Releases:

```gitignore
electron/godot-export/web/*
!electron/godot-export/web/.gitkeep
electron/dist/
site/dist/
release/windows/
release/mac/
release/checksums/
```

## Difficulty System Plan

### Difficulty Modes

Add two modes:

```text
Shrububu
- Extremely easy.
- Intended for story, jokes, exploration, and birthday-gift playthrough.
- Player should almost never get stuck.

SRMT
- Extremely hard.
- Intended for challenge.
- Requires bullet dodging, item use, weapon use, and learning phase patterns.
```

### Data Model

Add to `GameState`:

```gdscript
var difficulty_id := "shrububu"
```

Add save field in `SaveSystem`:

```json
{
  "difficulty_id": "shrububu"
}
```

Add data file:

```text
data/difficulty/difficulty_modes.json
```

Suggested schema:

```json
{
  "shrububu": {
    "display_name": "Shrububu",
    "description": "Extremely easy. Story-first, generous HP, slow bullets.",
    "player_hp_multiplier": 3.0,
    "enemy_hp_multiplier": 0.45,
    "enemy_damage_multiplier": 0.25,
    "bullet_speed_multiplier": 0.45,
    "bullet_count_multiplier": 0.45,
    "telegraph_multiplier": 1.8,
    "item_drop_multiplier": 2.0,
    "forgive_failed_puzzles": true
  },
  "srmt": {
    "display_name": "SRMT",
    "description": "Extremely hard. Fast bullets, strict resources, brutal bosses.",
    "player_hp_multiplier": 0.75,
    "enemy_hp_multiplier": 1.8,
    "enemy_damage_multiplier": 2.5,
    "bullet_speed_multiplier": 1.8,
    "bullet_count_multiplier": 2.0,
    "telegraph_multiplier": 0.65,
    "item_drop_multiplier": 0.6,
    "forgive_failed_puzzles": false
  }
}
```

### UI Requirements

Add difficulty selection before starting a new game:

- New Game opens a difficulty modal.
- Modal choices:
  - **Shrububu**: "Extremely easy. For story, chaos, and KFC."
  - **SRMT**: "Extremely hard. For suffering under demon law."
- Continue uses saved difficulty.
- Pause menu shows current difficulty.
- Do not allow changing difficulty mid-save unless explicitly implemented as a settings feature later.

### Battle Integration

Modify `BattleManager` and `TuningLoader`:

- Apply difficulty multiplier to player HP.
- Apply difficulty multiplier to enemy HP.
- Apply difficulty multiplier to enemy phase damage.
- Apply difficulty multiplier to bullet count.
- Apply difficulty multiplier to bullet speed.
- Apply difficulty multiplier to telegraph duration.
- Add per-encounter overrides when a boss needs custom tuning.

### Overworld Integration

Shrububu mode:

- More generous interaction range.
- More visible clue hints.
- Optional automatic route reminder after long inactivity.
- Save points more frequent.

SRMT mode:

- Less visible clue assistance.
- Stricter puzzle reset rules.
- More enemy/boss route gates.
- Save points remain fair but less forgiving.

### Difficulty Tests

Add smoke tests:

- `tests/pass30_difficulty_data_smoke.gd`
- `tests/pass31_difficulty_menu_smoke.gd`
- `tests/pass32_difficulty_battle_tuning_smoke.gd`

Test requirements:

- Difficulty data loads.
- New game can set `difficulty_id`.
- Save/load preserves `difficulty_id`.
- Shrububu mode produces higher effective player HP and lower damage.
- SRMT mode produces lower effective player HP and higher damage.
- Existing tests still pass.

## Ending Message Plan

Update `scenes/ending.tscn` and any ending controller if added later.

The ending must include:

```text
Happy Birthday Tingu Verma.
~ Taklu Taklu Chuha.
```

Recommended final ending sequence:

1. SRMT defeated.
2. Throne room goes silent.
3. Dungeon door opens behind throne.
4. Shrububu finds KFC storage.
5. IshiYoga is freed.
6. Shrububu and IshiYoga eat KFC.
7. Ishiville restoration montage.
8. Birthday card appears as a final title card:

```text
Happy Birthday Tingu Verma.
~ Taklu Taklu Chuha.
```

Add test:

```text
tests/pass33_ending_birthday_message_smoke.gd
```

Test requirements:

- Ending scene loads.
- Ending scene contains exact birthday message.
- Message is visible in the scene tree.
- Message survives export.

## Art And Animation Upgrade Plan

### Art Quality Bar

The game should stop relying on colored boxes, route labels, and generic placeholder sprites. Every object on the critical path must communicate what it is through the art itself.

Each final environment must have:

- Painted pixel backplate.
- Tileable ground/wall details.
- Foreground props.
- Animated ambience.
- Clear walkable routes.
- Landmarks visible without text labels.
- NPC silhouettes that read at 320x180.
- Boss silhouettes larger and more expressive than NPCs.
- At least one unique color accent per level.

### Shared Asset Work

Replace or upgrade:

- `assets/shared/sprites/shrububu/form_01/`
- `assets/shared/sprites/shrububu/form_02/`
- `assets/shared/sprites/shrububu/form_03/`
- `assets/shared/sprites/shrububu/form_04/`
- `assets/shared/sprites/shrububu/form_05/`
- `assets/shared/sprites/ui_panel.png`
- `assets/shared/sprites/soul_cursor.png`
- `assets/shared/sprites/common_bullet.png`
- `assets/shared/sprites/cutins/`

Minimum Shrububu animation set per form:

- Idle down/up/side.
- Walk down/up/side.
- Interact.
- Door slam.
- Battle idle.
- Hurt.
- Attack with current weapon.
- Victory.
- Growth transformation.

Boss animation set per boss:

- Intro.
- Idle.
- Talk.
- Attack tell.
- Attack release.
- Hurt.
- Defeat.
- Post-defeat.

NPC animation set:

- Idle.
- Talk.
- Reaction.
- Post-boss variant for important NPCs.

### Level Art Passes

#### Divorcee Harbour

Upgrade:

- Rain depth.
- Broken fake chicken storefront.
- Sheriff office.
- Dock route.
- Divorce papers.
- Harbour residents.
- Satyaki route.
- Building collapse cutscene.

Remove dependency on text labels for:

- Fake chicken door.
- Sheriff office.
- Divorce records.
- Dock route.
- Exit.

#### Banana-burbs

Upgrade:

- Identical banana houses.
- Too-happy monkey loops.
- Smile posters.
- Lab exterior and interior.
- 165-files documents.
- Nitin janitor sprite.
- Mayor office.
- Deepak throne/desk.
- KFC popcorn reveal.

#### Berry Barks

Upgrade:

- Douglas Fir tree silhouettes.
- Red bark berries.
- Mist parallax.
- Berry clusters.
- Chef hut.
- Nishal mini boss sprite.
- Berry sharing town event.
- Ankit approach route.

#### Auticity

Upgrade:

- Pun street signage.
- Hospital exterior/interior.
- Pattern Serum lab props.
- Fireworks reveal.
- Aeon Festival plaza.
- Sushan and Mitta sprites.

#### Area 111

Upgrade:

- Pink cute-town ruins.
- Pub interior.
- Gummies bar.
- Suhas bar fight.
- Bike reward.
- Guitar reward.
- Hooligan streets.
- Fallen mansion puzzles.
- Ruined court.
- SRMT throne.
- KFC dungeon.
- IshiYoga rescue.

### Art Implementation Rules

- Use nearest-neighbor import settings.
- Avoid labels as substitutes for art.
- Keep labels for UI and optional interact prompts only.
- Every visual pass must include screenshot verification.
- Every critical-path scene must be checked at:
  - 1280x720.
  - 1920x1080.
  - Windowed and fullscreen.
- Do not ship generated assets as final unless manually curated and improved.

## Cutscene System Plan

### Required New System

Add:

```text
scripts/cutscenes/cutscene_director.gd
scripts/cutscenes/cutscene_step.gd
data/cutscenes/
scenes/ui/cutscene_letterbox.tscn
```

The cutscene director should support:

- Lock player movement.
- Move actors.
- Show dialogue.
- Play cut-ins.
- Play sound cues.
- Shake screen.
- Fade in/out.
- Wait for timed beats.
- Wait for input.
- Set flags.
- Start battles.
- Change scenes.

### Required Cutscenes

1. Opening arrival in Ishiville.
2. Fake chicken door slam and building collapse.
3. Poojan challenge.
4. Satyaki reveal.
5. Banana-burbs lab discovery.
6. KFC popcorn spell break.
7. Deepak moral twist.
8. Berry Barks false chicken promise.
9. Berry sharing event.
10. Sushan injection failure and fireworks reveal.
11. Aeon Festival transition.
12. Area 111 pub bar fight.
13. Bike/guitar acquisition.
14. SRMT throne reveal.
15. IshiYoga rescue.
16. Final birthday card.

### Cutscene Acceptance Gate

Each cutscene must have:

- Data file.
- Trigger condition.
- Skip behavior or fast-forward behavior.
- No softlock if interrupted.
- Save-safe state after completion.
- Screenshot/gif capture for review.

## Dialogue Expansion Plan

### Current Problem

Dialogue exists, but it is not yet dense enough to carry the intended weird, eerie, funny Pacific Northwest tone.

### Dialogue Goals

Every level should have:

- 5+ minor NPCs.
- 1 mini boss.
- 1 main boss.
- 3+ clue/object interactions.
- Pre-clear dialogue.
- Post-mini-boss dialogue.
- Post-main-boss dialogue.
- Optional weird lines.
- At least one line that points clearly to the next objective.
- At least one line that deepens SRMT's threat.
- At least one line that reinforces Shrububu's KFC obsession.

Shrububu phrases:

- "Unprovoked"
- "Ek Bihari, Sab pe Bhaari"
- "ehehehe"

Use these only where they fit. Do not spam them randomly.

### Dialogue Data Upgrade

Current files:

```text
data/dialogue/level_01_dialogue.json
data/dialogue/level_02_dialogue.json
data/dialogue/level_03_dialogue.json
data/dialogue/level_04_dialogue.json
data/dialogue/level_05_dialogue.json
```

Upgrade schema to support:

```json
{
  "npc_id": {
    "intro": [],
    "after_clue": [],
    "after_mini_boss": [],
    "after_main_boss": [],
    "post_game": [],
    "srmt_mode_extra": [],
    "shrububu_mode_hint": []
  }
}
```

### Dialogue QA

Add script:

```text
tools/audit_dialogue_depth.gd
```

Checks:

- Each level has minimum NPC count.
- Each boss has intro/defeat lines.
- Each clue has readable prose.
- Shrububu catchphrases are present but limited.
- KFC motivation appears in every level.
- SRMT escalation appears in every level.

## Gameplay Expansion Plan

### Overworld

Add:

- Better collision shape authoring.
- Interactable highlights that appear only near objects.
- Optional map/journal screen.
- Improved camera constraints.
- Puzzle reset safety.
- More meaningful item pickups.
- Level-specific mechanics:
  - Level 1: building destruction and paperwork route.
  - Level 2: lab records, spell break, monkey army gate.
  - Level 3: berry collection clusters and potion crafting.
  - Level 4: hospital evidence and festival transition.
  - Level 5: bike traversal, mansion puzzles, court clues.

### Battle

Upgrade battle from functional to expressive:

- Animated boss sprites.
- Player soul/cursor animation.
- Difficulty-aware bullet patterns.
- Better command menu.
- Weapon-specific minigames:
  - Revolver: timed shot.
  - Banana gun: spread placement.
  - Berry potions: potion choice and timing.
  - Musical guitar: rhythm/note timing.
- Boss-specific attack identities:
  - Poojan: badge lanes, warning cones.
  - Satyaki: legal papers, property deeds, rings.
  - Nitin: mop sweeps, wet floor signs, chemical drops.
  - Deepak: smile waves, banana arcs, mayor stamps.
  - Nishal: cooking tools, berry traps, fake chicken tells.
  - Ankit: plate throws, food rage, berry splash.
  - Sushan: syringe patterns, hospital lights, serum arcs.
  - Mitta: festival lights, pageant curtains, rhythm attacks.
  - Suhas: bottles, bar stools, guitar noise.
  - SRMT: callback attacks from all previous levels.

### Boss Design Acceptance

Every major boss must have:

- At least 3 phases.
- At least 3 unique bullet patterns.
- A readable tell before every dangerous attack.
- A Shrububu-mode version that is extremely forgiving.
- An SRMT-mode version that is legitimately hard.
- Intro and defeat cutscenes.
- Reward or story-state change.

## UI/UX Plan

### Main Menu

Add:

- New Game.
- Continue.
- Difficulty selection modal.
- Options.
- Credits.
- Quit.
- Version text.
- Electron build label.

Options:

- Fullscreen/windowed.
- Master volume.
- Music volume.
- SFX volume.
- Screen shake on/off.
- Flash reduction.
- Text speed.
- Control remapping if feasible.

### In-Game UI

Replace temporary overlays with final UI:

- Objective tracker should be optional and minimal.
- Interact prompt should appear only near valid objects.
- Clue journal should open from menu, not cover the screen by default.
- Pause menu should show:
  - Resume.
  - Journal.
  - Items.
  - Difficulty label.
  - Options.
  - Quit to title.

### Accessibility

Add:

- Flash reduction.
- Screen shake toggle.
- Clear font mode if pixel font is too hard to read.
- Shrububu difficulty as accessibility/story mode.

## Audio Plan

### Replace Placeholder Audio

Current audio is useful for structure but should not be considered final.

Final audio targets:

- Level 1: rainy harbour noir.
- Level 2: uncanny suburb jingle.
- Level 3: forest mystery.
- Level 4: hospital/festival synth.
- Level 5: ruined club/court finale.
- SRMT: final boss theme with callbacks.
- Ending: KFC/IshiYoga restoration theme.

### SFX Targets

- Door slam.
- Building break.
- Revolver.
- Banana gun.
- Berry potion.
- Guitar note.
- Clue pickup.
- Save.
- Growth transformation.
- Boss hurt.
- Boss defeat.
- Menu select.
- Cutscene stingers.

### Audio Tests

Add smoke checks:

- Every audio ID in `data/audio/audio_catalog.json` resolves to a file.
- Every weapon has SFX.
- Every level has music.
- Every boss has intro/defeat cues.

## Landing Page Plan

### Recommended Site Stack

Use a small static site with Vite or plain HTML/CSS. Keep it separate from the Electron app.

Directory:

```text
site/
├── package.json
├── index.html
├── src/
│   ├── main.ts
│   ├── styles.css
│   └── content.ts
└── public/
    ├── screenshots/
    ├── key-art/
    └── favicon.png
```

### Landing Page Requirements

First viewport:

- Strong key art.
- Title: **Shrugame**.
- Literal hook: "A cursed Pacific Northwest pixel RPG about Shrububu searching Ishiville for KFC."
- Download buttons:
  - Windows.
  - macOS.
- Trailer/gif area.
- No fake marketing fluff.

Sections:

1. Hero.
2. Screenshots.
3. Story.
4. Features.
5. Difficulty modes.
6. Characters.
7. System requirements.
8. Downloads.
9. Credits.

Feature copy:

- Five strange districts.
- Overworld exploration.
- Turn-based bullet-hell encounters.
- Shrububu growth forms.
- Gear upgrades.
- Clue journal.
- Two difficulty modes.
- Birthday ending.

### Landing Page Art Requirements

Use real screenshots from the finished game, not placeholder mockups.

Minimum media:

- 1 key art image.
- 6 screenshots.
- 3 animated gifs.
- 1 short trailer or trailer plan.

### Landing Page Verification

- Site builds locally.
- Site displays correctly at:
  - 390px mobile width.
  - 768px tablet width.
  - 1280px desktop width.
  - 1920px desktop width.
- No text overlap.
- Download buttons point to actual release files or a clearly marked "coming soon" path before release.

## Electron Build And Release Plan

### Package Tools

Use:

- `electron`
- `electron-builder`
- `npm-run-all` or simple npm scripts

Potential scripts:

```json
{
  "scripts": {
    "dev": "electron .",
    "build:godot:web": "godot --headless --path .. --export-release Web electron/godot-export/web/index.html",
    "build:win": "electron-builder --win",
    "build:mac": "electron-builder --mac",
    "dist": "npm run build:godot:web && electron-builder"
  }
}
```

### Windows Output

Targets:

- `.exe` installer.
- Portable `.exe` if desired.
- `.zip` package.

Expected output:

```text
electron/dist/Shrugame Setup x.y.z.exe
electron/dist/Shrugame-win32-x64/
```

### macOS Output

Targets:

- `.dmg`
- `.zip`

Expected output:

```text
electron/dist/Shrugame-x.y.z.dmg
electron/dist/mac/
```

Notes:

- macOS builds are usually easiest from macOS.
- If building macOS from Windows fails, use GitHub Actions macOS runner.
- Signing/notarization requires Apple Developer credentials.
- If unsigned, document Gatekeeper behavior clearly.

### GitHub Actions Release Workflow

Add:

```text
.github/workflows/release.yml
```

Workflow jobs:

1. Test Godot smoke tests.
2. Export Godot Web build.
3. Build Electron Windows package on Windows runner.
4. Build Electron macOS package on macOS runner.
5. Upload artifacts.
6. Create GitHub Release on version tags.

### Release Versioning

Use a single version source:

- `project.godot` or `export_presets.cfg`
- `electron/package.json`
- `site/src/content.ts`

Avoid mismatched versions. Add a script that checks all version strings.

## Pass-By-Pass Execution Roadmap

### Pass 30: Electron Feasibility Spike

Goal: Prove Godot Web export can run inside Electron.

Tasks:

- Add Web export preset.
- Add `electron/` minimal app.
- Export Godot Web build into Electron.
- Launch Electron locally.
- Verify input/audio/save behavior.

Acceptance:

- Electron window boots the game.
- New Game works.
- Movement works.
- Audio plays.
- No browser security errors block runtime.

Suggested intelligence: High.

### Pass 31: Difficulty Data And GameState

Goal: Add difficulty state without changing encounter balance yet.

Tasks:

- Add `data/difficulty/difficulty_modes.json`.
- Add `difficulty_id` to `GameState`.
- Save/load difficulty.
- Add tests.

Acceptance:

- New difficulty data loads.
- Save/load preserves selected difficulty.

Suggested intelligence: Medium-High.

### Pass 32: Difficulty Selection UI

Goal: Let players choose Shrububu or SRMT before New Game.

Tasks:

- Update `scenes/main.tscn`.
- Update `scripts/core/main_menu.gd`.
- Add difficulty modal.
- Show difficulty descriptions.
- Save selected mode.

Acceptance:

- New Game requires/selects difficulty.
- Continue preserves difficulty.
- No existing start flow breaks.

Suggested intelligence: High.

### Pass 33: Difficulty-Aware Battle Tuning

Goal: Make Shrububu extremely easy and SRMT extremely hard.

Tasks:

- Modify `TuningLoader`.
- Modify `BattleManager`.
- Scale HP, damage, bullet count, bullet speed, telegraph timing.
- Add per-boss override support.
- Add tests.

Acceptance:

- Shrububu mode is clearly forgiving.
- SRMT mode is clearly brutal.
- Bosses remain beatable in both modes.

Suggested intelligence: High.

### Pass 34: Ending Birthday Message

Goal: Add the exact birthday message to the end of the game.

Tasks:

- Update `scenes/ending.tscn`.
- Add final title-card layout.
- Add test for exact text.

Acceptance:

- Ending displays:

```text
Happy Birthday Tingu Verma.
~ Taklu Taklu Chuha.
```

Suggested intelligence: Medium.

### Pass 35: Cutscene Director

Goal: Build reusable cutscene infrastructure.

Tasks:

- Add cutscene director scripts.
- Add data schema.
- Add letterbox UI.
- Add simple test cutscene.

Acceptance:

- Cutscene can lock player, show dialogue, play SFX, set flags, and resume.

Suggested intelligence: High.

### Pass 36: Opening Cutscene Rebuild

Goal: Make the opening door slam/building collapse feel like a real scene.

Tasks:

- Stage Shrububu arrival.
- Animate fake chicken reveal.
- Animate door slam.
- Animate collapse.
- Add NPC reactions.
- Add Poojan setup.

Acceptance:

- The first three minutes communicate premise without debug labels.

Suggested intelligence: High.

### Pass 37: Final UI Style Pass

Goal: Replace temporary UI with finished interface.

Tasks:

- Final pixel font.
- Final dialogue box.
- Final battle HUD.
- Final pause menu.
- Final journal.
- Final settings.

Acceptance:

- No debug-looking overlay remains in normal gameplay.
- UI is legible at 1280x720 and 1920x1080.

Suggested intelligence: High.

### Pass 38: Shrububu Animation Production

Goal: Make Shrububu feel alive.

Tasks:

- Replace all five growth forms with finished sprite sheets.
- Add animation controller.
- Add growth transformation animation.
- Add weapon attack animations.

Acceptance:

- Growth is obvious without text.
- Movement and battle animations feel intentional.

Suggested intelligence: High or Max.

### Pass 39: Level 1 Final Art And Level Design

Goal: Bring Divorcee Harbour to near-final quality.

Tasks:

- Replace remaining placeholders.
- Remove route-label dependence.
- Add parallax/rain layers.
- Improve collision.
- Add NPC homes/interiors if scoped.
- Add final Poojan/Satyaki overworld staging.

Acceptance:

- Level 1 can be shown on the landing page without embarrassment.

Suggested intelligence: High.

### Pass 40: Level 1 Final Dialogue And Cutscenes

Goal: Make Level 1 narratively polished.

Tasks:

- Rewrite all Level 1 NPC dialogue.
- Add post-event variants.
- Add Poojan and Satyaki cutscenes.
- Add optional weird lines.

Acceptance:

- Level 1 reads like a finished comedic mystery intro.

Suggested intelligence: High.

### Pass 41: Level 1 Boss Rebuild

Goal: Make Poojan and Satyaki mechanically memorable.

Tasks:

- Three phases each.
- Unique bullet patterns.
- Difficulty variants.
- Boss tells.
- Final sprites.
- Defeat scenes.

Acceptance:

- Both fights are fun in Shrububu mode and challenging in SRMT mode.

Suggested intelligence: High.

### Pass 42-44: Banana-burbs Finalization

Passes:

- Art/level design.
- Dialogue/cutscenes.
- Boss mechanics.

Acceptance:

- Level 2 has a complete lab mystery, popcorn spell break, monkey army route, and Deepak moral twist.

Suggested intelligence: High.

### Pass 45-47: Berry Barks Finalization

Passes:

- Art/level design.
- Dialogue/cutscenes.
- Berry collection and potion mechanics.
- Nishal/Ankit boss mechanics.

Acceptance:

- The 1000-berry premise is clear and fun without tedious pickup spam.

Suggested intelligence: High.

### Pass 48-50: Auticity Finalization

Passes:

- Art/level design.
- Hospital/festival cutscenes.
- Sushan/Mitta boss mechanics.
- Dialogue polish.

Acceptance:

- The level preserves the requested absurd plot role while implementing the mechanics as fictional control/Pattern Serum systems.

Suggested intelligence: High.

### Pass 51-54: Area 111 Finalization

Passes:

- Pink ruined city art.
- Pub/bar fight cutscene.
- Bike/guitar mechanics.
- Mansion/court puzzles.
- SRMT final boss.
- IshiYoga rescue.
- Birthday ending.

Acceptance:

- Level 5 feels like a finale, not a placeholder route.

Suggested intelligence: High or Max.

### Pass 55: Full Dialogue Rewrite

Goal: Make the five-level story coherent.

Tasks:

- Review all dialogue files.
- Expand NPC states.
- Add optional lines.
- Add clue prose.
- Add item flavor text.
- Verify catchphrases are used sparingly.

Acceptance:

- Every district has a strong voice.
- Shrububu remains funny and consistent.
- SRMT threat escalates.

Suggested intelligence: High.

### Pass 56: Audio Replacement

Goal: Replace placeholder audio with intentional audio.

Tasks:

- Final music loops.
- Final SFX.
- Boss stingers.
- Cutscene cues.
- Volume mixing.

Acceptance:

- No critical scene is silent or placeholder-sounding.

Suggested intelligence: Medium-High.

### Pass 57: Landing Page Build

Goal: Create the public-facing game page.

Tasks:

- Add `site/`.
- Build responsive landing page.
- Add screenshots/gifs.
- Add download section.
- Add story/features/difficulty sections.

Acceptance:

- Landing page runs locally.
- Responsive screenshots pass.
- Copy reflects actual current game.

Suggested intelligence: High.

### Pass 58: Electron Packaging

Goal: Build Electron packages for Windows and macOS.

Tasks:

- Finalize `electron-builder`.
- Build Windows app.
- Build macOS app.
- Add icons.
- Add app metadata.
- Verify install/launch.

Acceptance:

- Windows package launches.
- macOS package launches.
- Version metadata is correct.

Suggested intelligence: High.

### Pass 59: Release Automation

Goal: Automate builds.

Tasks:

- Add GitHub Actions.
- Run Godot smoke tests.
- Build Electron packages.
- Upload artifacts.
- Create release draft.

Acceptance:

- A version tag produces Windows and macOS artifacts.

Suggested intelligence: High.

### Pass 60: Full Playthrough QA

Goal: Verify the game end-to-end.

Tasks:

- Full Shrububu mode playthrough.
- Full SRMT mode playthrough.
- Save/load at every level.
- Boss retries.
- Puzzle resets.
- Ending message.
- Electron app launch.
- Landing page link verification.

Acceptance:

- Game can be completed on both difficulties.
- Ending birthday message appears.
- No editor-only steps.

Suggested intelligence: High.

## Testing Strategy

### Automated Tests

Continue the current smoke-test pattern in `tests/`.

Add tests for:

- Electron scaffold files.
- Web export preset.
- Difficulty data.
- Difficulty save/load.
- Difficulty battle tuning.
- Ending birthday message.
- Landing page content.
- Release metadata.
- Required assets per level.

### Manual Tests

Manual checks are required for:

- Visual clarity.
- Animation quality.
- Dialogue timing.
- Cutscene pacing.
- Boss difficulty.
- Landing page responsiveness.
- Electron launch.
- macOS package launch.

### Visual QA

Every visual pass must capture screenshots into a temporary ignored folder:

```text
builds/qa/screenshots/
```

Do not commit these unless they are selected for marketing.

Required views:

- Title screen.
- Each level start.
- Each boss intro.
- Each battle.
- Ending birthday message.
- Electron loading screen.
- Landing page desktop/mobile.

## Definition Of Done For The Full Project

The project is not done until all of the following are true:

- Electron app runs locally.
- Windows Electron build is produced.
- macOS Electron build is produced.
- Landing page exists and builds.
- Shrububu difficulty works and is extremely easy.
- SRMT difficulty works and is extremely hard.
- Full game can be completed in Shrububu mode.
- Full game can be completed in SRMT mode.
- Ending shows:

```text
Happy Birthday Tingu Verma.
~ Taklu Taklu Chuha.
```

- Every level has final or near-final art.
- Every boss has final or near-final animations.
- Every major story beat has a cutscene or staged interaction.
- Dialogue has been rewritten and expanded.
- Placeholder/debug labels are not visible in normal play.
- Generated assets have been replaced or manually curated.
- Audio is intentional.
- Save/load works.
- Release artifacts are versioned.
- README reflects the real release state.
- Tests pass.
- Manual playthrough checklist is complete.

## Immediate Next Pass Recommendation

Start with **Pass 30: Electron Feasibility Spike**.

Reason:

- The user explicitly wants the game to become an Electron app.
- The current project has no web export, no Electron shell, and no package metadata.
- Proving the Electron runtime early prevents wasting weeks polishing a build path that may need architecture changes.

Suggested intelligence level: **High**.

After Pass 30 is accepted, proceed to the difficulty system before more art passes, because difficulty affects battle tuning, UI, save data, landing-page feature copy, and release QA.
