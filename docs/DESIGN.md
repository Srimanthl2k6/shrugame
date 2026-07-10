# Shrugame Design Notes

## One-Page Creative Spine

**Shrugame** is a 5-level 2D pixel RPG about **Shrububu**, a woman searching the cursed town of **Ishiville** for KFC. Ishiville is ruled by the demon king **SRMT**, who has locked each district into a strange local crisis. The town residents quickly realize Shrububu is absurdly strong after she enters a fake chicken building, discovers it is not KFC, slams the door in disappointment, and breaks the whole building.

The townspeople decide she is their best chance at freedom. They guide her through clues, gear upgrades, strange NPC interactions, mini bosses, main bosses, and finally toward SRMT. After beating SRMT, Shrububu frees **IshiYoga**, the former queen of Ishiville, from the dungeon behind his throne. The ending image is Shrububu and IshiYoga eating KFC together and ruling Ishiville.

The core loop remains overworld exploration, NPC interaction, clue gathering, gear upgrade, turn-based encounter, bullet-dodging enemy phase, boss resolution, growth unlock, and transition to the next area.

## Main Character

**Shrububu**

- Role: Player character and accidental liberator of Ishiville.
- Naming rule: **Shrububu** is the canonical display name. **Shruti** may appear as a nickname, mistaken NPC name, or late-story affectionate name.
- Motivation: Find KFC at any cost.
- Personality: Impatient, blunt, extremely strong, weirdly charismatic, often disappointed by non-KFC food.
- Growth rule: Shrububu grows after every level. Growth must be visible in sprite size, silhouette, NPC reactions, battle pose, and later environmental interactions.
- Starting state: Normal height, no gear, overwhelming physical strength but no battle tools.
- Final state: Biker/guitar final form, strong enough to face SRMT in the ruined court.

## Story Progression

| Level | Area | Intro Event | Mini Boss | Main Boss | Reward/Gear | Clue Gained | Growth Form | Town State After Defeat |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Divorcee Harbour | Shrububu enters Ishiville looking for KFC, slams a fake chicken building door, and breaks the building. | Sheriff Poojan | Satyaki Tirumal | Poojan's revolver | Divorce records and Satyaki abuse clues | Form 2: revolver carrier | Harbour residents realize Shrububu can free Ishiville. |
| 2 | Banana-burbs | Shrububu finds a too-happy monkey suburb and an abandoned lab. | Nitin the Janitor | Deepak Reddy | banana gun | 165-files proving the joy spell | Form 3: banana gun and berry satchel setup | Monkeys regain agency and reveal SRMT's wider threat. |
| 3 | Berry Barks | Shrububu is promised fried chicken for collecting bark berries. | Niggesh Nishal | Ankit | berry potions | Berry contract and food-supply clues | Form 4: oversized mythic town breaker | Residents receive shared berries and stop depending on one selfish supplier. |
| 4 | Auticity | Shrububu reaches a pun-heavy town and discovers hospital injections controlling residents. | Doctor Sushan | Mitta | festival clearance and final-route clue | Hospital records and Aeon festival clue | Form 5 setup: near-final giant form | The city regains self-direction after the Aeon festival conflict. |
| 5 | Area 111 | Shrububu enters ruined pink cute-town nightlife, finds Gummies instead of chicken, and starts a bar fight. | Suhas | SRMT | bike and musical guitar | Mansion/court clues leading to IshiYoga | Form 5: biker guitar final form | SRMT is defeated, IshiYoga is freed, and Ishiville is restored. |

## Level 1: Divorcee Harbour

