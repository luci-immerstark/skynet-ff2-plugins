// SKYNET FF2 Extras: win/loss sound, melee always crits, shields hold the boss's 1st hit and stomping the boss
// 1.0.1: at the start of each round FF2 moves almost everyone to another team at the same time; the notices for it (joined team /
//   changed class) went to every player at the same instant and overflowed the packet ("Buffer overflow in net message").
//   Now those two notices are no longer sent to players (the server still records them in the log).
// 1.0.2: stomp fixed. Whoever lands on the boss's head no longer takes fall damage; the damage goes to the boss.
//   The stomp is detected both by touch and by fall damage on top of the boss.
// 1.1.0: stomp redone: detects landing on the head (every tick), works both ways (player on boss and boss on
//   player), uses FF2 Rewrite's values (boss takes 585 and the stomper bounces 450 up; the boss stomping kills), own sound
//   and the stomper's fall damage is cancelled. Sniper: scoped shot (any charge) always crits.
// 1.1.1: melee wall climbing (Demoman, Spy, Sniper) done here, same as FF2/VSH (the Medic still goes through the FF2
//   config, where it already worked).
// 1.1.2: Engineer and Heavy also climb walls with melee.
// 1.1.3: announces the "goomba" library (the Blitzkrieg boss requires the goomba plugin; the stomp here does that job). The stomp sound is also precached when the plugin is reloaded mid-map.
// 1.1.4: louder stomp sound: new normalized file (goomba_stomp2.wav) and, for the stomper and the stomped,
//   the sound plays right in the ear (no volume loss with distance); everyone else hears it by position.
// 1.1.5: Mario sound 14x louder (with a limiter, no clipping) in goomba_stomp3.wav and confetti coming out of the head of whoever
//   got stomped (TF2's own "bday_confetti" particle; skynet_ff2_stomp_confete swaps the effect or turns it off with "").
// 1.1.8: boss stomp on someone with a shield (Demoman, Darwin's) or Razorback: the shield breaks and holds the stomp the same way it holds
//   the boss's hit (half the damage and no death), instead of killing outright.
// 1.1.9: the Medigun's normal uber also gives crits (to the Medic and to whoever he ubers, while the uber lasts)
//   and melee wall climbing costs 30 health (it was 15).
// 1.2.0: bosses in the skynet_ff2_escalar_bosses list (the HHH) also climb walls with melee, without losing health
//   (self-damage would give the boss rage).
// 1.2.1: climbing at a cost of 30 jumped higher (self-damage pushes the player and the push grows with the
//   damage). Now only the first 15 push (the old height); the rest of the cost is taken without push. Also applies to the
//   Medic's climb, which comes from FF2 (weapon config with 15): Extras charges the difference without push.
// 1.2.2: the boss takes less knockback from damage (crit sniper shot, sentry, crit explosion...): TF2 attribute
//   "damage force reduction" on the boss (skynet_ff2_boss_empurrao, 0.5 = half the normal knockback).
// 1.2.3: a boss melee hit on an Engineer building (sentry, dispenser, teleporter) deals a fixed 195
//   (skynet_ff2_boss_predio; no crit on top).
// 1.2.4: summons (players who spawn on the boss team to help it) never crit: no melee/sniper/uber crits from this
//   plugin, crit conditions are removed and crit damage is turned into normal damage (skynet_ff2_lacaio_critico 0).
// 1.2.5: the uber crits are applied by a 0.2 s check (any player in the normal uber gets Kritz while it lasts),
//   no longer depending on the condition-added forward.
// 1.2.7: the % damages use the boss's total health (one life x number of lives).
// 1.2.6: damage on the boss as a % of its full health (per life): backstab 7%, stomp 5% and the Market Gardener
//   while rocket jumping 5% (skynet_ff2_backstab_pct / skynet_ff2_stomp_pct / skynet_ff2_market_pct; 0 = FF2's own).
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <cfgmap>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Extras",
    author      = "SKYNET GAMING",
    description = "FF2: som no fim da rodada, melee critico, escudos resistem e stomp no boss",
    version     = "1.2.7",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native Handle FF2R_GetBossData(int client);   // FF2 Rewrite: != null if the player is a boss

#define SOM_STOMP "skynet/goomba_stomp3.wav"

