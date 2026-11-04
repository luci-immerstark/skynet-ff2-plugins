// SKYNET Sprays: spray moderation (replacing Super Spray Handler, which is old and has no source).
//   !quemspray / sm_spraytrace  - aim at a spray: shows who made it and how long ago (admins/moderators)
//   sm_sprayban <player>        - blocks the player's sprays (saved; the current spray disappears on map change)
//   sm_sprayunban <player>      - allows them again
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Sprays",
    author      = "SKYNET GAMING",
    description = "Ver de quem e o spray e bloquear sprays ofensivos",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

Cookie g_ckBan;
bool g_bBan[MAXPLAYERS + 1];
bool g_bTem[MAXPLAYERS + 1];
float g_fPos[MAXPLAYERS + 1][3];
float g_fQuando[MAXPLAYERS + 1];
float g_fAviso[MAXPLAYERS + 1];

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    g_ckBan = new Cookie("skynet_spray_ban", "Sprays bloqueados", CookieAccess_Private);
    RegAdminCmd("sm_spraytrace", Cmd_Trace, ADMFLAG_GENERIC, "Mostra de quem e o spray na sua mira");
    RegAdminCmd("sm_quemspray", Cmd_Trace, ADMFLAG_GENERIC, "Mostra de quem e o spray na sua mira");
    RegAdminCmd("sm_sprayban", Cmd_Ban, ADMFLAG_GENERIC, "sm_sprayban <jogador>: bloqueia os sprays");
    RegAdminCmd("sm_sprayunban", Cmd_Unban, ADMFLAG_GENERIC, "sm_sprayunban <jogador>: libera os sprays");
    AddTempEntHook("Player Decal", TE_Spray);
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && AreClientCookiesCached(c))
            OnClientCookiesCached(c);
}

public void OnMapStart()
{
    for (int c = 0; c <= MaxClients; c++)
        g_bTem[c] = false;
}

public void OnClientConnected(int c)
{
    g_bBan[c] = false;
    g_bTem[c] = false;
}

public void OnClientCookiesCached(int c)
{
    char v[4];
    g_ckBan.Get(c, v, sizeof(v));
    g_bBan[c] = v[0] == '1';
}

public Action TE_Spray(const char[] te, const int[] jogadores, int n, float atraso)
{
    int c = TE_ReadNum("m_nPlayer");
    if (c < 1 || c > MaxClients || !IsClientInGame(c))
        return Plugin_Continue;
    if (g_bBan[c])
    {
        if (GetGameTime() > g_fAviso[c])
        {
            g_fAviso[c] = GetGameTime() + 10.0;
            PrintToChat(c, "[SKYNET] Seus sprays estao bloqueados neste servidor.");
        }
        return Plugin_Stop;
    }
    TE_ReadVector("m_vecOrigin", g_fPos[c]);
    g_fQuando[c] = GetGameTime();
    g_bTem[c] = true;
    return Plugin_Continue;
}

public bool F_Mundo(int ent, int mask)
{
    return ent == 0 || ent > MaxClients;
}

public Action Cmd_Trace(int c, int args)
{
    if (!c || !IsClientInGame(c))
        return Plugin_Handled;
    float olho[3], ang[3], fim[3];
    GetClientEyePosition(c, olho);
    GetClientEyeAngles(c, ang);
    TR_TraceRayFilter(olho, ang, MASK_SOLID_BRUSHONLY, RayType_Infinite, F_Mundo);
    if (!TR_DidHit())
    {
        ReplyToCommand(c, "[SKYNET] Mire numa parede com spray.");
        return Plugin_Handled;
    }
    TR_GetEndPosition(fim);
    int dono = 0;
    float melhor = 48.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!g_bTem[i] || !IsClientInGame(i))
            continue;
        float d = GetVectorDistance(fim, g_fPos[i]);
        if (d < melhor)
        {
            melhor = d;
            dono = i;
        }
    }
    if (!dono)
    {
        ReplyToCommand(c, "[SKYNET] Nenhum spray de quem esta no servidor nesse lugar.");
        return Plugin_Handled;
    }
    char id[32];
    if (!GetClientAuthId(dono, AuthId_Steam2, id, sizeof(id)))
        strcopy(id, sizeof(id), "?");
    int seg = RoundToFloor(GetGameTime() - g_fQuando[dono]);
    ReplyToCommand(c, "[SKYNET] Spray de %N (%s), feito ha %d min %d s. Para bloquear: sm_sprayban #%d", dono, id, seg / 60, seg % 60, GetClientUserId(dono));
    return Plugin_Handled;
}

public Action Cmd_Ban(int c, int args)
{
    return Muda(c, args, true);
}

public Action Cmd_Unban(int c, int args)
{
    return Muda(c, args, false);
}

Action Muda(int c, int args, bool ban)
{
    if (args < 1)
    {
        ReplyToCommand(c, "[SKYNET] Uso: %s <jogador>", ban ? "sm_sprayban" : "sm_sprayunban");
        return Plugin_Handled;
    }
    char arg[64];
    GetCmdArg(1, arg, sizeof(arg));
    int alvo = FindTarget(c, arg, true, false);
    if (alvo == -1)
        return Plugin_Handled;
    g_bBan[alvo] = ban;
    if (AreClientCookiesCached(alvo))
        g_ckBan.Set(alvo, ban ? "1" : "");
    if (ban)
        g_bTem[alvo] = false;
    ShowActivity2(c, "[SKYNET] ", "%s os sprays de %N.", ban ? "bloqueou" : "liberou", alvo);
    LogAction(c, alvo, "\"%L\" %s os sprays de \"%L\"", c, ban ? "bloqueou" : "liberou", alvo);
    return Plugin_Handled;
}