- Setting: Rainy harbour district, divorce paperwork in the wind, motel lights, docks, broken fake chicken storefront, sheriff office, damp homes, paper-cluttered streets.
- Plot: Shrububu enters Ishiville looking for KFC. She finds a building that appears promising, learns it is not KFC, slams the door in disappointment, and destroys it. The residents witness this and understand she has impossible strength.
- NPC function: Harbour residents point Shrububu toward Sheriff Poojan and then Satyaki Tirumal. Their clues establish Satyaki as her ex-husband and the local abuser who has been torturing the district's women because of his anger over the divorce.
- Mini boss: **Sheriff Poojan** tests Shrububu's strength and gives her his revolver after losing.
- Main boss: **Satyaki Tirumal** uses divorce papers, property deeds, money, broken rings, and revenge dialogue.
- Clear condition: Defeat Satyaki, earn Form 2, keep the revolver, and open the route to Banana-burbs.

## Level 2: Banana-burbs

- Setting: Perfect yellow suburb, identical houses, smiling monkey residents, cheerful loops, strange civic posters, abandoned lab on the outskirts, mayor office.
- Plot: Shrububu's search for KFC continues. The monkeys are too happy and too satisfied. In the lab, Shrububu finds the **165-files**, secret records proving Mayor **Deepak Reddy** has the monkeys under a spell that keeps them happy.
- Mini boss: **Nitin the Janitor** blocks the lab exit to keep the 165-files hidden.
- Town break event: Shrububu shares her backup KFC popcorn box. The monkeys experience a stronger joy than the spell and begin listening to her.
- Reward: The monkey army gives Shrububu the **banana gun**.
- Main boss: **Deepak Reddy**, monkey king mayor, fights from the mayor's office.
- Twist: Deepak says the outside world under SRMT is cruel to the monkeys and that forced happiness was his way of keeping them safe.
- Clear condition: Defeat Deepak, gain Form 3, save the banana gun, and open the route to Berry Barks.

## Level 3: Berry Barks

- Setting: Pacific Northwest fir forest, Douglas Fir trees with red bark berries, mist, cabins, berry vats, trail signs, wet roots, hidden chef hut.
- Plot: Shrububu keeps searching for KFC. **Niggesh Nishal** promises fried chicken if she gathers 1000 bark berries. The level should frame this as a large order but implement it through clusters and counters, not 1000 individual pickups.
- Mini boss: Niggesh Nishal admits there is no chicken and fights after the lie is exposed.
- Town event: Shrububu shares the berries with residents and creates **berry potions**.
- Main boss: **Ankit** attacks because Niggesh Nishal was his chef and now Ankit has nothing to eat.
- Boss tools: Plate throws, food rage, berry splash patterns, chef tools, potion counterplay.
- Clear condition: Defeat Ankit with berry potions, gain Form 4, save berry potions, and open the route to Auticity.

## Level 4: Auticity

- Setting: Pun-heavy streets, rigid civic signage, hospital corridors, injection lab, fireworks setup, Aeon Festival plaza.
- Plot: Shrububu keeps searching for KFC. Residents speak in strange looping puns and ritualized lines. She reaches the hospital after getting hurt and discovers **Doctor Sushan** injecting residents with a fictional control substance that keeps them dependent on his treatment.
- Mechanic framing: Use a fictional **Pattern Serum** / Autinjection-equivalent as the game mechanic. Do not frame real-world autism as a disease, cure state, or failure state in implementable text. The plot role is forced dependency, medical exploitation, and absurd town control.
- Mini boss: Doctor Sushan injects Shrububu, but it fails because Shrububu's internal chaos is already stronger than the serum. Fireworks reveal her immunity.
- Festival event: Residents begin regaining self-direction and celebrate at **Aeon**.
- Main boss: **Mitta** attacks because of his relationship with Sushan and his grief/rage over the broken scheme. The fight is theatrical, festival-like, and spectacle-heavy.
- Clear condition: Defeat Mitta, free Auticity, unlock final growth setup, and open the route to Area 111.

## Level 5: Area 111

