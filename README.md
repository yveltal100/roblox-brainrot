# roblox-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/yveltal100/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/yveltal100/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bay — Steal the Tide** is a 3D Roblox brainrot game in the genre *Steal a Brainrot* began, with a cast and a world of its own. Wild brainrots stroll down a conveyor lane on a beach island: buy one, haul it home on your head (it slows you down), and place it on your base, where it piles up dollars every second until you step on the gold pad to collect. Other players can steal from your base unless it is locked, rebirths multiply all income forever, and every couple of minutes a tsunami tide sweeps the lane — get home, or climb the Safe Hill, before it takes the brainrot on your head.

The cast climbs a six-step rarity ladder (Common → Rare → Epic → Legendary → Mythic → Brainrot God) with Gold, Diamond and Rainbow mutations: Cone Crab Carl, Toaster Giraffe Gigi, Disco Potato Duke, WiFi Router Rhino, Turbo Grandma Scooter, the Galaxy Fridge Phoenix, DJ Headphone Kraken, The Eternal Sock Dragon, and more — twelve originals, each built from parts with its name, rarity and $/s on a floating label.

Built Rojo-first: every script is a `.luau` file under `src/` (`shared/` catalogue and config, `server/` world builder, conveyor, bases, tide and state, `client/` HUD and tide effects), and `game.rbxl` is built from them. `main.ts` (Node 22, standard library only) hands the entry in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `dossier.json` with the vendored make.fun library.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio to play, publish it as a Public experience, and write its ids into `PLAY.json`. One screenshot in `screenshots/` is also the experience's first thumbnail on Roblox.

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
