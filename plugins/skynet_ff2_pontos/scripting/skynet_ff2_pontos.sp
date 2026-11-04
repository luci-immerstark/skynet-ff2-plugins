// SKYNET FF2 Pontos: pontuacao do ranking (HLstatsZ) do Freak Fortress 2, entregue no fim de cada rodada.
//   Vitoria como boss: +30 para cada boss (dupla: cada um ganha 30; minions invocados nao contam).
//   Vitoria contra o boss: +10 para cada jogador do time que venceu (que estava na rodada).
//   Dano no boss: +1 a cada 1000 de dano (somado na rodada, entregue e mostrado no chat no fim).
//   (A kill vale +1 direto no daemon do ranking.) Os pontos vao para o ranking pelas acoes ff2_boss_vitoria (30),
//   ff2_vitoria (10) e ff2_dano (1, uma por cada 1000 de dano), registradas no log do jogo como as do proprio TF2.
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
    CreateTimer(0.5, T_Marca, _, TIMER_FLAG_NO_MAPCHANGE);    // depois do FF2 montar os bosses
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
