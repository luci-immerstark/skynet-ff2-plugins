// SKYNET Dissolve: refeito do "Dissolve" (L. Duke, 2008; o .smx antigo nao tem codigo e ficava escrevendo
//   "[DISSOLVE] Could not get ragdoll" no console). O corpo de quem morre se dissolve (efeito de energia do HL2).
//   Melhorias: nao dissolve a morte falsa do Dead Ringer (entregaria o Spy), nao mexe em quem ja renasceu, sem spam.
//   Cvars (mesmos nomes do original): sm_dissolve (1 liga), sm_dissolve_delay (segundos, 2), sm_dissolve_type (0-3).
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Dissolve",
    author      = "SKYNET GAMING (ideia original: L. Duke)",
    description = "Os corpos dos mortos se dissolvem",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

ConVar g_cvLiga, g_cvDelay, g_cvTipo;

public void OnPluginStart()
{
    g_cvLiga  = CreateConVar("sm_dissolve", "1", "Corpos se dissolvem (1 = sim)", _, true, 0.0, true, 1.0);
    g_cvDelay = CreateConVar("sm_dissolve_delay", "2.0", "Segundos depois da morte para o corpo dissolver", _, true, 0.0, true, 30.0);
    g_cvTipo  = CreateConVar("sm_dissolve_type", "0", "0 = energia, 1 = energia leve, 2 = energia forte, 3 = rapido", _, true, 0.0, true, 3.0);
    AutoExecConfig(true, "skynet_dissolve");
    HookEvent("player_death", Ev_Morte);
}

public void Ev_Morte(Event e, const char[] nome, bool sem)
{
    if (!g_cvLiga.BoolValue || (e.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
        return;
    float d = g_cvDelay.FloatValue;
    CreateTimer(d < 0.1 ? 0.1 : d, T_Dissolve, e.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_Dissolve(Handle t, int uid)
{
    int c = GetClientOfUserId(uid);
    if (!c || !IsClientInGame(c) || IsPlayerAlive(c))
        return Plugin_Stop;
    int corpo = GetEntPropEnt(c, Prop_Send, "m_hRagdoll");
    if (corpo <= MaxClients || !IsValidEntity(corpo))
        return Plugin_Stop;                 // sem corpo (explodiu em pedacos, por exemplo)
    int dis = CreateEntityByName("env_entity_dissolver");
    if (dis == -1)
        return Plugin_Stop;
    char alvo[32], tipo[4];
    FormatEx(alvo, sizeof(alvo), "skdis_%d", corpo);
    IntToString(g_cvTipo.IntValue, tipo, sizeof(tipo));
    DispatchKeyValue(corpo, "targetname", alvo);
    DispatchKeyValue(dis, "dissolvetype", tipo);
    DispatchKeyValue(dis, "target", alvo);
    AcceptEntityInput(dis, "Dissolve");
    AcceptEntityInput(dis, "Kill");
    return Plugin_Stop;
}
