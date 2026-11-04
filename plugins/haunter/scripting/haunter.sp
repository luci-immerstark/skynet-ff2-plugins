// SKYNET: "haunter" refeito (o original sumiu da internet). Usado por SCP-106, Lewis The Ghost e Walrider.
//   Habilidade special_haunter (na furia):
//     arg1 = duracao do modo fantasma (atravessa paredes + brilho), arg2 = velocidade no modo fantasma,
//     arg3 = aceleracao no modo fantasma, arg4 = duracao do susto (stun), arg5 = raio do susto
//   Ao ativar: assusta (stun de fantasma) os inimigos no raio e o boss vira fantasma. Ao acabar, se ele ficou
//   dentro de uma parede, volta para o ultimo lugar livre por onde passou.
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "Freak Fortress 2: haunter (SKYNET)",
    author      = "SKYNET GAMING",
    description = "special_haunter: modo fantasma + susto",
    version     = "1.0.0",
};

#define HAUNTER "special_haunter"

float g_fFim[MAXPLAYERS + 1];
float g_fLivre[MAXPLAYERS + 1][3];
Handle g_hTimer[MAXPLAYERS + 1];
ConVar g_cvSpeed, g_cvAccel;
float g_fSpeedOrig, g_fAccelOrig;
int g_iAtivos;

public void OnPluginStart2()
{
    g_cvSpeed = FindConVar("sv_noclipspeed");
    g_cvAccel = FindConVar("sv_noclipaccelerate");
    HookEvent("teamplay_round_start", Ev_Limpa, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", Ev_Limpa, EventHookMode_PostNoCopy);
    HookEvent("player_death", Ev_Morte);
}

public void OnMapEnd()
{
    for (int i = 1; i <= MaxClients; i++)
        g_hTimer[i] = null;
    g_iAtivos = 0;
}

public void FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    if (!StrEqual(ability_name, HAUNTER))
        return;
    int client = GetClientOfUserId(FF2_GetBossUserId(boss));
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || g_hTimer[client] != null)
        return;

    float dur = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 10.0);
    float vel = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, 2.0);
    float acel = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 3, 10.0);
    float stun = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 4, 3.0);
    float raio = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 5, 1000.0);

    // susto nos inimigos perto
    float pb[3], pv[3];
    GetClientAbsOrigin(client, pb);
    int time = GetClientTeam(client);
    for (int v = 1; v <= MaxClients; v++)
    {
        if (v == client || !IsClientInGame(v) || !IsPlayerAlive(v) || GetClientTeam(v) == time)
            continue;
        GetClientAbsOrigin(v, pv);
        if (stun > 0.0 && GetVectorDistance(pb, pv) <= raio)
            TF2_StunPlayer(v, stun, 0.0, TF_STUNFLAGS_GHOSTSCARE, client);
    }

    // modo fantasma
    if (g_iAtivos == 0 && g_cvSpeed != null && g_cvAccel != null)
    {
        g_fSpeedOrig = g_cvSpeed.FloatValue;
        g_fAccelOrig = g_cvAccel.FloatValue;
    }
    g_iAtivos++;
    if (g_cvSpeed != null && vel > 0.0)
        g_cvSpeed.FloatValue = vel;
    if (g_cvAccel != null && acel > 0.0)
        g_cvAccel.FloatValue = acel;
    g_fLivre[client] = pb;
    g_fFim[client] = GetGameTime() + dur;
    SetEntityMoveType(client, MOVETYPE_NOCLIP);
    SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
    g_hTimer[client] = CreateTimer(0.1, T_Fantasma, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

bool Preso(int client, const float pos[3])
{
    float mins[3], maxs[3];
    GetClientMins(client, mins);
    GetClientMaxs(client, maxs);
    TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, F_SoMundo, client);
    return TR_DidHit();
}

public bool F_SoMundo(int ent, int mask, int client)
{
    return ent == 0 || ent > MaxClients;     // so parede/objetos, nao jogadores
}

public Action T_Fantasma(Handle t, int uid)
{
    int client = GetClientOfUserId(uid);
    if (client <= 0)
    {
        Desliga(0);
        return Plugin_Stop;
    }
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
    {
        g_hTimer[client] = null;
        Termina(client, false);
        return Plugin_Stop;
    }
    float pos[3];
    GetClientAbsOrigin(client, pos);
    if (!Preso(client, pos))
        g_fLivre[client] = pos;
    if (GetGameTime() >= g_fFim[client])
    {
        g_hTimer[client] = null;
        Termina(client, true);
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

void Termina(int client, bool vivo)
{
    if (vivo && IsClientInGame(client))
    {
        SetEntityMoveType(client, MOVETYPE_WALK);
        SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
        float pos[3];
        GetClientAbsOrigin(client, pos);
        if (Preso(client, pos))
            TeleportEntity(client, g_fLivre[client], NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
    }
    Desliga(client);
}

void Desliga(int client)
{
    if (g_iAtivos > 0)
        g_iAtivos--;
    if (g_iAtivos == 0)
    {
        if (g_cvSpeed != null && g_fSpeedOrig > 0.0)
            g_cvSpeed.FloatValue = g_fSpeedOrig;
        if (g_cvAccel != null && g_fAccelOrig > 0.0)
            g_cvAccel.FloatValue = g_fAccelOrig;
    }
}

public void OnClientDisconnect(int client)
{
    if (g_hTimer[client] != null)
    {
        KillTimer(g_hTimer[client]);
        g_hTimer[client] = null;
        Desliga(client);
    }
}

public void Ev_Morte(Event e, const char[] nome, bool sem)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    if (client > 0 && g_hTimer[client] != null)
    {
        KillTimer(g_hTimer[client]);
        g_hTimer[client] = null;
        SetEntityMoveType(client, MOVETYPE_WALK);
        SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
        Desliga(client);
    }
}

public void Ev_Limpa(Event e, const char[] nome, bool sem)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hTimer[i] != null)
        {
            KillTimer(g_hTimer[i]);
            g_hTimer[i] = null;
            if (IsClientInGame(i))
            {
                SetEntityMoveType(i, MOVETYPE_WALK);
                SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
            }
        }
    }
    g_iAtivos = 1;
    Desliga(0);
}
