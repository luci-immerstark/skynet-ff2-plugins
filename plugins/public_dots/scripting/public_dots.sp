// SKYNET: "public_dots" refeito (o original nao existe mais na internet). Habilidades de "drain over time" (DOT):
//   dot_weapon_swap  - enquanto o DOT esta ligado troca a arma (arg1 nome, arg2 indice, arg3 atributos, arg4 visivel);
//                      ao desligar volta para a outra (arg5..arg8)
//   dot_model_swap   - enquanto o DOT esta ligado troca o modelo do boss (arg1); ao desligar volta o original
//   dot_teleport     - ao ligar, teleporta para um inimigo aleatorio ate arg1 de distancia (arg2 som de falha,
//                      arg3 particula na saida, arg4 particula na chegada, arg5 som)
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <drain_over_time>
#include <drain_over_time_subplugin>

public Plugin:myinfo =
{
    name        = "Freak Fortress 2: public_dots (SKYNET)",
    author      = "SKYNET GAMING",
    description = "dot_weapon_swap, dot_model_swap e dot_teleport",
    version     = "1.0.0",
};

new bool:g_Ativo;
new bool:WS_Pode[MAXPLAYERS + 1];
new bool:MS_Pode[MAXPLAYERS + 1];
new bool:TP_Pode[MAXPLAYERS + 1];
new String:MS_Original[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

public OnPluginStart2()
{
    HookEvent("arena_win_panel", Ev_Fim, EventHookMode_PostNoCopy);
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status)
{
    return Plugin_Continue;
}

public Ev_Fim(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_Ativo = false;
    for (new i = 1; i <= MaxClients; i++)
    {
        WS_Pode[i] = false;
        MS_Pode[i] = false;
        TP_Pode[i] = false;
    }
}

DOTPostRoundStartInit()
{
    g_Ativo = false;
    for (new c = 1; c <= MaxClients; c++)
    {
        WS_Pode[c] = false;
        MS_Pode[c] = false;
        TP_Pode[c] = false;
        if (!IsClientInGame(c) || !IsPlayerAlive(c))
            continue;
        new boss = FF2_GetBossIndex(c);
        if (boss < 0)
            continue;
        WS_Pode[c] = FF2_HasAbility(boss, this_plugin_name, "dot_weapon_swap");
        MS_Pode[c] = FF2_HasAbility(boss, this_plugin_name, "dot_model_swap");
        TP_Pode[c] = FF2_HasAbility(boss, this_plugin_name, "dot_teleport");
        if (MS_Pode[c])
        {
            new String:m[PLATFORM_MAX_PATH];
            FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_model_swap", 1, m, sizeof(m));
            ReplaceString(m, sizeof(m), "\\", "/");
            if (strlen(m) > 3)
                PrecacheModel(m);
            GetEntPropString(c, Prop_Send, "m_iszCustomModel", MS_Original[c], PLATFORM_MAX_PATH);
        }
        if (TP_Pode[c])
        {
            new String:s[PLATFORM_MAX_PATH];
            FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_teleport", 2, s, sizeof(s));
            if (strlen(s) > 3) PrecacheSound(s);
            FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_teleport", 5, s, sizeof(s));
            if (strlen(s) > 3) PrecacheSound(s);
        }
        if (WS_Pode[c] || MS_Pode[c] || TP_Pode[c])
            g_Ativo = true;
    }
}

TrocaArma(client, boss, primeiro)
{
    new String:nome[64], String:atr[256];
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_weapon_swap", primeiro, nome, sizeof(nome));
    new indice = FF2_GetAbilityArgument(boss, this_plugin_name, "dot_weapon_swap", primeiro + 1);
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_weapon_swap", primeiro + 2, atr, sizeof(atr));
    new visivel = FF2_GetAbilityArgument(boss, this_plugin_name, "dot_weapon_swap", primeiro + 3, 1);
    if (!nome[0])
        return;
    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
    new arma = CriaArma(client, nome, indice, atr, visivel);
    if (arma > MaxClients)
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", arma);
}

CriaArma(client, String:nome[], indice, String:atr[], visivel)
{
    new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
    TF2Items_SetClassname(item, nome);
    TF2Items_SetItemIndex(item, indice);
    TF2Items_SetLevel(item, 101);
    TF2Items_SetQuality(item, 5);
    new String:partes[32][32];
    new n = ExplodeString(atr, ";", partes, 32, 32);
    if (n % 2)
        n--;
    TF2Items_SetNumAttributes(item, n / 2);
    for (new i = 0, a = 0; i < n; i += 2, a++)
    {
        TrimString(partes[i]);
        TrimString(partes[i + 1]);
        TF2Items_SetAttribute(item, a, StringToInt(partes[i]), StringToFloat(partes[i + 1]));
    }
    new arma = TF2Items_GiveNamedItem(client, item);
    CloseHandle(item);
    if (arma > MaxClients)
    {
        EquipPlayerWeapon(client, arma);
        if (!visivel)
        {
            SetEntProp(arma, Prop_Send, "m_iWorldModelIndex", -1);
            SetEntPropFloat(arma, Prop_Send, "m_flModelScale", 0.001);
        }
    }
    return arma;
}

Particula(const Float:pos[3], const String:efeito[])
{
    if (strlen(efeito) < 2)
        return;
    new p = CreateEntityByName("info_particle_system");
    if (p == -1)
        return;
    TeleportEntity(p, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(p, "effect_name", efeito);
    DispatchSpawn(p);
    ActivateEntity(p);
    AcceptEntityInput(p, "Start");
    SetVariantString("OnUser1 !self:Kill::3:1");
    AcceptEntityInput(p, "AddOutput");
    AcceptEntityInput(p, "FireUser1");
}

bool:Teleporta(client, boss)
{
    new Float:dist = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "dot_teleport", 1, 3000.0);
    new String:s[PLATFORM_MAX_PATH];
    new Float:pb[3], Float:pv[3];
    GetClientAbsOrigin(client, pb);
    new alvos[MAXPLAYERS + 1], n = 0;
    for (new v = 1; v <= MaxClients; v++)
    {
        if (v == client || !IsClientInGame(v) || !IsPlayerAlive(v) || GetClientTeam(v) == GetClientTeam(client))
            continue;
        GetClientAbsOrigin(v, pv);
        if (GetVectorDistance(pb, pv) <= dist)
            alvos[n++] = v;
    }
    if (!n)
    {
        FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_teleport", 2, s, sizeof(s));
        if (strlen(s) > 3)
            EmitSoundToClient(client, s);
        return false;
    }
    new alvo = alvos[GetRandomInt(0, n - 1)];
    GetClientAbsOrigin(alvo, pv);
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_teleport", 3, s, sizeof(s));
    Particula(pb, s);
    // abaixado, para caber no lugar do alvo sem ficar preso
    SetEntProp(client, Prop_Send, "m_bDucked", 1);
    SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
    TeleportEntity(client, pv, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_teleport", 4, s, sizeof(s));
    Particula(pv, s);
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_teleport", 5, s, sizeof(s));
    if (strlen(s) > 3)
        EmitSoundToAll(s, client);
    return true;
}

OnDOTAbilityActivated(clientIdx)
{
    if (!g_Ativo || !IsClientInGame(clientIdx) || !IsPlayerAlive(clientIdx))
        return;
    new boss = FF2_GetBossIndex(clientIdx);
    if (boss < 0)
        return;
    if (WS_Pode[clientIdx])
        TrocaArma(clientIdx, boss, 1);
    if (MS_Pode[clientIdx])
    {
        new String:m[PLATFORM_MAX_PATH];
        FF2_GetAbilityArgumentString(boss, this_plugin_name, "dot_model_swap", 1, m, sizeof(m));
        ReplaceString(m, sizeof(m), "\\", "/");
        if (strlen(m) > 3)
        {
            SetVariantString(m);
            AcceptEntityInput(clientIdx, "SetCustomModel");
            SetEntProp(clientIdx, Prop_Send, "m_bUseClassAnimations", 1);
        }
    }
    if (TP_Pode[clientIdx])
        Teleporta(clientIdx, boss);
}

OnDOTAbilityDeactivated(clientIdx)
{
    if (!g_Ativo || !IsClientInGame(clientIdx) || !IsPlayerAlive(clientIdx))
        return;
    new boss = FF2_GetBossIndex(clientIdx);
    if (boss < 0)
        return;
    if (WS_Pode[clientIdx])
        TrocaArma(clientIdx, boss, 5);
    if (MS_Pode[clientIdx] && strlen(MS_Original[clientIdx]) > 3)
    {
        SetVariantString(MS_Original[clientIdx]);
        AcceptEntityInput(clientIdx, "SetCustomModel");
        SetEntProp(clientIdx, Prop_Send, "m_bUseClassAnimations", 1);
    }
}

OnDOTAbilityTick(clientIdx, tickCount)
{
}

OnDOTUserDeath(clientIdx, isInGame)
{
}
