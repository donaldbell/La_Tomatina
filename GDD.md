# TOMATINA — Game Design Document
*A PICO-8 survival game set at Spain's La Tomatina festival*

---

## Concept

A single-player survival arcade game. The player navigates the tomato-soaked streets of Buñol, Spain during the annual La Tomatina festival — dodging hurled tomatoes, slipping on puddles, scavenging for ammo and items, and surviving as long as possible in glorious, slapstick chaos.

**Tone:** Comedic, chaotic, adult fun. Think: young adults letting loose. Pratfalls, splats, absurd pickups, expressive animations. Not childish — more like a great party that got completely out of hand.

**Primary references:** Metal Slug, TMNT Arcade, The Simpsons Arcade

---

## Perspective & Camera

- **Side-scrolling** with a beat-em-up ground plane
- Player moves left/right AND up/down within a defined ground band (roughly the bottom half of the screen)
- Lower Y position = closer to camera (drawn on top, slightly larger)
- Camera scrolls horizontally, revealing new scenery, enemies, and items
- Depth sorting: all characters and items drawn in Y order

---

## Core Loop

1. Survive as long as possible
2. Dodge incoming tomatoes from the crowd
3. Throw tomatoes to stun/defeat NPCs
4. Scavenge tomatoes and items to stay resourced
5. Navigate the street without slipping, running dry, or getting overwhelmed

---

## Player Mechanics

### Movement
- 8-directional movement within the ground plane
- Walking speed feels weighty and physical, not floaty
- Slipping on tomato puddles causes brief loss of control (pratfall animation)

### Throwing
- Player throws tomatoes in the direction they're facing
- Throw arc is visible (maybe a brief parabolic splash path)
- Hitting an NPC stuns them briefly; repeat hits knock them down

### Ammo — The Backpack
- Player starts with ~12 tomatoes
- Ammo count always visible on HUD
- Tomatoes are picked up by walking over them
- Maximum capacity: 12
- When empty: player can only dodge — no throwing, fully vulnerable

---

## Health System

- Player has a health bar (e.g. 5 hearts)
- Taking a direct tomato hit = lose 1 heart
- Slipping on a puddle = brief stun, no heart loss (unless hit while down)
- Certain status effects (blinded, soaked) can amplify damage
- Food items restore hearts

---

## Hazards

| Hazard | Effect |
|---|---|
| Tomato (direct hit) | Lose 1 heart |
| Tomato puddle | Slip — brief pratfall, lose control |
| Tomato to the face | "Blinded" status — blurry screen for 2–3 seconds |
| Being surrounded | Risk of multi-hit combo from NPCs |

---

## Item System

Items are scattered on the ground or dropped by NPCs. Player picks them up by walking over them.

### Protective Gear
| Item | Effect |
|---|---|
| Goggles | Prevents "blinded" status from face hits |
| Bandana | Reduces face-hit damage |
| Helmet | Protects from head hits; reduces 1 heart of damage |
| Boots | Prevents slipping on tomato puddles |
| Towel | Clears "soaked/blinded" status instantly when picked up |

### Food — Health Restores
| Item | Hearts Restored |
|---|---|
| Patatas bravas | 1 heart |
| Bocadillo | 2 hearts |
| Tortilla española | 2 hearts |
| Pimientos | 1 heart |
| Olives | 1 heart |
| Cheese | 1 heart |
| Beer | 1 heart (with a brief screen wobble for comedy) |

### Collectibles (Score / Comedy)
- Bikini tops, swim goggles, rubber ducks, fan scarves
- No gameplay effect — trigger a fun animation or sound, add to score
- Reward players for exploring the full ground plane

---

## The Tomato Truck

A slow-moving truck (based on the real La Tomatina supply trucks) that travels through the level dispensing tomatoes. It is the primary ammo source and the visual centrepiece of the chaos.

