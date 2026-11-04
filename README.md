# SKYNET GAMING · FF2 Plugins

Todos os plugins de SourceMod que rodam no servidor **Freak Fortress 2** (Team Fortress 2) da **SKYNET GAMING BRASIL / LATAM**: os nossos e os de terceiros, com o código-fonte e o `.smx` compilado, para que fiquem disponíveis na internet.

*Every SourceMod plugin running on the SKYNET GAMING **Freak Fortress 2** server (Team Fortress 2), ours and third-party ones, with source code and compiled `.smx`. Third-party plugins are mirrored here only for availability; all credit goes to their authors.*

> Os plugins de terceiros estão aqui só como cópia de segurança, do jeito que usamos no servidor. O crédito é todo dos autores listados em cada tabela. Alguns fontes têm pequenas correções nossas para compilar e rodar no SourceMod 1.12 de 64 bits (marcadas com `SKYNET` no código).

## Índice

- [Requisitos](#requisitos)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Como instalar](#como-instalar)
- [Como compilar](#como-compilar)
- [Plugins](#plugins)
  - [FF2 Rewrite (núcleo)](#ff2-rewrite-núcleo)
  - [Subplugins de boss (`plugins/freaks`)](#subplugins-de-boss-pluginsfreaks)
  - [Plugins SKYNET](#plugins-skynet)
  - [Outros plugins de terceiros](#outros-plugins-de-terceiros)
  - [Plugins padrão do SourceMod](#plugins-padrão-do-sourcemod)
- [Configurações extras](#configurações-extras)
- [O que não está incluído](#o-que-não-está-incluído)
- [Licença](#licença)

## Requisitos

- Servidor dedicado de **Team Fortress 2** (Linux, 64 bits).
- **MetaMod:Source** e **SourceMod 1.12** (os `.smx` foram compilados para 1.12; o DHooks já vem no SourceMod).
- **Não** precisa das extensões TF2Items nem TF2Attributes: no servidor 64 bits elas não funcionam (a TF2Items derruba o servidor). Os `.smx` deste repositório foram compilados com os substitutos em [`include/tf2items.inc`](include/tf2items.inc) e [`include/skynet_tf2attrib.inc`](include/skynet_tf2attrib.inc), que fazem o mesmo trabalho pelo VScript do próprio TF2.
- Os subplugins de boss precisam do **FF2 Rewrite** ([`plugins/freak_fortress_2`](plugins/freak_fortress_2/)) instalado.

## Estrutura do repositório

```
plugins/<nome>/            um plugin por pasta; o conteúdo espelha addons/sourcemod/
  plugins/<nome>.smx       plugin compilado (subplugins de boss ficam em plugins/freaks/)
  scripting/<nome>.sp      código-fonte (e a subpasta <nome>/ quando o fonte tem vários arquivos)
  configs/                 só quando o plugin precisa de um arquivo de configuração
include/                   includes (.inc) usados para compilar, com os substitutos de 64 bits
translations/              arquivos de tradução (.phrases.txt) que os plugins usam
gamedata/                  gamedata do FF2 e da TF2Items
```

## Como instalar

1. Escolha o plugin em [`plugins/`](plugins/).
2. Copie as pastas de dentro dele (`plugins/`, e `configs/` se houver) para `tf/addons/sourcemod/` no servidor. Exemplo:
   - `plugins/skynet_terceira/plugins/skynet_terceira.smx` → `tf/addons/sourcemod/plugins/skynet_terceira.smx`
   - `plugins/haunter/plugins/freaks/haunter.smx` → `tf/addons/sourcemod/plugins/freaks/haunter.smx`
3. Se o plugin usa tradução ou gamedata, copie o arquivo correspondente de [`translations/`](translations/) para `addons/sourcemod/translations/` e de [`gamedata/`](gamedata/) para `addons/sourcemod/gamedata/`.
4. Carregue com `sm plugins load <nome>` ou troque o mapa.

Subplugins de boss (pasta `freaks`): o FF2 Rewrite carrega os `.smx` dessa pasta e renomeia para `.ff2`. Ele só faz isso **na troca de mapa** (o `ff2_loadsubplugins` não faz nada no meio do mapa). Para conferir se carregou: `sm plugins info freaks/<nome>.ff2`.

## Como compilar

Use o `spcomp64` do SourceMod 1.12 apontando para a pasta [`include/`](include/) deste repositório (além da `include/` do próprio SourceMod):

```sh
spcomp64 -i include -i plugins/skynet_ff2_extras/scripting \
  plugins/skynet_ff2_extras/scripting/skynet_ff2_extras.sp -o skynet_ff2_extras.smx
```

Para o FF2 Rewrite, compile `plugins/freak_fortress_2/scripting/freak_fortress_2.sp` com `-i plugins/freak_fortress_2/scripting` (ele inclui os arquivos da subpasta `freak_fortress_2/`).

## Plugins

### FF2 Rewrite (núcleo)

Instale em `addons/sourcemod/plugins/`.

| Plugin | Autor | Versão | O que faz |
|---|---|---|---|
| [freak_fortress_2](plugins/freak_fortress_2/) | Batfoxkid (baseado no FF2 original) | 1.3.custom | O modo de jogo Freak Fortress 2 Rewrite: um jogador vira o boss contra o resto do servidor. Nossa versão tem o volume da música ajustado e os substitutos de 64 bits. |
| [ff2r_default_abilities](plugins/ff2r_default_abilities/) | Batfoxkid | Custom | Habilidades padrão do FF2 Rewrite: super pulo, teleporte, weighdown, stun, troca de arma e afins. |
| [ff2r_gray_abilities](plugins/ff2r_gray_abilities/) | Batfoxkid | Custom | Pacote extra de habilidades do FF2 Rewrite usado por vários bosses. |
| [ff2r_menu_abilities](plugins/ff2r_menu_abilities/) | Batfoxkid | Custom | Habilidades escolhidas por menu (o boss escolhe qual fúria/feitiço usar). |

### Subplugins de boss (`plugins/freaks`)

Instale em `addons/sourcemod/plugins/freaks/`. Cada um adiciona habilidades que os arquivos de boss (`.cfg`) chamam pelo nome; só fazem algo quando um boss usa essas habilidades.

| Plugin | Autor | Versão | O que faz |
|---|---|---|---|
| [bloodriders_plugin](plugins/bloodriders_plugin/) | M7 | 3.0 | Habilidade `rage_bloodrider` do boss Bloodriders. |
| [darkevoir](plugins/darkevoir/) | SKYNET GAMING | 1.0.0 | `special_darkevoir`: na fúria o boss atravessa a uber e outras proteções. |
| [default_abilities](plugins/default_abilities/) | RainBolt Dash | 1.10.5 | Habilidades comuns do FF2 antigo: super pulo, teleporte, weighdown, stun. |
| [default_dots](plugins/default_dots/) | sarysa | 1.1.3 | DOTs (habilidades que gastam fúria aos poucos) padrão: raio, modo maníaco e outros. |
| [double_copycat](plugins/double_copycat/) | M7 | 2.0 | Fúria que copia as armas de um jogador e rouba habilidades (`rage_copycat`, `rage_skill_steal`). |
| [drain_over_time](plugins/drain_over_time/) | sarysa | 1.1.0 | Base do sistema DOT (Drain Over Time) do FF2 antigo. |
| [duck_abilities](plugins/duck_abilities/) | — | — | `special_duckpyro`, do boss pato. |
| [easter_abilities](plugins/easter_abilities/) | Powerlord, FlaminSarge, Wliu | 1.10.8 | Habilidades de cosméticos e projéteis (ovos de Páscoa e afins). |
| [ff2_1st_set_abilities](plugins/ff2_1st_set_abilities/) | RainBolt Dash | 1.10.8 | Habilidades do Seeldier, Seeman, Demopan, CBS e Ninja Spy: clones, matrix, explosive dance, arco do CBS. |
| [ff2_blockdropitem](plugins/ff2_blockdropitem/) | Naydef | 1.0 | Impede o boss de soltar ou pegar itens. |
| [ff2_bosstweaks](plugins/ff2_bosstweaks/) | frog | 1.0 | Ajustes no boss, como gravidade. |
| [ff2_darthmule_stripped](plugins/ff2_darthmule_stripped/) | Darthmule, Deathreus | 1.2 | `rage_condition`: aplica condições do TF2 na fúria. |
| [ff2_death](plugins/ff2_death/) | Deathreus | 1.5 | Cargas mágicas: pulo mágico, teleporte mágico e projéteis com tempo de recarga. |
| [ff2_dynamic_defaults](plugins/ff2_dynamic_defaults/) | sarysa, RainBolt Dash | 1.3.3 | Versões configuráveis do pulo, teleporte e weighdown; outros subplugins dependem dele. |
| [ff2_fog](plugins/ff2_fog/) | Koishi | 1.04 | Efeito de névoa na fúria. |
| [ff2_grab](plugins/ff2_grab/) | SHADoW93 (base de Friagram) | 1.1 | O boss agarra e arremessa jogadores. |
| [ff2_killicon](plugins/ff2_killicon/) | Naydef | 0.4 | Troca o ícone de kill do boss. |
| [ff2_movespeed](plugins/ff2_movespeed/) | SHADoW NiNE TR3S | 1.3.4 | Fúria que muda a velocidade do boss. |
| [ff2_otokiru](plugins/ff2_otokiru/) | Otokiru, SHADoW93 | 1.7 | Habilidades de vários bosses: salmon, abstract spy, gentlemen, giftwrap, nurse. |
| [ff2_otokiru_wc3](plugins/ff2_otokiru_wc3/) | Otokiru | 1.1 | Teleporte configurável e weighdown corrigido. |
| [ff2_phatrages](plugins/ff2_phatrages/) | frog, Kemsan, Peace Maker, LeGone, RainBolt Dash | 0.9.4 | Fúrias de delírio, afogamento, explosão, hellfire e ion cannon. |
| [ff2_ragemodel](plugins/ff2_ragemodel/) | frog | 1.1 | Troca o modelo do boss durante a fúria. |
| [ff2_replaceprojectile](plugins/ff2_replaceprojectile/) | frog, friagram | 1.0.2 | Troca os projéteis das armas do boss. |
| [ff2_sarysamods](plugins/ff2_sarysamods/) | sarysa, 01Pollux | 1.1.0 | Fúrias com atraso (dano, terremoto, destruição de construções) e imunidade a airblast. |
| [ff2_sarysamods3](plugins/ff2_sarysamods3/) | sarysa | 1.1.1 | Roubo de sentry, teleporte, embaralhar personagens e fúria, destroços em chamas. |
| [ff2_sarysamods6](plugins/ff2_sarysamods6/) | sarysa | 1.1.4 | Sentries descontroladas, necromancia, passivas simples e habilidades debaixo d'água. |
| [ff2_sarysamods7](plugins/ff2_sarysamods7/) | sarysa | 1.3.1 | Armadilhas, sugar e arremessar, nerf de classes e mega habilidades. |
| [ff2_sarysamods8](plugins/ff2_sarysamods8/) | sarysa | 1.2.3 | Guitar hero, dreno pela cabeça, olhar paralisante e coleção de cabeças. |
| [ff2_sarysapub3](plugins/ff2_sarysapub3/) | sarysa | 1.0.2 BBG | Pacote público 3 com AMS: teleporte dinâmico, desvio de dano, falso Dead Ringer, proteção frontal. |
| [ff2_sarysapub3a](plugins/ff2_sarysapub3a/) | sarysa | 1.0.2 BBG | Variante "a" do mesmo pacote, para os bosses que pedem essa versão. |
| [ff2_tfcond](plugins/ff2_tfcond/) | SHADoW NiNE TR3S | 1.1.1 | Aplica condições do TF2 por fúria, carga ou habilidade especial. |
| [ff2r_chat](plugins/ff2r_chat/) | Zell | 1.0.0 | Mensagens no chat, hint ou HUD quando o boss usa a fúria. |
| [ff2r_darthmule_stripped](plugins/ff2r_darthmule_stripped/) | Darthmule, Zell | 1.3.1 | `rage_condition` para o FF2 Rewrite. |
| [ff2r_doslot](plugins/ff2r_doslot/) | Zell | 1.0.2 | Ativa um slot de habilidade depois de um tempo ou ao matar uma classe específica. |
| [ff2r_drain_over_time](plugins/ff2r_drain_over_time/) | sarysa, Zell | 1.1.0 | Sistema DOT para o FF2 Rewrite. |
| [ff2r_fog](plugins/ff2r_fog/) | Koishi, J0BL3SS, Zell | 1.2.0 | Efeitos de névoa para o FF2 Rewrite. |
| [ff2r_gravity](plugins/ff2r_gravity/) | J0BL3SS | 1.4.0 | Campos gravitacionais e ondas de choque. |
| [ff2r_mann_up_abilities](plugins/ff2r_mann_up_abilities/) | M7, Zell | 1.0.1 | Falas do anunciador do Mann vs. Machine para o boss. |
| [ff2r_movespeed](plugins/ff2r_movespeed/) | SHADoW NiNE TR3S, Zell | 1.4.0 | Velocidade na fúria para o FF2 Rewrite. |
| [ff2r_overlay](plugins/ff2r_overlay/) | Jery0987, RainBolt Dash, Naydef, Zell | 2.1.2 | Cobre a tela dos jogadores vivos com uma imagem na fúria. |
| [ff2r_phatrages](plugins/ff2r_phatrages/) | frog, Kemsan, Peace Maker, LeGone, RainBolt Dash, SHADoW NiNE TR3S, M76030, Zell | 0.9.8 | Phatrages para o FF2 Rewrite. |
| [ff2r_public_dots](plugins/ff2r_public_dots/) | sarysa, Zell | 1.1.0 | DOTs públicos para o FF2 Rewrite: troca de arma e de modelo, teleporte, imunidade ao empurrão da sentry. |
| [ff2r_revivemarker](plugins/ff2r_revivemarker/) | SHADoW93, Zell | 1.0.1 | Marcadores de reviver no estilo do Mann vs. Machine. |
| [ff2r_s93_abilities](plugins/ff2r_s93_abilities/) | Koishi (SHADoW NiNE TR3S), Zell | 1.23.0 | Roboticize, taunt slide, class react e thriller. |
| [ff2r_tfcond](plugins/ff2r_tfcond/) | J0BL3SS, Zell | 1.1.0 | Condições do TF2 para o FF2 Rewrite. |
| [ff2r_timer](plugins/ff2r_timer/) | M7, Zell | 1.0.0 | Cronômetro da rodada melhorado. |
| [ffbat_defaults](plugins/ffbat_defaults/) | vários autores (Batfoxkid) | 0.6.2 | Subplugin que junta as habilidades padrão: base jumper, arma strange, projéteis, arco do CBS e outras. |
| [halloween_2014](plugins/halloween_2014/) | Friagram | — | Habilidades dos bosses do Halloween 2014. |
| [haunter](plugins/haunter/) | SKYNET GAMING | 1.0.0 | `special_haunter`: modo fantasma e susto nos jogadores. |
| [improved_saxton](plugins/improved_saxton/) | sarysa | 1.0.5 | Saxton Hale melhorado: investida e berserk. |
| [m7_abilities_extended](plugins/m7_abilities_extended/) | M76030 | 3.0 | Buffs, cura entre bosses, fúria ao matar, contorno nos jogadores e nova salmon. |
| [m7_customizable](plugins/m7_customizable/) | M7 | — | Armas sem pente na fúria (`rage_cliplessweapons`). |
| [misc_stuff](plugins/misc_stuff/) | M7 | 5.0 | Habilidades variadas, entre elas névoa configurável. |
| [overlay_on_kill](plugins/overlay_on_kill/) | Jery0987, RainBolt Dash, SHADoW NiNE TR3S | 1.4 | Igual ao `rage_overlay`, mas quando o boss mata alguém. |
| [powerlord_abilities](plugins/powerlord_abilities/) | Powerlord | 2.0 | Transparência na fúria e ragdolls especiais. |
| [public_dots](plugins/public_dots/) | SKYNET GAMING | 1.0.0 | `dot_weapon_swap`, `dot_model_swap` e `dot_teleport` para bosses do FF2 antigo. |
| [rage_overlay](plugins/rage_overlay/) | Jery0987, RainBolt Dash | 1.9.3 | Cobre a tela dos jogadores vivos com uma imagem na fúria. |
| [s93_beepman](plugins/s93_beepman/) | 93SHADoW | 1.3 | Habilidades do Beepman: embaralhar, bhop, roubo de sentry e rastros. |
| [s93_blitzkrieg](plugins/s93_blitzkrieg/) | SHADoW NiNE TR3S, sarysa | 3.3 Beta | Blitzkrieg: chuva de foguetes (Projectile Hell). |
| [shadow93_abilities](plugins/shadow93_abilities/) | Koishi (SHADoW NiNE TR3S) | 1.23 | Invocar ajudantes e construções, taunt slide e thriller. |
| [shadow93_bosses](plugins/shadow93_bosses/) | Koishi (SHADoW NiNE TR3S) | 1.23 | Habilidades de Eirin Yagokoro, Female Heavy, Handsome Jack, Human Sentry Buster e Reimu Hakurei. |
| [special_ams_overlay](plugins/special_ams_overlay/) | M76030 | 1.0.0 | O `rage_overlay` padrão, compatível com o AMS. |
| [special_noanims](plugins/special_noanims/) | RainBolt Dash, Wliu | 1.10.8 | Arma nova na fúria e boss sem animações. |
| [special_stipper](plugins/special_stipper/) | M7 | 1.0 | `rage_staring_at_sexiness`. |
| [the_true_administrator](plugins/the_true_administrator/) | M7 | 1.0 | Habilidades do boss The True Administrator. |

### Plugins SKYNET

Feitos por nós para o servidor. Instale em `addons/sourcemod/plugins/`. Mensagens em português.

| Plugin | Versão | O que faz | Comandos e cvars |
|---|---|---|---|
| [skynet_ff2_extras](plugins/skynet_ff2_extras/) | 1.2.3 | Ajustes do FF2: som no fim da rodada, melee crítico, escudo do Demoman e Razorback aguentam o stomp (o item quebra, o jogador não morre), stomp no boss, uber dá crítico, escalada com melee para alguns bosses, menos empurrão no boss e dano fixo do boss em construções. | `skynet_ff2_stomp*`, `skynet_ff2_escudos`, `skynet_ff2_uber_critico`, `skynet_ff2_escalar*`, `skynet_ff2_boss_empurrao`, `skynet_ff2_boss_predio`, `skynet_ff2_melee_critico`, `skynet_ff2_sniper_critico`, `skynet_ff2_som_vitoria` |
| [skynet_ff2_fila](plugins/skynet_ff2_fila/) | 1.1.0 | Fila de boss justa: quem espera mais vira o boss. | `!fila` |
| [skynet_ff2_rodizio](plugins/skynet_ff2_rodizio/) | 1.1.0 | O boss da rodada não se repete nas últimas N rodadas (guarda em `data/skynet_ff2_rodizio.txt`). | `!rodizio`, `skynet_ff2_rodizio`, `skynet_ff2_rodizio_duo_min` |
| [skynet_ff2_flecha](plugins/skynet_ff2_flecha/) | 1.1.0 | A flecha da besta do Medic explode, com teto de dano por tiro em cada alvo. | `skynet_ff2_flecha`, `skynet_ff2_flecha_dano`, `skynet_ff2_flecha_raio`, `skynet_ff2_flecha_max` |
| [skynet_ff2_semarma](plugins/skynet_ff2_semarma/) | 1.0.0 | O boss não pega arma do chão (as armas largadas perto dele somem). | `skynet_ff2_semarma_raio` |
| [skynet_ff2_pontos](plugins/skynet_ff2_pontos/) | 1.0.0 | Pontos do ranking (HLstatsX) no FF2: vitória do boss, vitória contra o boss e dano. | — |
| [skynet_ff2_precarga](plugins/skynet_ff2_precarga/) | 1.0.0 | Carrega os subplugins do FF2 no início do mapa, fora dos eventos da rodada. | — |
| [skynet_mapa_proibido](plugins/skynet_mapa_proibido/) | 1.1 | Se o servidor abrir num mapa proibido, troca na hora para outro mapa. | `skynet_mapas_proibidos`, `skynet_mapa_destino` |
| [skynet_tauntcrit](plugins/skynet_tauntcrit/) | 1.0.0 | Taunt dá crítico por alguns segundos (um jogador por vez). | `skynet_tauntcrit_tempo`, `skynet_tauntcrit_minimo`, `skynet_tauntcrit_boss` |
| [skynet_taunts](plugins/skynet_taunts/) | 1.0 | Menu com todas as taunts do jogo, mesmo as que o jogador não tem. Precisa de `configs/skynet_taunts.txt` (incluído). | `!taunt`, `!taunts` |
| [skynet_terceira](plugins/skynet_terceira/) | 1.0.0 | Jogar em terceira pessoa. | `!tp`, `!fp` |
| [skynet_killstreak](plugins/skynet_killstreak/) | 1.0.0 | Professional Killstreak em todas as armas, com escolha de brilho e efeito. | `!killstreak`, `!ks` |
| [skynet_amp](plugins/skynet_amp/) | 1.1.0 | O Dispenser do Engineer pode virar Amplificador: dá crítico aos aliados por perto. | `!amp`, `skynet_amp*` |
| [skynet_metal](plugins/skynet_metal/) | 1.0.0 | O Engineer regenera metal aos poucos. | `skynet_metal`, `skynet_metal_qtd`, `skynet_metal_intervalo`, `skynet_metal_max` |
| [skynet_dissolve](plugins/skynet_dissolve/) | 1.0.0 | Os corpos dos mortos se dissolvem (ideia original de L. Duke). | `sm_dissolve`, `sm_dissolve_delay`, `sm_dissolve_type` |
| [skynet_sprays](plugins/skynet_sprays/) | 1.0.0 | Mostra de quem é o spray e permite bloquear sprays ofensivos. | `!quemspray`, `sm_spraytrace`, `sm_sprayban`, `sm_sprayunban` |
| [skynet_admtag](plugins/skynet_admtag/) | 1.3 | Tag no chat: `[ADM]` dourada, `[MOD]` azul e `[VIP]` roxa, conforme as flags de admin. | — |
| [skynet_entrada](plugins/skynet_entrada/) | 1.0.0 | Avisa no chat quem entrou no servidor e de qual país (usa o GeoIP do SourceMod). | — |
| [skynet_silencio](plugins/skynet_silencio/) | 1.0.0 | Esconde do chat os avisos de cvar alterada. | — |
| [skynet_bots](plugins/skynet_bots/) | 1.0.0 | Menu para colocar 1, 3, 5 ou 10 bots de teste e tirar todos (admin). | `!bots`, `skynet_bots_teste` |
| [zmbr_welcome](plugins/zmbr_welcome/) | 1.1 | Mensagem de boas-vindas no chat, uma vez por conexão. | — |

Os subplugins de boss `darkevoir`, `haunter` e `public_dots` também são nossos e estão na [tabela de subplugins](#subplugins-de-boss-pluginsfreaks).

### Outros plugins de terceiros

Instale em `addons/sourcemod/plugins/`.

| Plugin | Autor | Versão | O que faz |
|---|---|---|---|
| [ams_redux](plugins/ams_redux/) | sarysa, rework de 01Pollux | — | AMS (Ability Management System): permite que o boss tenha várias fúrias e escolha qual usar. |
| [engipads](plugins/engipads/) | Starblaster 64 | 1.1.0 | O Engineer pode trocar o teleporte por pads de pulo e de velocidade. Fonte com correções nossas para 64 bits. |
| [advertisements](plugins/advertisements/) | Tsunami | 2.1.2 | Mensagens automáticas no chat, lidas de `configs/advertisements.txt`. |
| [hlstatsx](plugins/hlstatsx/) | psychonic | 1.6.19 | Comandos dentro do jogo para o HLstatsX CE (rank, top, etc.). |
| [superlogs-tf2](plugins/superlogs-tf2/) | Thomas "CmptrWz" Berezansky, psychonic | 2.0.32-skynet1 | Logs extras do TF2 para o HLstatsX. Nossa versão tem correções para o servidor atual. |
| [sbpp_main](plugins/sbpp_main/) | SourceBans Development Team, SourceBans++ Dev Team | 2.2.1 | SourceBans++: bans gravados no banco de dados e no painel web. |
| [sbpp_checker](plugins/sbpp_checker/) | psychonic, Ca$h Munny, SourceBans++ Dev Team | 2.2.1 | Avisa os admins quando entra alguém com bans anteriores. |
| [sbpp_comms](plugins/sbpp_comms/) | Alex, SourceBans++ Dev Team | 1.8.4 | Mute e gag (punições de chat e voz) no estilo SourceBans. |
| [sbpp_report](plugins/sbpp_report/) | RumbleFrog, SourceBans++ Dev Team | 1.8.0 | Comando para os jogadores denunciarem outros jogadores. |
| [sbpp_admcfg](plugins/sbpp_admcfg/) | AlliedModders LLC, SourceBans++ Dev Team | 1.8.0 | Lê os arquivos de admin gerados pelo SourceBans++. |

### Plugins padrão do SourceMod

Vêm com o SourceMod 1.12 e não estão neste repositório. No servidor estão ligados: `admin-flatfile`, `adminhelp`, `adminmenu`, `antiflood`, `basechat`, `basecomm`, `basecommands`, `basetriggers`, `basevotes`, `clientprefs`, `funcommands`, `funvotes`, `mapchooser`, `nextmap`, `nominations`, `playercommands`, `reservedslots`, `rockthevote` e `sounds`.

## Configurações extras

- **SourceBans++** precisa de uma entrada `sourcebans` no `configs/databases.cfg` e do painel web do SourceBans++. Veja a [documentação do SourceBans++](https://sbpp.github.io/).
- **hlstatsx**, **superlogs-tf2** e **skynet_ff2_pontos** só fazem sentido com um HLstatsX CE recebendo os logs do servidor.
- **advertisements** lê as mensagens de `configs/advertisements.txt`. As nossas não estão aqui porque são próprias do servidor.
- **skynet_entrada** usa o banco GeoIP do SourceMod (`configs/geoip`).
- As cvars dos plugins SKYNET podem ir no `cfg/sourcemod/sourcemod.cfg`, que o SourceMod executa em toda troca de mapa.

## O que não está incluído

- Os bosses em si: arquivos `.cfg` dos bosses, modelos, sons e materiais.
- Configurações do servidor (`server.cfg`, configs do FF2 Rewrite em `data/freak_fortress_2`, rotação de mapas, admins).
- Os plugins padrão do SourceMod.

## Licença

O nosso código (plugins `skynet_*`, `zmbr_welcome`, `darkevoir`, `haunter`, `public_dots` e os includes `skynet_*`) é distribuído sob a **GNU GPL v3**; veja [LICENSE](LICENSE).

O código de terceiros continua com a licença e os créditos dos seus autores. Quase todos os plugins de SourceMod usam a GPL v3, como o próprio SourceMod. Se você é autor de algum plugin daqui e quer que ele seja removido, abra uma issue.
