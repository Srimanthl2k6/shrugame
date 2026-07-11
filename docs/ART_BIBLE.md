# Shrugame Art Bible

## Core Pixel Specs

- Base resolution: 640x360.
- Default desktop presentation: 1280x720 at 2x integer scale.
- Supported presentation: 960x540 minimum window through 1920x1080 fullscreen.
- Tile size: 16x16.
- Battle arena: 384x152 within the 640x360 battle composition.
- Camera target: one 640x360 room at a time with gentle follow and hard room limits.
- Texture filtering: nearest-neighbor only.
- Outline rule: 1 pixel dark outline on characters, bosses, gear, and important interactables.
- Readability rule: every interactable must read at 1x scale by silhouette, color contrast, or motion.

## UI style

- UI panels use dark ink backgrounds with warm off-white borders.
- Dialogue text uses a high-contrast pixel font direction with short line lengths.
- Button prompts use compact icon-plus-text labels.
- Health, gear, clue, and objective UI must stay small and functional; do not cover the battle arena.
- Level title cards use a black panel, one accent color from the level palette, and a 1-frame flicker before settling.

## Battle portrait/cut-in style

- The battle portrait/cut-in style is a high-contrast bust or silhouette frame shown before major bosses and growth changes.
- Cut-ins use a 640x160 safe composition so they can cross the 640x360 screen without hiding the HUD for long.
- Major boss cut-ins should use 6 frames: anticipation, smear, hold, shake, flash, settle.
- Shrububu growth cut-ins should use 8 frames: crouch, stretch, pop, shake, outfit/gear snap, stare, flash, settle.
- SRMT throne reveal uses 8 frames plus a screen tint, but the actual animation can be built later from still layers.

## Sprite Scale Rules

### Shrububu identity reference

- Canonical concept: `assets/shared/concept/shrububu_forms_reference.png`.
- The two private childhood photos inform only her playful eyes, side-glance, and mischievous expression. Shrububu remains an adult woman in every playable form.
- The adult photos are the primary identity reference: medium-brown skin, large expressive dark eyes, long black hair with bangs or soft waves, optional clear-frame glasses, and a tall, slim silhouette.
- Growth is shown through height, posture, confidence, equipment, coat length, and animation force. Her body does not widen as she grows.
- Never portray Shrububu as fat, bulky, broad-bodied, inflated, childlike, or as a body-size joke.
- Raw photo references are production-only and must never be packaged into the game, site, or release artifacts.

### Shrububu Growth Forms

| Form | Story State | Overworld Sprite | Battle Sprite | Notes |
| --- | --- | --- | --- | --- |
| Form 1: KFC seeker | Arrives in Ishiville with no gear. | 48x64 | 52x72 | Teal raincoat, impatient side-eye, unbranded fried-chicken bucket. |
| Form 2: revolver carrier | After Poojan gives the revolver. | 50x68 | 54x76 | Slightly taller, maroon rain duster, clear-frame glasses, revolver holster. |
| Form 3: banana gun + berry satchel | After Banana-burbs. | 52x72 | 56x80 | Taller field silhouette, banana gun and berry satchel. |
| Form 4: mythic town breaker | After Berry Barks. | 54x76 | 58x84 | Taller long-coat silhouette, stronger stance and potion gear; no added body width. |
| Form 5: biker guitar final form | Area 111 finale. | 58x80 | 62x88 | Tallest form, cropped biker jacket, fitted trousers, guitar and musical-note effects. |

### NPC sprite size classes

- Small NPC: 28x36 for monkeys and deliberately tiny weird residents.
- Standard NPC: 34x48 for most town residents.
- Tall NPC: 40x56 for sheriffs, doctors, and festival hosts.
- Feature NPC: up to 48x64 for narratively important silhouettes.
- Important NPCs get one extra color accent and at least a 2-frame idle.

### boss sprite sizes

- Mini boss overworld sprite: 40x56 minimum.
- Mini boss battle sprite: 64x74 minimum.
- Main boss overworld sprite: 44x62 minimum.
- Main boss battle sprite: 80x92 minimum.
- SRMT battle sprite: 112x128 minimum, centered above the arena.
- Boss silhouettes must be readable in grayscale before coloring.

## Level Art Specifications

| Level | Area | Palette | Tileset target | Animation motif | NPC direction | Boss direction |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Divorcee Harbour | #0E1B24, #355060, #7B2E3A, #D8C7A3, #F0E7D0 | Wet dock boards, motel walls, fake chicken storefront, sheriff office, paper-covered streets. | Rain streaks, neon motel flicker, paper flutter, door slam debris. | Raincoats, house robes, paperwork accessories, tired expressions. | Poojan uses sheriff browns and metal glints; Satyaki uses suit shapes, paper swarms, ring/deed motifs. |
| 2 | Banana-burbs | #1E2A18, #F0C53A, #7FB069, #FFFFFF, #2F5D50 | Identical lawns, yellow houses, lab tiles, mayor office, suburb roads. | Synchronized monkey idle loops, smile-poster blink, lab monitor pulse. | Monkeys look too cheerful until freed; use repeated poses to show spell monotony. | Nitin uses janitor greens and hazard stripes; Deepak uses mayor sash, crown, banana-gold spell effects. |
| 3 | Berry Barks | #07140E, #1F4A2F, #8B1E3F, #D63A5C, #A7C8A0 | Fir trunks, bark berry clusters, mist paths, cabins, vats, chef hut. | Mist drift, berry glow, fir branch sway, potion bubble. | Forest residents wear bark/berry accessories and look hungry but suspicious. | Niggesh Nishal uses chef whites and berry stains; Ankit uses food-rage shapes, plates, and heavy stomps. |
| 4 | Auticity | #15161C, #E8E8DD, #4DA3FF, #FFCF40, #E55C8A | Punned street signs, hospital rooms, injection lab, Aeon Festival plaza. | Sign blink loops, fluorescent buzz, fireworks bursts, festival light chases. | Residents use stiff loops, pun sign props, festival masks, and odd pauses. | Doctor Sushan uses sterile whites and serum greens; Mitta uses festival color, theatrical capes, and spotlight poses. |
| 5 | Area 111 | #120D18, #FF78B7, #49E6FF, #F7D44A, #202030 | Pink cute-town ruins, clubs, pubs, bike streets, fallen mansion, ruined court, KFC dungeon. | Club strobes, static bands, gummy sign wobble, musical note trails. | Hooligans use neon outlines, gummy props, and nightclub silhouettes. | Suhas uses bar-fight smear frames; SRMT uses throne silhouette, KFC bucket glow, demon shadow callbacks. |