- Moves slowly right-to-left through the level (against the player's scroll direction)
- Periodically dumps a cascade of tomatoes — they fly through the air and land on the ground as pickups
- Player can run alongside it to scavenge ammo
- The cascade also hits NPCs, briefly knocking them down (comic relief)
- Appears multiple times per run, announced by a distant rumble sfx
- Visually: large flatbed truck, red-branded, tomato-stained — a prominent scrolling landmark

---

## Enemies / NPCs

### Festival-Goer (basic)
- Wanders the street, throws tomatoes at player on sight
- Slips on puddles too (comedy opportunity)
- Drops 1–3 tomatoes when knocked down

### Aggressive Festival-Goer
- Moves faster, better aim, throws more frequently
- Drops more tomatoes

### Bucket Carrier (mini-hazard)
- Carries a giant bucket of tomatoes
- If they reach the player, dumps the whole bucket — big splat, brief blackout
- Worth prioritizing

*(Additional NPC types to be designed as scope allows)*

---

## Visual Style

### PICO-8 Palette Strategy
- **Sky:** color 12 (blue)
- **Hills (far background):** color 3 (dark green)
- **Castle stone:** color 9 (orange) + color 4 (brown) for shadows
- **Building walls:** color 7 (white) + color 15 (peach/cream) for variety
- **Wall dado (base stripe):** color 1 (dark blue) — pale blue kickplate seen on real buildings
- **Blue tarps:** color 1 (dark blue) — festival building protection sheeting
- **Terracotta roofs:** color 9 (orange) + color 4 (brown)
- **Tomatoes/splats:** color 8 (red) + color 2 (dark red/purple)
- **Ground (clean):** color 6 (light gray) + color 5 (dark gray mortar)
- **Ground (stained):** progressively shifts toward color 8 (red) as game progresses
- **Characters:** high contrast to stand out against background
- **Festival decoration:** color 8 (red banners), color 10 (yellow), color 14 (pink flowers)

### Background Layer Plan
```
y=0  to y=20  — sky (blue) + distant green hills silhouette
y=20 to y=45  — castle/church dome/bell tower (placed landmarks)
y=45 to y=72  — building facades (white/cream, balconies, windows, blue tarps)
y=72 to y=82  — terracotta roofline eave strip
y=82 to y=100 — cobblestone ground (walkable)
y=100+        — shadow
```

### Environment — Confirmed from Reference Photos
- Narrow street, buildings close on both sides
- Building facade details (all confirmed from street photography):
  - **Iron balconies** on every floor — defining visual feature
  - **Iron window grilles** at ground floor
  - **Light blue dado stripe** at base of walls (~20% height)
  - **Hanging flower baskets** — red geraniums spilling from upper walls
  - **Street lamp** — black iron lamp hanging from wall at mid-height
  - **Blue plastic tarps** — buildings wrapped for festival protection
  - **Overhead wires** strung building-to-building
  - **Festival banners** + "TOMATINA" signage between buildings
- **Palm trees** at street intersections — scrolling landmark
- **Balcony/rooftop spectators** — background characters watching the chaos
- **The Tomato Truck** — slow-moving truck dispensing tomatoes (see Mechanics)

### Landmarks (placed once in the map)
- **Gate arch (Torre del Portal)** — medieval arched gateway the player walks through
- **Castle (Castillo de Buñol)** — amber/golden tower + battlemented wall, visible above roofline
- **Church bell tower + blue dome** — cream tower + iconic blue tiled dome, visible mid-level

### Progressive Visual Staining
- Ground starts as clean gray cobblestone
- Tomato splats accumulate as persistent red puddles
- Late game: ground is predominantly red — a river of tomato
- Building lower walls gradually get red-splattered too

### Character Art Direction
- Chunky, expressive sprites (8x8 or 8x16 depending on detail needed)
- Exaggerated animations: big wind-up throw, full-body pratfall, dramatic splat reaction
- Player character: visibly festive — shorts, t-shirt, sandals (upgradeable with gear pickups)

### Effects
- Tomato splat: brief red particle burst + persistent puddle on ground
- Slip: spinning star or birds above head
- Blindness: red/dark overlay on screen
- Item pickup: brief flash + sound
- Food: small hearts floating up

---

## HUD

```
[HEALTH: ♥♥♥♥♥]   SCORE: 00000   [TOMATOES: 🍅x12]
```

- Left: health hearts
- Center: score
- Right: tomato ammo count (backpack)
- Equipped gear icons (optional, small row of icons)

---

## Audio Direction

- **Music:** Upbeat, slightly chaotic chiptune with a Spanish/festive feel. 4/4 rhythm, brass-like lead, energetic.
- **Throw:** satisfying "whoosh" + wet splat on impact
- **Slip:** classic cartoon slip sound
- **Pickup:** bright coin-like chime
- **Hit taken:** brief grunt + splat
- **Blind:** muffled/distorted audio while effect lasts
- **Beer pickup:** hiccup sound (comedy beat)
- **Bucket dump:** big dramatic splat chord

---

## Development Workflow

### Screenshot Review Process
1. Develop in PICO-8's built-in editor (code + sprite + map + sound tabs)
2. Run the cart to test (`Ctrl+R`)
3. Press `F6` to capture a screenshot (saved to desktop as PNG)
4. Share the screenshot in the Claude Code chat
5. Claude reviews visuals, suggests changes to code/sprites
6. Iterate

### File Location
- Cart file: `/Users/donaldbell/Documents/Claude_Code_Projects/Tomato/tomatina.p8`
- Screenshots shared directly in chat as needed

---

## Development Phases

Given weekend scope and new-to-PICO-8 context, build in this order:

### Phase 1 — Foundation
- [ ] Create the cart file, set up basic structure
- [ ] Player sprite (static, placeholder ok)
- [ ] 8-directional movement within ground plane
- [ ] Ground plane defined (walkable Y band)
- [ ] Camera scrolls with player on X axis

### Phase 2 — Core Mechanics
- [ ] Tomato projectile (throw + travel + splat)
- [ ] Ammo counter (backpack, max 12)
- [ ] Tomato pickups on ground
- [ ] Basic NPC: walks toward player, throws tomatoes
- [ ] Hit detection (player ↔ projectile, projectile ↔ NPC)
- [ ] Health bar

### Phase 3 — Game Feel
- [ ] Splat effect + persistent puddle
- [ ] Slip mechanic on puddles
- [ ] Sound effects (throw, splat, slip, pickup)
- [ ] Basic animations (walk cycle, throw, hit reaction)
- [ ] NPC slip/pratfall when hit

### Phase 4 — Items & Polish
- [ ] Food items (health restore)
- [ ] Protective gear items (goggles, boots, etc.)
- [ ] Collectibles
- [ ] Score system
- [ ] Title screen
- [ ] Game over screen

### Phase 5 — Environment & Audio
- [ ] Tiled street background with buildings
- [ ] Scrolling level with varied scenery
- [ ] Background music
- [ ] Balcony spectators (decorative)

---

## PICO-8 Technical Notes

- **Screen:** 128×128 pixels
- **Sprites:** 256 tiles of 8×8 pixels each
- **Map:** 128×32 tiles (can extend to 128×64 by sharing lower sprite sheet)
- **Colors:** 16 (fixed PICO-8 palette)
- **Code:** Lua, max 8192 tokens
- **Audio:** 4 channels, 64 SFX slots, 64 music patterns
- **Ground plane:** Y=80 to Y=101 (confirmed from The Lair reference — `mid(y,80,101)`)
- **Draw order:** sort all entities by `.y` before drawing each frame
- **Camera:** `camera(cam_x, 0)` — only scroll on X

---

## Code Architecture (informed by The Lair reference)

The Lair (`thelairv1.p8` by @krajzeg) is our primary PICO-8 structural reference for side-scrolling beat-em-up mechanics. Key patterns to adapt:

### Entity/State Machine
Each entity has a `state` field (string). The update loop calls `entity[state](entity, timer)` each frame. States for our entities:
- Player: `"idle"`, `"walk"`, `"throw"`, `"hit"`, `"down"`, `"slip"`
- NPC: `"wander"`, `"approach"`, `"throw"`, `"down"`, `"getup"`

### Facing Direction
Every entity has a `dir` field: `1` = facing right, `-1` = facing left.
Flip sprite horizontally with `spr(n, x, y, 1, 1, dir < 0)`.

### Ground Plane Constraint
After any movement, clamp: `entity.y = mid(entity.y, 80, 101)`
X is clamped to screen or level bounds.

### Y-Sorted Rendering
Collect all draw calls into a list keyed by `floor(entity.y)`, then draw in ascending y order (0→127). This makes lower-y entities appear behind higher-y ones.

### Hitboxes
Simple axis-aligned bounding boxes relative to entity position. Flip x-offsets based on `dir` for directional attacks.

### Key difference from The Lair
The Lair kills enemies. TOMATINA uses a **"downed"** state instead — NPCs get splatted, lie still briefly (leaving a puddle), then stand up and rejoin the chaos. No deaths.

---

*Last updated: 2026-05-19*
