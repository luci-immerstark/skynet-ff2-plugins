// SKYNET FF2 Points: Freak Fortress 2 ranking points (HLstatsZ), given at the end of each round.
//   Win as boss: +30 for each boss (duo: each one gets 30; summoned minions do not count).
//   Win against the boss: +10 for each player on the winning team (who was in the round).
//   Damage to the boss: +1 per 1000 damage (added up over the round, given and shown in chat at the end).
//   (A kill is worth +1 directly in the ranking daemon.) The points reach the ranking through the actions ff2_boss_vitoria (30),
//   ff2_vitoria (10) and ff2_dano (1, one per 1000 damage), recorded in the game log like TF2's own.
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Pontos",
    author      = "SKYNET GAMING",
    description = "Pontos do ranking do FF2: vitoria de boss, vitoria contra o boss e dano",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native Handle FF2R_GetBossData(int client);

bool g_bBoss[MAXPLAYERS + 1];
bool g_bJogou[MAXPLAYERS + 1];
int g_iDano[MAXPLAYERS + 1];
int g_iTimeBoss;
bool g_bRodada;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("arena_round_start", Ev_Inicio, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", Ev_Fim);
    HookEvent("player_hurt", Ev_Dano);
}

public void OnMapStart()
{
    g_bRodada = false;
}

public void OnClientDisconnect(int c)
{
    g_bBoss[c] = false;
    g_bJogou[c] = false;
    g_iDano[c] = 0;
}

bool EhBoss(int c)
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available && FF2R_GetBossData(c) != null;
}

public void Ev_Inicio(Event e, const char[] nome, bool sem)
{
    for (int c = 1; c <= MaxClients; c++)
    {
        g_bBoss[c] = false;
        g_bJogou[c] = false;
        g_iDano[c] = 0;
    }
    g_iTimeBoss = 0;
    g_bRodada = true;
    CreateTimer(0.5, T_Marca, _, TIMER_FLAG_NO_MAPCHANGE);    // after FF2 sets up the bosses
}

public Action T_Marca(Handle t)
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!IsClientInGame(c) || GetClientTeam(c) < 2)
            continue;
        g_bJogou[c] = true;
        if (EhBoss(c))
        {
            g_bBoss[c] = true;
            g_iTimeBoss = GetClientTeam(c);
        }
    }
    return Plugin_Stop;
}

public void Ev_Dano(Event e, const char[] nome, bool sem)
{
    if (!g_bRodada)
        return;
    int vit = GetClientOfUserId(e.GetInt("userid"));
    int atk = GetClientOfUserId(e.GetInt("attacker"));
    if (vit < 1 || atk < 1 || vit == atk || !g_bBoss[vit] || g_bBoss[atk] || !IsClientInGame(atk) || GetClientTeam(atk) == GetClientTeam(vit))
        return;
    g_iDano[atk] += e.GetInt("damageamount");
    g_bJogou[atk] = true;
}

void Acao(int c, const char[] acao, int vezes = 1)
{
    char auth[64], time[32];
    if (!GetClientAuthId(c, AuthId_Engine, auth, sizeof(auth)))
        return;
    GetTeamName(GetClientTeam(c), time, sizeof(time));
    for (int i = 0; i < vezes; i++)
        LogToGame("\"%N<%d><%s><%s>\" triggered \"%s\"", c, GetClientUserId(c), auth, time, acao);
}

public void Ev_Fim(Event e, const char[] nome, bool sem)
{
    if (!g_bRodada || !g_iTimeBoss)
        return;
    g_bRodada = false;
    int venceu = e.GetInt("team");
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!IsClientInGame(c) || IsFakeClient(c) || !g_bJogou[c])
            continue;
        int total = 0;
        char msg[192];
        msg[0] = '\0';
        if (g_bBoss[c])
        {
            if (venceu == g_iTimeBoss)
            {
                Acao(c, "ff2_boss_vitoria");
                total += 30;
                StrCat(msg, sizeof(msg), " | vitoria como boss +30");
            }
        }
        else if (venceu > 1 && venceu != g_iTimeBoss && GetClientTeam(c) == venceu)
        {
            Acao(c, "ff2_vitoria");
            total += 10;
            StrCat(msg, sizeof(msg), " | vitoria contra o boss +10");
        }
        int pd = g_iDano[c] / 1000;
        if (pd > 0)
        {
            Acao(c, "ff2_dano", pd);
            total += pd;
            Format(msg, sizeof(msg), "%s | dano no boss %d = +%d", msg, g_iDano[c], pd);
        }
        if (total > 0)
            PrintToChat(c, "\x07FFD700[SKYNET]\x01 Pontos da rodada: \x0700FF00+%d\x01%s", total, msg);
        else if (g_iDano[c] > 0)
            PrintToChat(c, "\x07FFD700[SKYNET]\x01 Dano no boss: %d (cada 1000 de dano vale 1 ponto no ranking)", g_iDano[c]);
    }
}
