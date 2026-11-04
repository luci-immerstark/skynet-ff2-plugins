// SKYNET FF2 Sem Arma: o boss nao pega arma do chao.
// No TF2 a arma caida e pega com a tecla de chamar o Medic, que e a mesma tecla do rage do boss; por isso a tecla
// nao e bloqueada. Em vez disso, arma caida perto de um boss vivo some antes que ele consiga pegar.
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Sem Arma",
    author      = "SKYNET GAMING",
    description = "FF2: o boss nao pega arma do chao",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native Handle FF2R_GetBossData(int client);

ConVar g_cvRaio;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvRaio = CreateConVar("skynet_ff2_semarma_raio", "300", "Arma caida a esta distancia (unidades) de um boss vivo some", _, true, 50.0);
    CreateTimer(0.1, T_Varre, _, TIMER_REPEAT);
}

bool EhBoss(int c)
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available && FF2R_GetBossData(c) != null;
}

bool PertoDeBoss(int e)
{
    float p[3], b[3];
    GetEntPropVector(e, Prop_Data, "m_vecAbsOrigin", p);
    float r = g_cvRaio.FloatValue;
    r *= r;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsClientInGame(c) && IsPlayerAlive(c) && EhBoss(c))
        {
            GetClientAbsOrigin(c, b);
            if (GetVectorDistance(p, b, true) <= r)
                return true;
        }
    }
    return false;
}

public void OnEntityCreated(int e, const char[] classe)
{
    if (StrEqual(classe, "tf_dropped_weapon"))
        RequestFrame(F_Nova, EntIndexToEntRef(e));
}

public void F_Nova(int ref)
{
    int e = EntRefToEntIndex(ref);
    if (e > MaxClients && PertoDeBoss(e))
        RemoveEntity(e);
}

public Action T_Varre(Handle t)
{
    int e = -1;
    while ((e = FindEntityByClassname(e, "tf_dropped_weapon")) != -1)
    {
        if (PertoDeBoss(e))
            RemoveEntity(e);
    }
    return Plugin_Continue;
}
