// SKYNET Taunt Crit: whoever finishes a taunt gets crits for 5 seconds. One at a time: taunting during the crits does not stack.
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Taunt Crit",
    author      = "SKYNET GAMING",
    description = "Taunt da critico por alguns segundos (um por vez)",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native any FF2R_GetBossData(int client);

ConVar g_cvTempo, g_cvMin, g_cvBoss;
float g_fInicio[MAXPLAYERS + 1], g_fFim[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvTempo = CreateConVar("skynet_tauntcrit_tempo", "5", "Segundos de critico depois de uma taunt", _, true, 0.0, true, 30.0);
    g_cvMin   = CreateConVar("skynet_tauntcrit_minimo", "1.5", "A taunt precisa durar pelo menos isso (s) para valer (evita cancelar a taunt na hora)", _, true, 0.0, true, 10.0);
    g_cvBoss  = CreateConVar("skynet_tauntcrit_boss", "0", "1 = o boss do FF2 tambem ganha critico com taunt");
    AutoExecConfig(true, "skynet_tauntcrit");
}

public void OnClientDisconnect(int client)
{
    g_fInicio[client] = 0.0;
    g_fFim[client] = 0.0;
}

bool EhBoss(int c)
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available && FF2R_GetBossData(c);
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
    if (cond == TFCond_Taunting)
        g_fInicio[client] = GetGameTime();
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
    if (cond != TFCond_Taunting || g_cvTempo.FloatValue <= 0.0)
        return;
    if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;
    if (!g_cvBoss.BoolValue && EhBoss(client))
        return;
    float agora = GetGameTime();
    if (agora - g_fInicio[client] < g_cvMin.FloatValue)
        return;                 // taunt cancelled right at the start
    if (agora < g_fFim[client])
        return;                 // already has crits: one at a time
    float t = g_cvTempo.FloatValue;
    TF2_AddCondition(client, TFCond_CritCanteen, t);
    g_fFim[client] = agora + t;
    PrintCenterText(client, "CRITICO por %.0f segundos!", t);
}