- Setting: Ruins of a pink cute-town, clubs, pubs, neon alleys, hooligan streets, fallen mansion, ruined court, SRMT throne room, KFC dungeon.
- Plot: Shrububu is almost ready to give up on finding KFC. She enters a pub asking for chicken, but they only serve **Gummies**. A drunk named **Suhas** starts a bar fight.
- Mini boss: Suhas. After winning, Shrububu steals his bike and takes his **musical guitar**, which shoots musical notes.
- Level structure: Bike traversal through hooligan streets, fallen mansion puzzles, ruined court approach, SRMT throne room.
- Final boss: **SRMT** sits on the throne eating KFC. The fight is over the KFC bucket and control of Ishiville. SRMT should use callback attacks from previous levels.
- Ending: Shrububu defeats SRMT with the guitar, finds the KFC storage dungeon, frees **IshiYoga**, eats KFC with her, and they rule Ishiville together.
- Clear condition: Defeat SRMT, free IshiYoga, and show the restored-rule ending.

## Gear And Clue Spine

- Revolver: Earned from Poojan. First real weapon. Used for precise shots and intimidation checks.
- Banana gun: Earned from the monkey army. Used for spread shots, curved projectiles, and some switch puzzles.
- Berry potions: Made after Level 3. Used for healing, buffs, and berry-based boss counterplay.
- Musical guitar: Taken after Suhas. Shoots musical notes and is required for SRMT.
- 165-files: Level 2 clue set proving the monkey spell.
- Divorce records: Level 1 clue set exposing Satyaki's motives and control.
- Berry contract: Level 3 clue set exposing the fake chicken promise.
- Hospital records: Level 4 clue set exposing Sushan's treatment scheme.
- Mansion/court clues: Level 5 clue set leading to SRMT and IshiYoga.

## Tone Rules

- The tone is **Pacific Northwest mystery**: wet streets, cold forests, municipal weirdness, neon windows, fog, fir trees, diners, motels, documents, suspicious locals, and supernatural bureaucracy.
- Reference feel: **Twin Peaks** eeriness and **Gravity Falls** absurd mystery energy.
- The writing target is **rainy, strange, funny, unsettling**.
- NPC dialogue should be short, weird, and useful. Every optional line should either reveal character, deliver a joke, give a clue, or make the town feel stranger.
- Keep KFC present as Shrububu's constant motivation, but let each level reveal a more serious local problem under the joke.
- SRMT should feel distant at first, then increasingly present through documents, bosses, town rules, and final callback attacks.

## Art Pillars

- Use **chunky expressive pixel sprites** with readable silhouettes and exaggerated reactions.
- Environmental motifs: **rain, neon, mist, paper clutter, cursed signage**.
- Each level must have a clear **palette and animation motif**:
  - Divorcee Harbour: rain, teal-gray docks, red motel glow, paper flutter.
  - Banana-burbs: bright yellows, identical lawns, smile posters, synchronized monkey idles.
  - Berry Barks: dark greens, red berry glow, drifting mist, swaying fir branches.
  - Auticity: hospital whites, festival colors, looping signage, fireworks bursts.
  - Area 111: pink ruins, nightclub neon, gummy signage, static, musical note effects.
- Shrububu's growth must be the most important recurring visual feature.
- Bosses should have larger, more animated sprites than normal NPCs.
- Major scene beats need cut-in animation targets: door slam, weapon unlocks, boss intros, growth transformations, SRMT throne reveal, IshiYoga rescue.

## Gameplay And Production Constraints

- Build one pass at a time and stop after each pass for review.
- Keep five levels total.
- Keep single-player and one save file.
- Keep Godot 4.x, GDScript, Windows-first export.
- Keep data editable in JSON.
- Prioritize art, animation, level design, and story over complex RPG stat systems.
- Keep the overworld plus turn-based bullet-hell encounter structure.
- Each level needs one mini boss, one main boss, at least five minor NPCs, at least three clue/object interactions, and post-clear dialogue changes.

## Open Production Questions For Later Passes

- Exact final title treatment.
- Final pixel font and UI frame style.
- Whether aggressive alternate outcomes are added after the main route works.
- How much of each boss fight gets unique animation versus shared framework effects.
