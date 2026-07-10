# Shrugame

A small 5-level 2D pixel RPG built with Godot 4.7 and GDScript.

Current status: **Pass 29 presentation scale repair**, built on the **Pass 15 release candidate**, Pass 16 readability work, Pass 17 Level 1 art replacement, Pass 18 QA polish, Pass 19 interaction/battle readability, Pass 20 boss visual replacement, Pass 21 pattern readability, Pass 22 Level 1 visual clarity, Pass 23 Level 2 visual clarity, Pass 24 Level 3 visual clarity, Pass 25 Level 4 visual clarity, Pass 26 Level 5 visual clarity, Pass 27 full-route QA, and Pass 28 Level 2 art cleanup. The project has five playable levels, expanded Ishiville story/dialogue data, turn-based bullet encounters, one local save file, generated placeholder pixel art/audio, feedback effects, a clearer PC title/menu presentation, compact runtime map labels/boundaries, authored PlayableFrame visible/collidable boundaries on every level, a Banana-burbs painted backplate and happy monkey sprites for Level 2, an ending scene, and a Windows export at `builds/windows/Shrugame.exe`.

## Stack

- Engine: Godot 4.7
- Language: GDScript
- Primary target: Windows downloadable build
- Data format: JSON for editable dialogue, encounter, item, character, and level configuration data

## Current Pass Status

- Pass 1-15 roadmap passes are implemented for the current release-candidate baseline.
- Pass 16 adds PC-sized launch settings, clearer menu structure, visible level boundaries, map labels, and a readable HUD/legend so the prototype is no longer just unlabeled colored blocks.
- Pass 17 Level 1 art replacement gives Divorcee Harbour a painted backplate, fake chicken storefront, sheriff office, dock route, readable NPC/boss sprites, rain overlay, and sprite replacements for the most visible polygon stand-ins.
- Pass 18 Level 1 QA polish adds camera limits, physical collision blockers for major Divorcee Harbour scenery, route guides, and a persistent E/Enter interaction prompt.
- Pass 19 interaction and battle readability adds named focus prompts for Level 1 objects, a battle nameplate, clearer battle status labels, and command hints for Act, Item, Gear, and Guard.
- Pass 20 Level 1 boss battle visual replacement adds a Divorcee Harbour battle backdrop, Poojan battle sprite, Satyaki battle sprite, and thematic bullet visuals for badges, legal papers, and broken rings.
- Pass 21 Level 1 boss pattern readability adds telegraph timing, safe-lane hints, slower Level 1 pacing, and battle labels that explain the active boss pattern before bullets spawn.
- Pass 22 Level 1 full playthrough visual clarity adds an authored clarity layer, stronger landmark labels, a visible critical-path route, and a PC overlay route strip for Divorcee Harbour.
- Pass 23 Level 2 Banana-burbs visual clarity adds a Banana-burbs authored clarity layer, the 165-files Lab label, suburb/lab/mayor route panels, and a visible Deepak route to the mayor office.
- Pass 24 Level 3 Berry Barks visual clarity adds a Berry Barks authored clarity layer, 1000 Berries and Berry Contract labels, route panels for Nishal/share/Ankit, and a visible Ankit route toward Auticity.
- Pass 25 Level 4 Auticity visual clarity adds an Auticity authored clarity layer, Hospital Records and Doctor Sushan labels, route panels for puns/hospital/festival/Mitta, and a visible Mitta route toward Area 111.
- Pass 26 Level 5 Area 111 visual clarity adds an Area 111 authored clarity layer, Gummies Pub and Fallen Mansion labels, route panels for Suhas/bike/guitar/SRMT, a visible SRMT route, and an IshiYoga rescue route toward the ending.
- Pass 27 full-route visual QA adds an authored PlayableFrame to all five levels, giving each route visible/collidable boundaries, corner markers, and shared edge collision for PC-scale readability.
- Pass 28 Level 2 art cleanup adds a Banana-burbs painted backplate, happy monkey sprites, 165-files lab art, mayor office art, readable Nitin/Deepak overworld sprites, and sprite replacements for the old Level 2 colored polygon stand-ins.
- Pass 29 presentation scale repair shrinks the runtime PC overlay, route strip, prompt, legend, objective tracker, generated markers, and world labels so labels no longer cover the playfield at 1280x720.
- Pass 10 remains the playable prototype integration milestone in the project history.
- Run the project from Godot with `scenes/main.tscn`.
- Windows export is prepared through the `Windows Desktop` preset at `builds/windows/Shrugame.exe`.
- Current verification target: all smoke tests in `tests/` pass before export.
- Remaining production work is mostly manual playtesting, final art/audio replacement, and external release packaging polish.

## Folder Guide

- `assets/`: Sprites, tilesets, audio, and fonts, split into shared assets and per-level assets.
- `scenes/`: Main/title flow, UI, overworld, battle, ending, and five level scenes.
- `scripts/`: Core systems for player control, dialogue, battle, saving, audio, tuning, input, and level flow.
- `data/`: JSON data for dialogue, encounters, items, characters, levels, and gameplay tuning.
- `docs/DESIGN.md`: Story, character, level, and mechanic notes.
