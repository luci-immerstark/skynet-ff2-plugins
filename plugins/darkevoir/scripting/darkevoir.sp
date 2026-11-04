// SKYNET: "darkevoir" remade (the original no longer exists online). Used by Michael Myers.
//   special_darkevoir (on rage): for arg1 seconds the boss ignores the players' protections (uber, bonk,
//   Vaccinator crit/blast/bullet/fire resistance, Battalion's): its hit removes the protection and lands.
#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "Freak Fortress 2: darkevoir (SKYNET)",
    author      = "SKYNET GAMING",
    description = "special_darkevoir: na furia o boss atravessa uber e outras protecoes",
    version     = "1.0.0",
};

float g_fAte[MAXPLAYERS + 1];

static const TFCond PROTECOES[] = {
    TFCond_Ubercharged, TFCond_UberchargedHidden, TFCond_UberchargedCanteen, TFCond_UberchargedOnTakeDamage,
    TFCond_Bonked, TFCond_UberBulletResist, TFCond_UberBlastResist, TFCond_UberFireResist,
    TFCond_BulletImmune, TFCond_BlastImmune, TFCond_FireImmune, TFCond_DefenseBuffed, TFCond_DefenseBuffNoCritBlock,
    TFCond_PreventDeath
};

public void OnPluginStart2()
{
    HookEvent("teamplay_round_start", Ev_Limpa, EventHookMode_PostNoCopy);
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            OnClientPutInServer(i);
}

public void OnClientPutInServer(int client)
{
    g_fAte[client] = 0.0;
    SDKHook(client, SDKHook_OnTakeDamage, OnDano);
}

public void Ev_Limpa(Event e, const char[] nome, bool sem)
{
    for (int i = 1; i <= MaxClients; i++)
        g_fAte[i] = 0.0;
}

public void FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    if (!StrEqual(ability_name, "special_darkevoir"))
        return;
    int client = GetClientOfUserId(FF2_GetBossUserId(boss));
    if (client <= 0 || !IsClientInGame(client))
        return;
    g_fAte[client] = GetGameTime() + FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 8.0);
}

public Action OnDano(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (attacker < 1 || attacker > MaxClients || attacker == victim || g_fAte[attacker] < GetGameTime())
        return Plugin_Continue;
    if (!IsClientInGame(attacker) || !IsClientInGame(victim) || GetClientTeam(attacker) == GetClientTeam(victim))
        return Plugin_Continue;
    for (int i = 0; i < sizeof(PROTECOES); i++)
        if (TF2_IsPlayerInCondition(victim, PROTECOES[i]))
            TF2_RemoveCondition(victim, PROTECOES[i]);
    return Plugin_Continue;
}
