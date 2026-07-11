# Shrububu Character Bible

## Canonical Visual Anchor

The production concept at `assets/shared/concept/shrububu_forms_reference.png` is the canonical reference for all in-game sprites, portraits, cut-ins, marketing art, and animation. It was developed from the private photo folders in the project root. The raw photos are reference-only and are excluded from source control and release packaging.

Shrububu is an adult Indian woman with medium-brown skin, large expressive dark eyes, long black hair, and a dry, suspicious side-glance. Her hair may use straight bangs, loose waves, or clear-frame glasses when the outfit supports them. These details should carry recognition at small pixel scale.

## Non-Negotiable Silhouette Rule

Shrububu remains slim and naturally proportioned in every form. Her growth is never represented by added body width, obesity, bulky limbs, exaggerated shoulders, or a body-size gag.

Growth reads through:

- Increasing height.
- More upright and confident posture.
- Longer, more dramatic outerwear.
- Stronger anticipation, recoil, and impact frames.
- Increasingly recognizable equipment.
- NPC staging and environmental scale reactions.

Her gameplay collision footprint remains consistent across forms so visual growth does not make later levels harder to navigate.

## Five Forms

| Form | Visual identity | Key read at 1x |
| --- | --- | --- |
| 1: KFC seeker | Teal raincoat, fitted dark clothes, lace-up boots, long wavy hair, impatient side-eye. | Small fried-chicken bucket and teal coat. |
| 2: Revolver carrier | Taller maroon rain duster, clear-frame glasses, practical holster. | Maroon coat, glasses glint, revolver. |
| 3: Banana gun adventurer | Teal field jacket, pale inner shirt, berry satchel. | Banana-shaped gun and purple satchel. |
| 4: Mythic town breaker | Taller forest coat, potion belt, controlled powerful stance. | Long dark-green coat and glowing potion. |
| 5: Biker guitar final form | Cropped black biker jacket, teal top, fitted dark trousers, boots. | Electric guitar and cyan note effects. |

## Face And Animation

- Preserve large eyes and an asymmetrical side-eye whenever the camera can show them.
- Idle animation should feel observant and impatient, not vacant.
- Walk cycles stay light and deliberate. Later forms gain impact through timing and coat movement, not wider limbs.
- Victory poses can use a small smirk or upward glance inspired by the childhood references.
- `ehehehe` moments use a restrained grin and a half-lidded look; do not turn them into a generic manic expression.

## Release Privacy

- Keep a `.gdignore` marker in both raw photo folders so Godot never imports them.
- Never copy raw photos into `electron/`, `site/`, `builds/`, release zips, screenshots, or promotional media.
- Only derived, stylized artwork may leave the development workspace.