ConVar g_cvSom, g_cvCrit, g_cvEscudo, g_cvStomp, g_cvStompDano, g_cvSilencia, g_cvSniper, g_cvStompVel;
bool g_bNoAr[MAXPLAYERS + 1];
int g_iArmaAnt[MAXPLAYERS + 1];
float g_fProxAtq[MAXPLAYERS + 1];
ConVar g_cvLacaioCrit;
ConVar g_cvPctStab, g_cvPctStomp, g_cvPctMarket;
ConVar g_cvEscalar, g_cvEscalarDano, g_cvConfete, g_cvUberCrit, g_cvEscalarBoss, g_cvBossEmpurrao, g_cvBossPredio;
bool g_bCritUber[MAXPLAYERS + 1];
bool g_bEscalando;
#define ESCALAR_EMPURRA 15.0   // part of the climb cost that pushes (the original height)
float g_fVz[MAXPLAYERS + 1];
GlobalForward g_fwStomp;
float g_fUltimoStomp[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    RegPluginLibrary("goomba");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvSom       = CreateConVar("skynet_ff2_som_vitoria", "1", "Toca a musica de vitoria/derrota do TF2 no fim da rodada");
    g_cvCrit      = CreateConVar("skynet_ff2_melee_critico", "1", "Melee sempre critico para quem nao e boss");
    g_cvEscudo    = CreateConVar("skynet_ff2_escudos", "1", "Escudos do Demoman e do Sniper seguram o 1o golpe do boss (metade do dano e nao morre) e quebram");
    g_cvStomp     = CreateConVar("skynet_ff2_stomp", "1", "Cair na cabeca do boss da dano (stomp)");
    g_cvStompDano = CreateConVar("skynet_ff2_stomp_dano", "585", "Dano do stomp se o FF2 nao definir");
    g_cvSilencia  = CreateConVar("skynet_ff2_silencia_times", "1", "Nao envia aos jogadores os avisos de troca de time/classe (evita o Buffer overflow no inicio da rodada)");
    g_cvSniper    = CreateConVar("skynet_ff2_sniper_critico", "1", "Tiro do rifle de sniper com a mira (qualquer carga) e sempre critico");
    g_cvStompVel  = CreateConVar("skynet_ff2_stomp_velocidade", "360", "Velocidade minima de queda (unidades/s) para valer o stomp (360 = padrao do Goomba Stomp: precisa cair de mais alto que um pulo normal)");
    g_cvEscalar     = CreateConVar("skynet_ff2_escalar", "1", "Melee do Demoman, Spy, Sniper, Engineer e Heavy escala parede (bata o melee de frente para a parede; o Medic vem da config do FF2)");
    g_cvEscalarDano = CreateConVar("skynet_ff2_escalar_dano", "30", "Vida que cada escalada custa (0 = de graca)");
    g_cvEscalarBoss = CreateConVar("skynet_ff2_escalar_bosses", "hhh,horsemann,headless", "Bosses que escalam parede com o melee: pedacos do nome ou do arquivo do boss, separados por virgula (vazio = nenhum)");
    g_cvBossEmpurrao = CreateConVar("skynet_ff2_boss_empurrao", "0.5", "Empurrao que o boss leva de dano (1 = normal do jogo, 0.5 = metade, 0 = nenhum)", _, true, 0.0, true, 1.0);
    g_cvBossPredio  = CreateConVar("skynet_ff2_boss_predio", "195", "Dano fixo de cada golpe corpo a corpo do boss em construcao do Engineer (0 = como o jogo)", _, true, 0.0);
    g_cvUberCrit    = CreateConVar("skynet_ff2_uber_critico", "1", "A uber normal da Medigun tambem da critico enquanto durar");
    g_cvConfete     = CreateConVar("skynet_ff2_stomp_confete", "bday_confetti", "Efeito que sai da cabeca de quem foi pisado no stomp (vazio = nenhum). Ex.: bday_confetti, mini_fireworks");
    g_cvLacaioCrit  = CreateConVar("skynet_ff2_lacaio_critico", "0", "Summons (players who spawn to help the boss) can crit (0 = never)");
    g_cvPctStab     = CreateConVar("skynet_ff2_backstab_pct", "7", "Backstab no boss: % da vida cheia do boss (0 = dano do FF2)", _, true, 0.0, true, 100.0);
    g_cvPctStomp    = CreateConVar("skynet_ff2_stomp_pct", "5", "Stomp no boss: % da vida cheia do boss (0 = dano do FF2)", _, true, 0.0, true, 100.0);
    g_cvPctMarket   = CreateConVar("skynet_ff2_market_pct", "5", "Market Gardener no ar (rocket jump) no boss: % da vida cheia do boss (0 = dano normal)", _, true, 0.0, true, 100.0);
    CreateTimer(0.2, T_UberCrit, _, TIMER_REPEAT);
    AutoExecConfig(true, "skynet_ff2_extras");
    HookEvent("player_team", Ev_Silencia, EventHookMode_Pre);
    HookEvent("player_changeclass", Ev_Silencia, EventHookMode_Pre);
    g_fwStomp = new GlobalForward("OnStomp", ET_Event, Param_Cell, Param_Cell, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
    HookEvent("teamplay_round_win", Ev_FimRodada);
    HookEvent("player_shield_blocked", Ev_Bloqueio);
    HookEvent("post_inventory_application", Ev_Equipou);
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            OnClientPutInServer(i);
    static const char predios[][] = {"obj_sentrygun", "obj_dispenser", "obj_teleporter"};
    for (int k = 0; k < sizeof(predios); k++)
    {
        int e = -1;
        while ((e = FindEntityByClassname(e, predios[k])) != -1)
            SDKHook(e, SDKHook_OnTakeDamage, OnDanoPredio);
    }
    PrecacheSound(SOM_STOMP, true);     // reloaded mid-map: the sound is ready right away
    PrecacheConfete();
}

public void OnClientPutInServer(int client)
{
    g_fUltimoStomp[client] = 0.0;
    g_bNoAr[client] = false;
    g_bCritUber[client] = false;
    SDKHook(client, SDKHook_OnTakeDamage, OnDanoPre);
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnDano);
}

