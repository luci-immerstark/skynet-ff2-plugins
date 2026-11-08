# SKYNET GAMING · FF2 Plugins

Every SourceMod plugin running on the **SKYNET GAMING BRASIL / LATAM** **Freak Fortress 2** server (Team Fortress 2): ours and third-party ones, with source code and compiled `.smx`, so they stay available online.

> Third-party plugins are here only as a backup copy, exactly as we run them on the server. All credit goes to the authors listed in each table. Some sources have small fixes of ours so they compile and run on 64-bit SourceMod 1.12 (marked `SKYNET` in the code).

## Contents

- [Requirements](#requirements)
- [Repository layout](#repository-layout)
- [Installation](#installation)
- [Compiling](#compiling)
- [Plugins](#plugins)
  - [FF2 Rewrite (core)](#ff2-rewrite-core)
  - [Boss subplugins (`plugins/freaks`)](#boss-subplugins-pluginsfreaks)
  - [SKYNET plugins](#skynet-plugins)
  - [Other third-party plugins](#other-third-party-plugins)
  - [Stock SourceMod plugins](#stock-sourcemod-plugins)
- [Extra configuration](#extra-configuration)
- [Not included](#not-included)
- [License](#license)

## Requirements

- A **Team Fortress 2** dedicated server (Linux, 64-bit).
- **MetaMod:Source** and **SourceMod 1.12** (the `.smx` files were compiled for 1.12; DHooks already ships with SourceMod).
- The TF2Items and TF2Attributes extensions are **not** needed: they do not work on the 64-bit server (TF2Items crashes it). The `.smx` files in this repository were compiled with the replacements in [`include/tf2items.inc`](include/tf2items.inc) and [`include/skynet_tf2attrib.inc`](include/skynet_tf2attrib.inc), which do the same job through TF2's own VScript.
- The boss subplugins need **FF2 Rewrite** ([`plugins/freak_fortress_2`](plugins/freak_fortress_2/)) installed.

## Repository layout

```
plugins/<name>/            one plugin per folder; its contents mirror addons/sourcemod/
  plugins/<name>.smx       compiled plugin (boss subplugins go in plugins/freaks/)
  scripting/<name>.sp      source code (plus a <name>/ subfolder when the source has several files)
  configs/                 only when the plugin needs a config file
include/                   includes (.inc) used to compile, with the 64-bit replacements
translations/              translation files (.phrases.txt) the plugins use
gamedata/                  FF2 and TF2Items gamedata
```

## Installation

1. Pick the plugin in [`plugins/`](plugins/).
2. Copy the folders inside it (`plugins/`, and `configs/` if there is one) into `tf/addons/sourcemod/` on the server. For example:
   - `plugins/skynet_terceira/plugins/skynet_terceira.smx` → `tf/addons/sourcemod/plugins/skynet_terceira.smx`
   - `plugins/haunter/plugins/freaks/haunter.smx` → `tf/addons/sourcemod/plugins/freaks/haunter.smx`
3. If the plugin uses a translation or gamedata file, copy it from [`translations/`](translations/) to `addons/sourcemod/translations/` and from [`gamedata/`](gamedata/) to `addons/sourcemod/gamedata/`.
4. Load it with `sm plugins load <name>` or change map.

Boss subplugins (`freaks` folder): FF2 Rewrite loads the `.smx` files in that folder and renames them to `.ff2`. It only does this **on map change** (`ff2_loadsubplugins` does nothing mid-map). To check that one loaded: `sm plugins info freaks/<name>.ff2`.

## Compiling

Use SourceMod 1.12's `spcomp64` pointed at this repository's [`include/`](include/) folder (in addition to SourceMod's own `include/`):

```sh
spcomp64 -i include -i plugins/skynet_ff2_extras/scripting \
  plugins/skynet_ff2_extras/scripting/skynet_ff2_extras.sp -o skynet_ff2_extras.smx
```

FF2 Rewrite is the exception: it only uses TF2Attributes when the extension is loaded, so it compiles against the original `tf2attributes.inc` (in `plugins/freak_fortress_2/scripting/include/`), which has to come before this repository's `include/`:

```sh
spcomp64 -i plugins/freak_fortress_2/scripting/include -i include -i plugins/freak_fortress_2/scripting \
  plugins/freak_fortress_2/scripting/freak_fortress_2.sp -o freak_fortress_2.smx
```

## Plugins

### FF2 Rewrite (core)

Install in `addons/sourcemod/plugins/`.

| Plugin | Author | Version | What it does |
|---|---|---|---|
| [freak_fortress_2](plugins/freak_fortress_2/) | Batfoxkid (based on the original FF2) | 1.3.custom | The Freak Fortress 2 Rewrite game mode: one player becomes the boss against the rest of the server. Our build has adjusted music volume and the 64-bit replacements. |
| [ff2r_default_abilities](plugins/ff2r_default_abilities/) | Batfoxkid | Custom | FF2 Rewrite default abilities: super jump, teleport, weighdown, stun, weapon swap and similar. |
| [ff2r_gray_abilities](plugins/ff2r_gray_abilities/) | Batfoxkid | Custom | Extra FF2 Rewrite ability pack used by several bosses. |
| [ff2r_menu_abilities](plugins/ff2r_menu_abilities/) | Batfoxkid | Custom | Menu-selected abilities (the boss picks which rage/spell to use). |

### Boss subplugins (`plugins/freaks`)

Install in `addons/sourcemod/plugins/freaks/`. Each one adds abilities that the boss files (`.cfg`) call by name; they only do something when a boss uses those abilities.

| Plugin | Author | Version | What it does |
|---|---|---|---|
| [bloodriders_plugin](plugins/bloodriders_plugin/) | M7 | 3.0 | `rage_bloodrider` ability of the Bloodriders boss. |
| [darkevoir](plugins/darkevoir/) | SKYNET GAMING | 1.0.0 | `special_darkevoir`: on rage the boss goes through uber and other protections. |
| [default_abilities](plugins/default_abilities/) | RainBolt Dash | 1.10.5 | Common abilities from the old FF2: super jump, teleport, weighdown, stun. |
| [default_dots](plugins/default_dots/) | sarysa | 1.1.3 | Default DOTs (abilities that drain rage over time): beam, manic mode and others. |
| [double_copycat](plugins/double_copycat/) | M7 | 2.0 | Rage that copies a player's weapons and steals abilities (`rage_copycat`, `rage_skill_steal`). |
| [drain_over_time](plugins/drain_over_time/) | sarysa | 1.1.0 | Base of the old FF2's DOT (Drain Over Time) system. |
| [duck_abilities](plugins/duck_abilities/) | — | — | `special_duckpyro`, from the duck boss. |
| [easter_abilities](plugins/easter_abilities/) | Powerlord, FlaminSarge, Wliu | 1.10.8 | Cosmetic and projectile abilities (Easter eggs and similar). |
| [ff2_1st_set_abilities](plugins/ff2_1st_set_abilities/) | RainBolt Dash | 1.10.8 | Abilities of Seeldier, Seeman, Demopan, CBS and Ninja Spy: clones, matrix, explosive dance, CBS bow. |
| [ff2_blockdropitem](plugins/ff2_blockdropitem/) | Naydef | 1.0 | Stops the boss from dropping or picking up items. |
| [ff2_bosstweaks](plugins/ff2_bosstweaks/) | frog | 1.0 | Boss tweaks, such as gravity. |
| [ff2_darthmule_stripped](plugins/ff2_darthmule_stripped/) | Darthmule, Deathreus | 1.2 | `rage_condition`: applies TF2 conditions on rage. |
| [ff2_death](plugins/ff2_death/) | Deathreus | 1.5 | Magic charges: magic jump, magic teleport and projectiles with a cooldown. |
| [ff2_dynamic_defaults](plugins/ff2_dynamic_defaults/) | sarysa, RainBolt Dash | 1.3.3 | Configurable versions of jump, teleport and weighdown; other subplugins depend on it. |
| [ff2_fog](plugins/ff2_fog/) | Koishi | 1.04 | Fog effect on rage. |
| [ff2_grab](plugins/ff2_grab/) | SHADoW93 (base by Friagram) | 1.1 | The boss grabs and throws players. |
| [ff2_killicon](plugins/ff2_killicon/) | Naydef | 0.4 | Changes the boss's kill icon. |
| [ff2_movespeed](plugins/ff2_movespeed/) | SHADoW NiNE TR3S | 1.3.4 | Rage that changes the boss's speed. |
| [ff2_otokiru](plugins/ff2_otokiru/) | Otokiru, SHADoW93 | 1.7 | Abilities of several bosses: salmon, abstract spy, gentlemen, giftwrap, nurse. |
| [ff2_otokiru_wc3](plugins/ff2_otokiru_wc3/) | Otokiru | 1.1 | Configurable teleport and fixed weighdown. |
| [ff2_phatrages](plugins/ff2_phatrages/) | frog, Kemsan, Peace Maker, LeGone, RainBolt Dash | 0.9.4 | Delirium, drown, explosion, hellfire and ion cannon rages. |
| [ff2_ragemodel](plugins/ff2_ragemodel/) | frog | 1.1 | Changes the boss model during rage. |
| [ff2_replaceprojectile](plugins/ff2_replaceprojectile/) | frog, friagram | 1.0.2 | Replaces the projectiles of the boss's weapons. |
| [ff2_sarysamods](plugins/ff2_sarysamods/) | sarysa, 01Pollux | 1.1.0 | Delayed rages (damage, earthquake, building destruction) and airblast immunity. |
| [ff2_sarysamods3](plugins/ff2_sarysamods3/) | sarysa | 1.1.1 | Sentry hijack, teleport, character and rage scramble, flaming debris. |
| [ff2_sarysamods6](plugins/ff2_sarysamods6/) | sarysa | 1.1.4 | Haywire sentries, necromancy, simple passives and underwater abilities. |
| [ff2_sarysamods7](plugins/ff2_sarysamods7/) | sarysa | 1.3.1 | Entrapment, suck and chuck, class nerfs and mega abilities. |
| [ff2_sarysamods8](plugins/ff2_sarysamods8/) | sarysa | 1.2.3 | Guitar hero, head drain, paralyzing stare and head collection. |
| [ff2_sarysapub3](plugins/ff2_sarysapub3/) | sarysa | 1.0.2 BBG | Public pack 3 with AMS: dynamic teleport, damage dodge, fake Dead Ringer, front protection. |
| [ff2_sarysapub3a](plugins/ff2_sarysapub3a/) | sarysa | 1.0.2 BBG | Variant "a" of the same pack, for bosses that ask for that version. |
| [ff2_tfcond](plugins/ff2_tfcond/) | SHADoW NiNE TR3S | 1.1.1 | Applies TF2 conditions by rage, charge or special ability. |
| [ff2r_chat](plugins/ff2r_chat/) | Zell | 1.0.0 | Chat, hint or HUD messages when the boss uses rage. |
| [ff2r_darthmule_stripped](plugins/ff2r_darthmule_stripped/) | Darthmule, Zell | 1.3.1 | `rage_condition` for FF2 Rewrite. |
| [ff2r_doslot](plugins/ff2r_doslot/) | Zell | 1.0.2 | Triggers an ability slot after a delay or on killing a specific class. |
| [ff2r_drain_over_time](plugins/ff2r_drain_over_time/) | sarysa, Zell | 1.1.0 | DOT system for FF2 Rewrite. |
| [ff2r_fog](plugins/ff2r_fog/) | Koishi, J0BL3SS, Zell | 1.2.0 | Fog effects for FF2 Rewrite. |
| [ff2r_gravity](plugins/ff2r_gravity/) | J0BL3SS | 1.4.0 | Gravitational fields and shockwaves. |
| [ff2r_mann_up_abilities](plugins/ff2r_mann_up_abilities/) | M7, Zell | 1.0.1 | Mann vs. Machine announcer lines for the boss. |
| [ff2r_movespeed](plugins/ff2r_movespeed/) | SHADoW NiNE TR3S, Zell | 1.4.0 | Rage speed for FF2 Rewrite. |
| [ff2r_overlay](plugins/ff2r_overlay/) | Jery0987, RainBolt Dash, Naydef, Zell | 2.1.2 | Covers living players' screens with an image on rage. |
| [ff2r_phatrages](plugins/ff2r_phatrages/) | frog, Kemsan, Peace Maker, LeGone, RainBolt Dash, SHADoW NiNE TR3S, M76030, Zell | 0.9.8 | Phatrages for FF2 Rewrite. |
| [ff2r_public_dots](plugins/ff2r_public_dots/) | sarysa, Zell | 1.1.0 | Public DOTs for FF2 Rewrite: weapon and model swap, teleport, sentry knockback immunity. |
| [ff2r_revivemarker](plugins/ff2r_revivemarker/) | SHADoW93, Zell | 1.0.1 | Mann vs. Machine style revive markers. |
| [ff2r_s93_abilities](plugins/ff2r_s93_abilities/) | Koishi (SHADoW NiNE TR3S), Zell | 1.23.0 | Roboticize, taunt slide, class react and thriller. |
| [ff2r_tfcond](plugins/ff2r_tfcond/) | J0BL3SS, Zell | 1.1.0 | TF2 conditions for FF2 Rewrite. |
| [ff2r_timer](plugins/ff2r_timer/) | M7, Zell | 1.0.0 | Improved round timer. |
| [ffbat_defaults](plugins/ffbat_defaults/) | many authors (Batfoxkid) | 0.6.2 | Combined subplugin of the default abilities: base jumper, strange weapon, projectiles, CBS bow and others. |
| [halloween_2014](plugins/halloween_2014/) | Friagram | — | Abilities of the Halloween 2014 bosses. |
| [haunter](plugins/haunter/) | SKYNET GAMING | 1.0.0 | `special_haunter`: ghost mode and a scare on players. |
| [improved_saxton](plugins/improved_saxton/) | sarysa | 1.0.5 | Improved Saxton Hale: lunge and berserk. |
| [m7_abilities_extended](plugins/m7_abilities_extended/) | M76030 | 3.0 | Buffs, healing between bosses, rage on kill, player outlines and a new salmon. |
| [m7_customizable](plugins/m7_customizable/) | M7 | — | Clipless weapons on rage (`rage_cliplessweapons`). |
| [misc_stuff](plugins/misc_stuff/) | M7 | 5.0 | Assorted abilities, including configurable fog. |
| [overlay_on_kill](plugins/overlay_on_kill/) | Jery0987, RainBolt Dash, SHADoW NiNE TR3S | 1.4 | Same as `rage_overlay`, but when the boss kills someone. |
| [powerlord_abilities](plugins/powerlord_abilities/) | Powerlord | 2.0 | Rage transparency and special ragdolls. |
| [public_dots](plugins/public_dots/) | SKYNET GAMING | 1.0.0 | `dot_weapon_swap`, `dot_model_swap` and `dot_teleport` for old-FF2 bosses. |
| [rage_overlay](plugins/rage_overlay/) | Jery0987, RainBolt Dash | 1.9.3 | Covers living players' screens with an image on rage. |
| [s93_beepman](plugins/s93_beepman/) | 93SHADoW | 1.3 | Beepman abilities: scramble, bhop, sentry hijack and trails. |
| [s93_blitzkrieg](plugins/s93_blitzkrieg/) | SHADoW NiNE TR3S, sarysa | 3.3 Beta | Blitzkrieg: rocket rain (Projectile Hell). |
| [shadow93_abilities](plugins/shadow93_abilities/) | Koishi (SHADoW NiNE TR3S) | 1.23 | Summon minions and buildings, taunt slide and thriller. |
| [shadow93_bosses](plugins/shadow93_bosses/) | Koishi (SHADoW NiNE TR3S) | 1.23 | Abilities of Eirin Yagokoro, Female Heavy, Handsome Jack, Human Sentry Buster and Reimu Hakurei. |
| [special_ams_overlay](plugins/special_ams_overlay/) | M76030 | 1.0.0 | The stock `rage_overlay`, compatible with AMS. |
| [special_noanims](plugins/special_noanims/) | RainBolt Dash, Wliu | 1.10.8 | New weapon on rage and a boss with no animations. |
| [special_stipper](plugins/special_stipper/) | M7 | 1.0 | `rage_staring_at_sexiness`. |
| [the_true_administrator](plugins/the_true_administrator/) | M7 | 1.0 | Abilities of The True Administrator boss. Our patch: the normal rage triggers the abilities directly, without the AMS menu. |

### SKYNET plugins

Made by us for the server. Install in `addons/sourcemod/plugins/`. In-game messages are in Portuguese.

| Plugin | Version | What it does | Commands and cvars |
|---|---|---|---|
| [skynet_ff2_extras](plugins/skynet_ff2_extras/) | 1.2.7 | FF2 tweaks: end-of-round sound, melee crits, the Demoman shield and Razorback survive the stomp (the item breaks, the player lives), stomping the boss, uber gives crits (Medic and patient), summons never crit, backstab / stomp / Market Gardener in the air deal a fixed % of the boss's total health (all lives), melee wall climbing for some bosses, less knockback on the boss and fixed boss damage to buildings. | `skynet_ff2_stomp*`, `skynet_ff2_escudos`, `skynet_ff2_uber_critico`, `skynet_ff2_lacaio_critico`, `skynet_ff2_backstab_pct`, `skynet_ff2_stomp_pct`, `skynet_ff2_market_pct`, `skynet_ff2_escalar*`, `skynet_ff2_boss_empurrao`, `skynet_ff2_boss_predio`, `skynet_ff2_melee_critico`, `skynet_ff2_sniper_critico`, `skynet_ff2_som_vitoria` |
| [skynet_ff2_fila](plugins/skynet_ff2_fila/) | 1.1.0 | Fair boss queue: whoever waits longest becomes the boss. | `!fila` |
| [skynet_ff2_rodizio](plugins/skynet_ff2_rodizio/) | 1.1.0 | The round's boss does not repeat within the last N rounds (saved in `data/skynet_ff2_rodizio.txt`). | `!rodizio`, `skynet_ff2_rodizio`, `skynet_ff2_rodizio_duo_min` |
| [skynet_ff2_flecha](plugins/skynet_ff2_flecha/) | 1.1.0 | The Medic's crossbow bolt explodes, with a damage cap per shot on each target. | `skynet_ff2_flecha`, `skynet_ff2_flecha_dano`, `skynet_ff2_flecha_raio`, `skynet_ff2_flecha_max` |
| [skynet_ff2_semarma](plugins/skynet_ff2_semarma/) | 1.0.0 | The boss cannot pick up weapons from the ground (weapons dropped near it disappear). | `skynet_ff2_semarma_raio` |
| [skynet_ff2_pontos](plugins/skynet_ff2_pontos/) | 1.0.0 | FF2 ranking points (HLstatsX): boss win, win against the boss and damage. | — |
| [skynet_ff2_precarga](plugins/skynet_ff2_precarga/) | 1.0.0 | Loads the FF2 subplugins at map start, outside the round events. | — |
| [skynet_mapa_proibido](plugins/skynet_mapa_proibido/) | 1.1 | If the server starts on a forbidden map, it switches to another map right away. | `skynet_mapas_proibidos`, `skynet_mapa_destino` |
| [skynet_tauntcrit](plugins/skynet_tauntcrit/) | 1.0.0 | Taunting gives crits for a few seconds (one player at a time). | `skynet_tauntcrit_tempo`, `skynet_tauntcrit_minimo`, `skynet_tauntcrit_boss` |
| [skynet_taunts](plugins/skynet_taunts/) | 1.0 | Menu with every taunt in the game, even ones the player does not own. Needs `configs/skynet_taunts.txt` (included). | `!taunt`, `!taunts` |
| [skynet_terceira](plugins/skynet_terceira/) | 1.0.0 | Play in third person. | `!tp`, `!fp` |
| [skynet_killstreak](plugins/skynet_killstreak/) | 1.0.0 | Professional Killstreak on every weapon, with a choice of sheen and effect. | `!killstreak`, `!ks` |
| [skynet_amp](plugins/skynet_amp/) | 1.1.0 | The Engineer's Dispenser can become an Amplifier: gives crits to nearby allies. | `!amp`, `skynet_amp*` |
| [skynet_metal](plugins/skynet_metal/) | 1.0.0 | The Engineer regenerates metal over time. | `skynet_metal`, `skynet_metal_qtd`, `skynet_metal_intervalo`, `skynet_metal_max` |
| [skynet_dissolve](plugins/skynet_dissolve/) | 1.0.0 | Dead bodies dissolve (original idea by L. Duke). | `sm_dissolve`, `sm_dissolve_delay`, `sm_dissolve_type` |
| [skynet_sprays](plugins/skynet_sprays/) | 1.0.0 | Shows who made a spray and lets admins block offensive sprays. | `!quemspray`, `sm_spraytrace`, `sm_sprayban`, `sm_sprayunban` |
| [skynet_admtag](plugins/skynet_admtag/) | 1.3 | Chat tag: gold `[ADM]`, blue `[MOD]` and purple `[VIP]`, based on admin flags. | — |
| [skynet_entrada](plugins/skynet_entrada/) | 1.0.0 | Tells the chat who joined the server and from which country (uses SourceMod's GeoIP). | — |
| [skynet_silencio](plugins/skynet_silencio/) | 1.0.0 | Hides "cvar changed" notices from chat. | — |
| [skynet_bots](plugins/skynet_bots/) | 1.0.0 | Menu to add 1, 3, 5 or 10 test bots and remove them all (admin). | `!bots`, `skynet_bots_teste` |
| [zmbr_welcome](plugins/zmbr_welcome/) | 1.1 | Welcome message in chat, once per connection. | — |

The boss subplugins `darkevoir`, `haunter` and `public_dots` are ours too and are listed in the [subplugins table](#boss-subplugins-pluginsfreaks).

### Other third-party plugins

Install in `addons/sourcemod/plugins/`.

| Plugin | Author | Version | What it does |
|---|---|---|---|
| [ams_redux](plugins/ams_redux/) | sarysa, rework by 01Pollux | — | AMS (Ability Management System): lets the boss have several rages and choose which one to use. |
| [engipads](plugins/engipads/) | Starblaster 64 | 1.1.0 | The Engineer can swap the teleporter for jump and speed pads. Source with our 64-bit fixes; no version/credits announcement (only the `/pad` tip) and the messages in Portuguese for every client language. |
| [advertisements](plugins/advertisements/) | Tsunami | 2.1.2 | Automatic chat messages, read from `configs/advertisements.txt`. |
| [hlstatsx](plugins/hlstatsx/) | psychonic | 1.6.19 | In-game commands for HLstatsX CE (rank, top, etc.). |
| [superlogs-tf2](plugins/superlogs-tf2/) | Thomas "CmptrWz" Berezansky, psychonic | 2.0.32-skynet1 | Extra TF2 logging for HLstatsX. Our build has fixes for the current server. |
| [sbpp_main](plugins/sbpp_main/) | SourceBans Development Team, SourceBans++ Dev Team | 2.2.1 | SourceBans++: bans stored in the database and the web panel. |
| [sbpp_checker](plugins/sbpp_checker/) | psychonic, Ca$h Munny, SourceBans++ Dev Team | 2.2.1 | Tells admins when someone with previous bans joins. |
| [sbpp_comms](plugins/sbpp_comms/) | Alex, SourceBans++ Dev Team | 1.8.4 | Mute and gag (chat and voice punishments) SourceBans style. |
| [sbpp_report](plugins/sbpp_report/) | RumbleFrog, SourceBans++ Dev Team | 1.8.0 | Command for players to report other players. |
| [sbpp_admcfg](plugins/sbpp_admcfg/) | AlliedModders LLC, SourceBans++ Dev Team | 1.8.0 | Reads the admin files generated by SourceBans++. |

### Stock SourceMod plugins

These ship with SourceMod 1.12 and are not in this repository. Enabled on the server: `admin-flatfile`, `adminhelp`, `adminmenu`, `antiflood`, `basechat`, `basecomm`, `basecommands`, `basetriggers`, `basevotes`, `clientprefs`, `funcommands`, `funvotes`, `mapchooser`, `nextmap`, `nominations`, `playercommands`, `reservedslots`, `rockthevote` and `sounds`.

## Extra configuration

- **SourceBans++** needs a `sourcebans` entry in `configs/databases.cfg` and the SourceBans++ web panel. See the [SourceBans++ documentation](https://sbpp.github.io/).
- **hlstatsx**, **superlogs-tf2** and **skynet_ff2_pontos** only make sense with an HLstatsX CE install receiving the server logs.
- **advertisements** reads its messages from `configs/advertisements.txt`. Ours are not here because they are specific to our server.
- **skynet_entrada** uses SourceMod's GeoIP database (`configs/geoip`).
- The SKYNET plugins' cvars can go in `cfg/sourcemod/sourcemod.cfg`, which SourceMod runs on every map change.

## Not included

- The bosses themselves: boss `.cfg` files, models, sounds and materials.
- Server configuration (`server.cfg`, FF2 Rewrite configs in `data/freak_fortress_2`, map rotation, admins).
- The stock SourceMod plugins.

## License

Our code (the `skynet_*`, `zmbr_welcome`, `darkevoir`, `haunter` and `public_dots` plugins and the `skynet_*` includes) is released under the **GNU GPL v3**; see [LICENSE](LICENSE).

Third-party code keeps its authors' license and credits. Almost every SourceMod plugin uses GPL v3, like SourceMod itself. If you are the author of a plugin here and want it removed, open an issue.