## Animation Requirements

### Shrububu base animations

| Animation | Frame Count | Applies To | Notes |
| --- | --- | --- | --- |
| overworld idle | 2 frames | All forms | Subtle breathing or impatient foot tap. |
| overworld walk | 4 frames per direction | All forms | Keep feet readable at 1x. Larger forms need heavier steps. |
| door slam | 6 frames | Form 1 first cutscene, reusable later | Hand reach, impact, squash, debris, hold, recover. |
| interact | 2 frames | All forms | Small lean or hand movement. |
| battle idle | 4 frames | All forms | Strong stance with gear visible. |
| hurt | 2 frames | All forms | Flash-compatible pose, no large movement. |
| attack per weapon | 6 frames | Forms 2-5 | Windup, aim, fire/swing, recoil, settle, idle return. |
| victory | 4 frames | All forms | Short enough to reuse after bosses. |

### Boss animation requirements

| Animation | Frame Count | Notes |
| --- | --- | --- |
| boss intro | 6 frames | Required for Poojan, Satyaki, Nitin, Deepak, Niggesh Nishal, Ankit, Doctor Sushan, Mitta, Suhas, SRMT. |
| boss idle | 4 frames | All mini bosses and main bosses. |
| boss attack windup | 4 frames | Should telegraph bullet pattern type. |
| boss attack loop | 4 frames | Can loop during bullet phase. |
| boss hurt | 2 frames | Use flash and small recoil. |
| boss defeat | 6 frames | Collapse, vanish, or emotional break depending on boss. |

### Environmental animation requirements

- Rain: 4 frames, diagonal loop, used in Divorcee Harbour.
- Neon flicker: 4 frames, non-random loop, used in Divorcee Harbour and Area 111.
- Monkey loop: 2 frames, intentionally synchronized before the spell break.
- Berry glow: 4 frames, pulsing red light.
- Hospital fluorescent buzz: 2 frames.
- Aeon fireworks: 8 frames for small bursts.
- Club strobe/static: 4 frames, low opacity so it does not obscure gameplay.
- Musical notes: 6 frames, used for guitar attacks and Area 111 effects.

## Asset Naming Rules

### Shared Shrububu sprites

- assets/shared/sprites/shrububu/form_01/
- assets/shared/sprites/shrububu/form_02/
- assets/shared/sprites/shrububu/form_03/
- assets/shared/sprites/shrububu/form_04/
- assets/shared/sprites/shrububu/form_05/

Inside each form folder:

- idle_down.png
- walk_down.png
- walk_up.png
- walk_left.png
- walk_right.png
- battle_idle.png
- hurt.png
- victory.png
- attack_<weapon_id>.png

### Level-specific assets

- assets/level_01/sprites/
- assets/level_01/tilesets/
- assets/level_01/audio/
- assets/level_02/sprites/
- assets/level_02/tilesets/
- assets/level_02/audio/
- assets/level_03/sprites/
- assets/level_03/tilesets/
- assets/level_03/audio/
- assets/level_04/sprites/
- assets/level_04/tilesets/
- assets/level_04/audio/
- assets/level_05/sprites/
- assets/level_05/tilesets/
- assets/level_05/audio/

Level sprite filenames:

- npc_<character_id>_idle.png
- npc_<character_id>_talk.png
- boss_<boss_id>_intro.png
- boss_<boss_id>_idle.png
- boss_<boss_id>_attack.png
- boss_<boss_id>_hurt.png
- boss_<boss_id>_defeat.png
- prop_<object_id>.png
- fx_<effect_id>.png

Tileset filenames:

- tiles_<area_id>_ground.png
- tiles_<area_id>_walls.png
- tiles_<area_id>_props.png
- tiles_<area_id>_animated.png

## Production Priority

1. Finalize Shrububu Form 1 and Form 2 first because Level 1 depends on both.
2. Produce Divorcee Harbour tiles and door-slam cutscene before drawing optional NPCs.
3. Create boss silhouettes before color work.
4. For each level, finish critical-path art before decorative props.
5. Reuse shared UI frames and effect conventions instead of inventing a new visual language per level.
6. Keep all source art grid-aligned to 16x16 tiles and exported PNG sheets.

## Implementation Notes For Later Passes

- Do not resize the battle arena without updating gameplay tuning.
- Do not use anti-aliased scaled sprites.
- Shrububu collision footprints grow only slightly from 12x18 to 16x24 and remain centered on her feet. Growth must never make required routes inaccessible.
- Boss sheets should be authored as horizontal frame strips unless a later importer requires another format.
- All animation counts in this document are minimums, not maximums.