public void OnMapStart()
{
    PrecacheSound(SOM_STOMP, true);
    AddFileToDownloadsTable("sound/" ... SOM_STOMP);
    PrecacheConfete();
}

// the particle has to be in the "ParticleEffectNames" table for players to see it
void PrecacheConfete()
{
    char efeito[64];
    g_cvConfete.GetString(efeito, sizeof(efeito));
    if (!efeito[0])
        return;
    int t = FindStringTable("ParticleEffectNames");
    if (t == INVALID_STRING_TABLE || FindStringIndex(t, efeito) != INVALID_STRING_INDEX)
        return;
    bool trava = LockStringTables(false);
    AddToStringTable(t, efeito);
    LockStringTables(trava);
}

void Confete(int vit)
{
    char efeito[64];
    g_cvConfete.GetString(efeito, sizeof(efeito));
    if (!efeito[0])
        return;
    PrecacheConfete();
    float pos[3], maxs[3];
    GetClientAbsOrigin(vit, pos);
    GetEntPropVector(vit, Prop_Send, "m_vecMaxs", maxs);
    pos[2] += maxs[2];
    int p = CreateEntityByName("info_particle_system");
    if (p == -1)
        return;
    TeleportEntity(p, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(p, "effect_name", efeito);
    DispatchSpawn(p);
    ActivateEntity(p);
    AcceptEntityInput(p, "Start");
    SetVariantString("OnUser1 !self:Kill::4:1");
    AcceptEntityInput(p, "AddOutput");
    AcceptEntityInput(p, "FireUser1");
}

bool FF2Ativo()
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available;
}

bool EhBoss(int c)
{
    return c > 0 && c <= MaxClients && IsClientInGame(c) && FF2Ativo() && FF2R_GetBossData(c) != null;
}

// summon: a player on the boss team who is not a boss
bool EhLacaio(int c)
{
    if (c < 1 || c > MaxClients || !IsClientInGame(c) || !FF2Ativo() || EhBoss(c))
        return false;
    int t = GetClientTeam(c);
    for (int i = 1; i <= MaxClients; i++)
        if (i != c && IsClientInGame(i) && GetClientTeam(i) == t && EhBoss(i))
            return true;
    return false;
}

// the boss's total full health (one life x number of lives), for the % damages
float VidaCheia(int c)
{
    ConfigMap cfg = view_as<ConfigMap>(FF2R_GetBossData(c));
    int v, vidas;
    if (cfg == null || !cfg.GetInt("maxhealth", v) || v < 1)
        v = GetClientHealth(c);
    if (cfg == null || !cfg.GetInt("lives", vidas) || vidas < 1)
        vidas = 1;
    return float(v) * float(vidas);
}

