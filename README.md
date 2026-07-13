# Escapa de La Tomatina 🍅

A PICO-8 survival arcade game set at Spain's La Tomatina festival. You've stumbled into the chaos in Buñol, Spain, where the whole town hurls tomatoes at each other for sport — dodge incoming splats, scavenge ammo and gear, and survive as long as you can.

![gameplay gif](images/tomatina_0.gif)

## About

Escapa de La Tomatina is a side-scrolling survival game built for the PICO-8 fantasy console. Navigate a tomato-soaked street on a beat-em-up style ground plane, throwing tomatoes to stun the crowd while dodging the ones thrown at you. Slip on puddles, get blinded by a face-hit, chase down the tomato truck for more ammo, and gear up with protective items to last longer.

**Tone:** comedic, chaotic, adult fun — think a great party that got completely out of hand, not a kids' game.

**References:** Metal Slug, TMNT Arcade, The Simpsons Arcade

## Play It

- **Source cart:** `tomatina.p8` — open in [PICO-8](https://www.lexaloffle.com/pico-8.php) to play the current version
- **Web build:** browser-playable exports live in [`web-export/`](web-export/). `tomatina_v1.1.html` is the more recent snapshot; `tomatina_v1.html` is an earlier one. Download the matching `.html` and `.js` pair, then open the `.html` file locally. Both predate several features below — `tomatina.p8` is the up-to-date version.
- **`.p8.png` cart:** [`web-export/tomatina_v1.1.p8.png`](web-export/tomatina_v1.1.p8.png) is a self-contained cart image — drag it into PICO-8 (or load it with `load`) to play the same v1.1 snapshot without a browser.

## Controls

| Input | Action |
|---|---|
| Arrow keys | 8-directional movement |
| Z / C | Throw tomato |
| X / V | Jump |

## Features

- **Survival core loop** — dodge, throw, scavenge, and last as long as possible against an escalating crowd
- **Backpack ammo system** — carry up to 12 tomatoes, scavenge more from the ground or the tomato truck
- **Slip mechanic** — tomato puddles cause pratfalls and brief loss of control
- **Protective gear** — goggles, bandana, helmet, boots, and towel counter specific hazards (blindness, puddle slips, face/head hits)
- **Food items** — patatas bravas, bocadillo, tortilla española, and more restore health
- **Collectibles** — bikini tops, rubber ducks, fan scarves, and other silliness for score, no gameplay effect
- **The Tomato Truck** — a slow-moving truck that periodically dumps a cascade of tomatoes, the primary ammo source and visual centerpiece
- **Boss level** and escalating difficulty across levels
- **Progressive staining** — the ground shifts from clean cobblestone to a river of tomato as a run goes on
- **Full audio pass** — SFX for every action plus looping background music

## Built With

- [PICO-8](https://www.lexaloffle.com/pico-8.php) — fantasy console, Lua

## Credits

Structural reference for camera, ground-plane movement, and state-machine architecture: [The Lair](https://github.com/krajzeg/thelair) by @krajzeg.

## License

MIT — see [LICENSE](LICENSE).
