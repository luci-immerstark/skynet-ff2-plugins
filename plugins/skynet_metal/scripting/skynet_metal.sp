// SKYNET Metal Regen: the Engineer gains metal little by little (in FF2 he spends the round running, with no time to fetch metal).
//   Cvars: skynet_metal (1 = on), skynet_metal_qtd (5 each time), skynet_metal_intervalo (1.0 s), skynet_metal_max (200).
//   In FF2, the boss does not get it.
// 1.0.1: 5 metal per second by default (was 10).
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Metal Regen",
    author      = "SKYNET GAMING",
    description = "Engineer regenera metal aos poucos",
    version     = "1.0.1",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

#define AMMO_METAL 3

native Handle FF2R_GetBossData(int client);

ConVar g_cvLiga, g_cvQtd, g_cvIntervalo, g_cvMax;
Handle g_hTimer;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvLiga      = CreateConVar("skynet_metal", "1", "Engineer regenera metal (1 = sim)", _, true, 0.0, true, 1.0);
    g_cvQtd       = CreateConVar("skynet_metal_qtd", "5", "Metal ganho por vez", _, true, 1.0, true, 200.0);
    g_cvIntervalo = CreateConVar("skynet_metal_intervalo", "1.0", "Segundos entre cada ganho", _, true, 0.1, true, 30.0);
    g_cvMax       = CreateConVar("skynet_metal_max", "200", "Metal maximo que a regeneracao enche", _, true, 1.0, true, 1000.0);
    g_cvIntervalo.AddChangeHook(OnIntervalo);
    AutoExecConfig(true, "skynet_metal");
}

public void OnConfigsExecuted()
{
    Reinicia();
}

public void OnIntervalo(ConVar cv, const char[] velho, const char[] novo)
{
    Reinicia();
}

void Reinicia()
{
    delete g_hTimer;
    g_hTimer = CreateTimer(g_cvIntervalo.FloatValue, T_Metal, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
    g_hTimer = null;    // timers without the map flag keep running; this one is recreated in OnConfigsExecuted
}

bool EhBoss(int c)
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available && FF2R_GetBossData(c) != null;
}

public Action T_Metal(Handle t)
{
    if (t != g_hTimer)
        return Plugin_Stop;
    if (!g_cvLiga.BoolValue)
        return Plugin_Continue;
    int qtd = g_cvQtd.IntValue, max = g_cvMax.IntValue;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!IsClientInGame(c) || !IsPlayerAlive(c) || TF2_GetPlayerClass(c) != TFClass_Engineer || EhBoss(c))
            continue;
        int metal = GetEntProp(c, Prop_Send, "m_iAmmo", _, AMMO_METAL);
        if (metal < max)
            SetEntProp(c, Prop_Send, "m_iAmmo", metal + qtd > max ? max : metal + qtd, _, AMMO_METAL);
    }
    return Plugin_Continue;
}