bool SemCritLacaio(int c)
{
    return !g_cvLacaioCrit.BoolValue && EhLacaio(c);
}

bool EhCondCrit(TFCond cond)
{
    switch (view_as<int>(cond))
    {
        case 11, 33, 34, 37, 38, 39, 40, 44, 56:    // Kritzkrieged, crit candy, canteen, first blood, win, capture, kill, Mmmph, on damage
            return true;
    }
    return false;
}

public void F_TiraCritLacaio(DataPack dp)
{
    dp.Reset();
    int c = GetClientOfUserId(dp.ReadCell());
    TFCond cond = view_as<TFCond>(dp.ReadCell());
    delete dp;
    if (c && IsClientInGame(c) && TF2_IsPlayerInCondition(c, cond))
        TF2_RemoveCondition(c, cond);
}

// ---------------------------------------------------------------- team/class change notices on the server only
public Action Ev_Silencia(Event e, const char[] nome, bool sem)
{
    if (g_cvSilencia.BoolValue)
        e.BroadcastDisabled = true;
    return Plugin_Continue;
}

// ---------------------------------------------------------------- end-of-round sound
// FF2 blocks TF2's normal music and only plays the boss voice line (which does not play when the boss dies).
public void Ev_FimRodada(Event e, const char[] nome, bool sem)
{
    if (!g_cvSom.BoolValue || !FF2Ativo())
        return;
    int vencedor = e.GetInt("team");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        int t = GetClientTeam(i);
        if (vencedor < 2)
            EmitGameSoundToClient(i, "Game.Stalemate");
        else if (t == vencedor || t < 2)
            EmitGameSoundToClient(i, "Game.YourTeamWon");
        else
            EmitGameSoundToClient(i, "Game.YourTeamLost");
    }
}

// ---------------------------------------------------------------- boss hit on a building: fixed damage
public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "obj_sentrygun") || StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_teleporter"))
        SDKHook(entity, SDKHook_OnTakeDamage, OnDanoPredio);
}

public Action OnDanoPredio(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
                           float damageForce[3], float damagePosition[3], int damagecustom)
{
    if ((damagetype & DMG_CRIT) && SemCritLacaio(attacker))
    {
        damagetype &= ~DMG_CRIT;            // summon crit on a building: normal damage
        return Plugin_Changed;
    }
    float fixo = g_cvBossPredio.FloatValue;
    if (fixo <= 0.0 || attacker < 1 || attacker > MaxClients || !EhBoss(attacker))
        return Plugin_Continue;
    bool melee = (damagetype & DMG_CLUB) || (weapon > MaxClients && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee));
    if (!melee)
        return Plugin_Continue;
    damage = fixo;
    damagetype &= ~DMG_CRIT;
    return Plugin_Changed;
}

// ---------------------------------------------------------------- boss takes less knockback from damage
public void FF2R_OnBossCreated(int client, any cfg, bool setup)
{
    if (client > 0 && client <= MaxClients)
        CreateTimer(1.0, T_Empurrao, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void Ev_Equipou(Event e, const char[] nome, bool sem)
{
    CreateTimer(0.2, T_Empurrao, e.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_Empurrao(Handle t, int uid)
{
    int c = GetClientOfUserId(uid);
    if (c && IsClientInGame(c) && IsPlayerAlive(c) && EhBoss(c))
    {
        char codigo[128];
        FormatEx(codigo, sizeof(codigo), "self.AddCustomAttribute(\"damage force reduction\", %.2f, -1)", g_cvBossEmpurrao.FloatValue);
        SetVariantString(codigo);
        AcceptEntityInput(c, "RunScriptCode");
    }
    return Plugin_Stop;
}

// ---------------------------------------------------------------- the Medigun's normal uber also gives crits
public void TF2_OnConditionAdded(int client, TFCond cond)
{
    if (EhCondCrit(cond) && SemCritLacaio(client))
    {
        DataPack dp = new DataPack();
        dp.WriteCell(GetClientUserId(client));
        dp.WriteCell(view_as<int>(cond));
        RequestFrame(F_TiraCritLacaio, dp);
        return;
    }
}

// every 0.2 s: whoever is in the normal uber (Medic and patient) gets Kritz for a moment; it ends with the uber
public Action T_UberCrit(Handle t)
{
    if (!g_cvUberCrit.BoolValue || !FF2Ativo())
        return Plugin_Continue;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsClientInGame(c) && IsPlayerAlive(c) && TF2_IsPlayerInCondition(c, TFCond_Ubercharged) && !EhBoss(c) && !SemCritLacaio(c))
            TF2_AddCondition(c, TFCond_Kritzkrieged, 0.35);
    }
    return Plugin_Continue;
}

// ---------------------------------------------------------------- melee always crits (except the boss)
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
    if (SemCritLacaio(client))
    {
        if (!result)
            return Plugin_Continue;
        result = false;
        return Plugin_Changed;
    }
    if (!g_cvCrit.BoolValue || result || !FF2Ativo() || EhBoss(client))
        return Plugin_Continue;
    if (weapon > MaxClients && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
    {
        result = true;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

// ---------------------------------------------------------------- Sniper's Razorback: holds 1 boss hit and disappears
// FF2 already blocks the hit with the Razorback; the game would let it recharge and block again. Here it breaks for good.
public void Ev_Bloqueio(Event e, const char[] nome, bool sem)
{
    int v = e.GetInt("blocker_entindex");
    if (v >= 1 && v <= MaxClients && IsClientInGame(v))
        RequestFrame(F_TiraRazor, GetClientUserId(v));
}

public void F_TiraRazor(int uid)
{
    int c = GetClientOfUserId(uid);
    if (!c || !IsClientInGame(c))
        return;
    int e = -1;
    while ((e = FindEntityByClassname(e, "tf_wearable_razorback")) != -1)
    {
        if (GetEntPropEnt(e, Prop_Send, "m_hOwnerEntity") == c)
        {
            TF2_RemoveWearable(c, e);
            PrintCenterText(c, "Seu Razorback segurou o golpe do boss e quebrou!");
            break;
        }
    }
}

// ---------------------------------------------------------------- shields hold the boss's 1st hit
int AchaRazor(int client)
{
    int e = -1;
    while ((e = FindEntityByClassname(e, "tf_wearable_razorback")) != -1)
        if (GetEntPropEnt(e, Prop_Send, "m_hOwnerEntity") == client)
            return e;
    return -1;
}

int AchaEscudo(int client)
{
    int e = -1;
    while ((e = FindEntityByClassname(e, "tf_wearable_demoshield")) != -1)
        if (GetEntPropEnt(e, Prop_Send, "m_hOwnerEntity") == client)
            return e;
    e = -1;
    while ((e = FindEntityByClassname(e, "tf_wearable")) != -1)
        if (GetEntPropEnt(e, Prop_Send, "m_hOwnerEntity") == client && GetEntProp(e, Prop_Send, "m_iItemDefinitionIndex") == 231)
            return e;   // Darwin's Danger Shield
    return -1;
}

public Action OnDano(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
                     float damageForce[3], float damagePosition[3], int damagecustom)
{
    // backstab and Market Gardener in the air on the boss: fixed % of its full health (final damage, crit included)
    if (attacker >= 1 && attacker <= MaxClients && attacker != victim && damage > 0.0 && EhBoss(victim) && !EhBoss(attacker))
    {
        float pct = 0.0;
        if (damagecustom == TF_CUSTOM_BACKSTAB)
            pct = g_cvPctStab.FloatValue;
        else if (weapon > MaxClients && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")
                 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 416 && TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
            pct = g_cvPctMarket.FloatValue;
        if (pct > 0.0)
        {
            damage = VidaCheia(victim) * pct / 100.0;
            return Plugin_Changed;
        }
    }
    if (!g_cvEscudo.BoolValue || damage <= 0.0 || !(damagetype & (DMG_CLUB | DMG_SLASH)))
        return Plugin_Continue;
    if (!EhBoss(attacker) || EhBoss(victim))
        return Plugin_Continue;
    int escudo = AchaEscudo(victim);
    if (escudo == -1)
        return Plugin_Continue;
    damage *= 0.5;
    int vida = GetClientHealth(victim);
    if (damage >= float(vida))
        damage = vida > 1 ? float(vida - 1) : 0.0;
    TF2_RemoveWearable(victim, escudo);
    EmitGameSoundToAll("Player.Spy_Shield_Break", victim);
    PrintCenterText(victim, "Seu escudo segurou o golpe do boss e quebrou!");
    return Plugin_Changed;
}

// ---------------------------------------------------------------- sniper crits + falling on someone
public Action OnDanoPre(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
                        float damageForce[3], float damagePosition[3], int damagecustom)
{
    // Medic climb done by FF2 (15 self-damage, DMG_CLUB): charges the difference up to the Extras cost
    if (!g_bEscalando && victim == attacker && victim == inflictor && damagetype == DMG_CLUB && damage == ESCALAR_EMPURRA
        && g_cvEscalar.BoolValue && g_cvEscalarDano.FloatValue > ESCALAR_EMPURRA && TF2_GetPlayerClass(victim) == TFClass_Medic && !EhBoss(victim))
        RequestFrame(F_EscalaMedic, GetClientUserId(victim));
    if (damagetype & DMG_FALL)
    {
        if (!g_cvStomp.BoolValue)
            return Plugin_Continue;
        if (GetGameTime() - g_fUltimoStomp[victim] < 0.5)
        {
            damage = 0.0;
            return Plugin_Handled;          // just stomped someone: no fall damage
        }
        int alvo = Abaixo(victim);
        if (alvo && PodeStomp(victim, alvo))
        {
            g_fUltimoStomp[victim] = GetGameTime();
            DataPack dp = new DataPack();
            dp.WriteCell(GetClientUserId(victim));
            dp.WriteCell(GetClientUserId(alvo));
            RequestFrame(F_Stomp, dp);      // the stomp happens on the next frame, outside this damage
            damage = 0.0;
            return Plugin_Handled;
        }
        return Plugin_Continue;
    }
    if ((damagetype & DMG_CRIT) && attacker != victim && SemCritLacaio(attacker))
    {
        damagetype &= ~DMG_CRIT;            // summon crit: normal damage
        return Plugin_Changed;
    }
    if (g_cvSniper.BoolValue && !(damagetype & DMG_CRIT) && attacker >= 1 && attacker <= MaxClients && attacker != victim
        && weapon > MaxClients && IsValidEntity(weapon) && !EhBoss(attacker) && !SemCritLacaio(attacker) && IsClientInGame(attacker))
    {
        char cls[48];
        GetEntityClassname(weapon, cls, sizeof(cls));
        if (StrContains(cls, "tf_weapon_sniperrifle") == 0)
        {
            bool ok = TF2_IsPlayerInCondition(attacker, TFCond_Zoomed);
            if (!ok && StrEqual(cls, "tf_weapon_sniperrifle_classic") && HasEntProp(weapon, Prop_Send, "m_flChargedDamage"))
                ok = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") > 0.0;
            if (ok)
            {
                damagetype |= DMG_CRIT;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

// ---------------------------------------------------------------- stomp (goomba): landing on someone's head
// Player on boss: the boss takes 585 (FF2 Rewrite value) and the stomper bounces up.
// Boss on player: the player dies (their health + 50), the boss does not bounce.

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon,
                               int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if (!IsPlayerAlive(client))
    {
        g_bNoAr[client] = false;
        g_iArmaAnt[client] = 0;
        return;
    }
    Golpe(client);
    if (!g_cvStomp.BoolValue)
    {
        g_bNoAr[client] = false;
        return;
    }
    if (!(GetEntityFlags(client) & FL_ONGROUND))
    {
        float v[3];
        GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", v);
        g_bNoAr[client] = true;
        g_fVz[client] = v[2];
        return;
    }
    if (!g_bNoAr[client])
        return;
    g_bNoAr[client] = false;                // just landed
    if (g_fVz[client] > -g_cvStompVel.FloatValue)
        return;
    int alvo = Abaixo(client);
    if (alvo)
        Stomp(client, alvo);
}

// ---------------------------------------------------------------- melee wall climbing (same as FF2/VSH)
void Golpe(int client)
{
    int arma = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (arma <= MaxClients || arma != GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
    {
        g_iArmaAnt[client] = 0;
        return;
    }
    float prox = GetEntPropFloat(arma, Prop_Send, "m_flNextPrimaryAttack");
    bool golpeou = (arma == g_iArmaAnt[client] && prox > g_fProxAtq[client] + 0.01);
    g_iArmaAnt[client] = arma;
    g_fProxAtq[client] = prox;
    if (golpeou)
        Escalar(client);
}

public bool Filtro(int entity, int mask, int client)
{
    return entity != client;
}

bool BossEscala(int client)
{
    char lista[256], itens[16][48], nome[128], arq[128];
    g_cvEscalarBoss.GetString(lista, sizeof(lista));
    if (!lista[0])
        return false;
    ConfigMap cfg = view_as<ConfigMap>(FF2R_GetBossData(client));
    if (cfg == null)
        return false;
    cfg.Get("name", nome, sizeof(nome));
    cfg.Get("filename", arq, sizeof(arq));
    int n = ExplodeString(lista, ",", itens, sizeof(itens), sizeof(itens[]));
    for (int i = 0; i < n; i++)
    {
        TrimString(itens[i]);
        if (itens[i][0] && (StrContains(nome, itens[i], false) != -1 || StrContains(arq, itens[i], false) != -1))
            return true;
    }
    return false;
}

void Escalar(int client)
{
    if (!g_cvEscalar.BoolValue)
        return;
    bool boss = EhBoss(client);
    if (boss)
    {
        if (!BossEscala(client))
            return;
    }
    else
    {
        TFClassType c = TF2_GetPlayerClass(client);
        if (c != TFClass_DemoMan && c != TFClass_Spy && c != TFClass_Sniper && c != TFClass_Engineer && c != TFClass_Heavy)
            return;
    }
    float pos[3], ang[3], fim[3], normal[3];
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);
    Handle tr = TR_TraceRayFilterEx(pos, ang, MASK_SOLID, RayType_Infinite, Filtro, client);
    bool ok = false;
    if (TR_DidHit(tr) && TR_GetEntityIndex(tr) == 0)
    {
        TR_GetPlaneNormal(tr, normal);
        GetVectorAngles(normal, normal);
        TR_GetEndPosition(fim, tr);
        ok = (normal[0] < 30.0 || normal[0] > 330.0) && GetVectorDistance(pos, fim, true) < 10000.0;   // upright wall, within 100 units
    }
    delete tr;
    if (!ok)
        return;
    float v[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", v);
    v[2] = 600.0;
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, v);
    float dano = g_cvEscalarDano.FloatValue;
    if (dano > 0.0 && !boss)
    {
        float base = dano < ESCALAR_EMPURRA ? dano : ESCALAR_EMPURRA;
        g_bEscalando = true;
        SDKHooks_TakeDamage(client, client, client, base, DMG_CLUB, 0);
        if (dano > base && IsPlayerAlive(client))
            SDKHooks_TakeDamage(client, client, client, dano - base, DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE, 0);
        g_bEscalando = false;
    }
    ClientCommand(client, "playgamesound player/taunt_clip_spin.wav");
}

public void F_EscalaMedic(int uid)
{
    int c = GetClientOfUserId(uid);
    if (c && IsClientInGame(c) && IsPlayerAlive(c))
    {
        g_bEscalando = true;
        SDKHooks_TakeDamage(c, c, c, g_cvEscalarDano.FloatValue - ESCALAR_EMPURRA, DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE, 0);
        g_bEscalando = false;
    }
}

// enemy right below the feet (the "floor" is their head)
int Abaixo(int client)
{
    int chao = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
    if (chao >= 1 && chao <= MaxClients && chao != client && IsClientInGame(chao) && IsPlayerAlive(chao)
        && GetClientTeam(chao) != GetClientTeam(client))
        return chao;
    float pa[3], pv[3], maxs[3];
    GetClientAbsOrigin(client, pa);
    for (int v = 1; v <= MaxClients; v++)
    {
        if (v == client || !IsClientInGame(v) || !IsPlayerAlive(v) || GetClientTeam(v) == GetClientTeam(client))
            continue;
        GetClientAbsOrigin(v, pv);
        GetEntPropVector(v, Prop_Send, "m_vecMaxs", maxs);
        float dz = pa[2] - pv[2];
        float dx = pa[0] - pv[0], dy = pa[1] - pv[1];
        if (dz >= maxs[2] - 10.0 && dz <= maxs[2] + 24.0 && dx * dx + dy * dy <= 48.0 * 48.0)
            return v;
    }
    return 0;
}

bool PodeStomp(int atk, int vit)
{
    if (!FF2Ativo() || !IsPlayerAlive(atk) || !IsPlayerAlive(vit) || GetClientTeam(atk) == GetClientTeam(vit))
        return false;
    return EhBoss(atk) != EhBoss(vit);      // only player x boss or boss x player
}

public void F_Stomp(DataPack dp)
{
    dp.Reset();
    int atk = GetClientOfUserId(dp.ReadCell());
    int vit = GetClientOfUserId(dp.ReadCell());
    delete dp;
    if (atk && vit)
        Stomp(atk, vit, true);
}

bool Stomp(int atk, int vit, bool agendado = false)
{
    if (!g_cvStomp.BoolValue || !PodeStomp(atk, vit))
        return false;
    float agora = GetGameTime();
    if (!agendado && agora - g_fUltimoStomp[atk] < 0.5)
        return false;

    float mult = 1.0, bonus = 50.0, pulo = 300.0;   // default values of the Goomba Stomp plugin
    Action r = Plugin_Continue;
    Call_StartForward(g_fwStomp);                   // FF2 Rewrite adjusts it (OnStomp)
    Call_PushCell(atk);
    Call_PushCell(vit);
    Call_PushFloatRef(mult);
    Call_PushFloatRef(bonus);
    Call_PushFloatRef(pulo);
    Call_Finish(r);
    if (r == Plugin_Handled || r == Plugin_Stop)
        return false;                               // this boss does not accept stomps
    if (r != Plugin_Changed && EhBoss(vit))
    {
        mult = 0.0;
        bonus = g_cvStompDano.FloatValue;
        pulo = 450.0;
    }
    g_fUltimoStomp[atk] = agora;
    float dano = bonus + mult * float(GetClientHealth(vit));
    if (EhBoss(vit) && g_cvPctStomp.FloatValue > 0.0)
        dano = VidaCheia(vit) * g_cvPctStomp.FloatValue / 100.0;   // stomp on the boss: % of its full health
    int protecao = 0;                               // 1 = shield, 2 = Razorback: holds the boss stomp and breaks
    if (!EhBoss(vit) && g_cvEscudo.BoolValue)
    {
        int w = AchaEscudo(vit);
        protecao = 1;
        if (w == -1)
        {
            w = AchaRazor(vit);
            protecao = 2;
        }
        if (w == -1)
            protecao = 0;
        else
        {
            int vida = GetClientHealth(vit);
            int fica = vida - RoundToCeil(dano * 0.5);
            SetEntityHealth(vit, fica < 1 ? 1 : fica);      // half the damage and never kills
            TF2_RemoveWearable(vit, w);
            EmitGameSoundToAll("Player.Spy_Shield_Break", vit);
        }
    }
    if (protecao == 0)
        SDKHooks_TakeDamage(vit, atk, atk, dano, DMG_PREVENT_PHYSICS_FORCE | DMG_CRUSH);
    if (pulo > 0.0)
    {
        float v[3];
        GetEntPropVector(atk, Prop_Data, "m_vecAbsVelocity", v);
        v[2] = pulo;
        TeleportEntity(atk, NULL_VECTOR, NULL_VECTOR, v);
    }
    PrecacheSound(SOM_STOMP, true);
    int outros[MAXPLAYERS + 1], n = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i != atk && i != vit && IsClientInGame(i) && !IsFakeClient(i))
            outros[n++] = i;
    }
    // double volume: the sound plays 2 times together, on different channels (a single sound is already at max volume)
    if (n > 0)
    {
        EmitSound(outros, n, SOM_STOMP, vit, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
        EmitSound(outros, n, SOM_STOMP, vit, SNDCHAN_BODY, SNDLEVEL_SCREAMING);
    }
    if (!IsFakeClient(atk))
    {
        EmitSoundToClient(atk, SOM_STOMP, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE);
        EmitSoundToClient(atk, SOM_STOMP, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_NONE);
    }
    if (!IsFakeClient(vit))
    {
        EmitSoundToClient(vit, SOM_STOMP, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE);
        EmitSoundToClient(vit, SOM_STOMP, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_NONE);
    }
    Confete(vit);
    if (EhBoss(vit))
        PrintCenterText(atk, "STOMP! %.0f de dano no boss", dano);
    else if (protecao == 1)
        PrintCenterText(vit, "Seu escudo segurou o stomp do boss e quebrou!");
    else if (protecao == 2)
        PrintCenterText(vit, "Seu Razorback segurou o stomp do boss e quebrou!");
    else
        PrintCenterText(vit, "O boss pisou na sua cabeca!");
    return true;
}
