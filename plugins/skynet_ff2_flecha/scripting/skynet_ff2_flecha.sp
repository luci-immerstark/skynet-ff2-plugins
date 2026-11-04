// SKYNET FF2 Flecha Explosiva: a flecha da besta do Medic (Crusader's Crossbow) explode ao acertar parede ou inimigo.
//   Dano em area nos inimigos (o dano conta para o Medic), menor na borda da explosao, sem atravessar parede.
//   So para os jogadores contra o boss (boss e minions nao ganham). Flecha em aliado continua so curando.
//   Cvars: skynet_ff2_flecha (1 liga), skynet_ff2_flecha_dano (300), skynet_ff2_flecha_raio (150),
//          skynet_ff2_flecha_borda (0.5 = na borda faz metade), skynet_ff2_flecha_empurra (0 = nao empurra),
//          skynet_ff2_flecha_max (250 = teto de cada flechada em cada alvo: acerto direto + explosao, ja com critico).
// 1.1.0: teto por flechada. Antes o acerto direto da flecha somava com a explosao (e critico/mini-critico subiam
//   mais ainda), passando de 400 no boss. Agora a soma das duas, ja com todos os bonus, nao passa do teto.
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Flecha Explosiva",
    author      = "SKYNET GAMING",
    description = "FF2: a flecha da besta do Medic explode",
    version     = "1.1.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

#define SOM_EXPLOSAO "weapons/explode1.wav"

native Handle FF2R_GetBossData(int client);

ConVar g_cvLiga, g_cvDano, g_cvRaio, g_cvBorda, g_cvEmpurra, g_cvMax;
bool g_bExplodiu[2049];
float g_fDireto[MAXPLAYERS + 1][MAXPLAYERS + 1];    // [atirador][alvo]: dano do acerto direto da ultima flecha
float g_fDiretoT[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iExpAlvo;                                    // alvo da explosao em andamento (0 = nenhuma)
float g_fExpLimite;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvLiga    = CreateConVar("skynet_ff2_flecha", "1", "Flecha do Medic explode (1 = sim)", _, true, 0.0, true, 1.0);
    g_cvDano    = CreateConVar("skynet_ff2_flecha_dano", "300", "Dano da explosao no centro", _, true, 0.0, true, 5000.0);
    g_cvRaio    = CreateConVar("skynet_ff2_flecha_raio", "150", "Raio da explosao", _, true, 10.0, true, 1000.0);
    g_cvBorda   = CreateConVar("skynet_ff2_flecha_borda", "0.5", "Fracao do dano na borda da explosao (1 = igual em toda a area)", _, true, 0.0, true, 1.0);
    g_cvEmpurra = CreateConVar("skynet_ff2_flecha_empurra", "0", "A explosao empurra (1 = sim)", _, true, 0.0, true, 1.0);
    g_cvMax     = CreateConVar("skynet_ff2_flecha_max", "250", "Dano maximo de cada flechada em cada alvo (acerto direto + explosao, ja com critico; 0 = sem teto)", _, true, 0.0, true, 5000.0);
    AutoExecConfig(true, "skynet_ff2_flecha");
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamageAlive, OnDanoVivo);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnDanoVivo);
}

// Dano final (depois de critico, mini-critico e bonus do FF2): segura o teto da flechada
public Action OnDanoVivo(int v, int &atk, int &inf, float &dano, int &tipo, int &arma, float forca[3], float pos[3], int custom)
{
    float teto = g_cvMax.FloatValue;
    if (teto <= 0.0)
        return Plugin_Continue;
    if (g_iExpAlvo == v)
    {
        if (dano > g_fExpLimite)
        {
            dano = g_fExpLimite;
            return Plugin_Changed;
        }
        return Plugin_Continue;
    }
    if (inf <= MaxClients || atk < 1 || atk > MaxClients || atk == v || !IsValidEntity(inf))
        return Plugin_Continue;
    char cls[40];
    GetEntityClassname(inf, cls, sizeof(cls));
    if (!StrEqual(cls, "tf_projectile_healing_bolt") || !IsClientInGame(atk) || GetClientTeam(atk) == GetClientTeam(v) || !FF2Ativo() || EhBoss(atk))
        return Plugin_Continue;
    float agora = GetGameTime();
    if (agora - g_fDiretoT[atk][v] > 0.3)
        g_fDireto[atk][v] = 0.0;
    float resta = teto - g_fDireto[atk][v];
    if (resta < 0.0)
        resta = 0.0;
    bool mudou = dano > resta;
    if (mudou)
        dano = resta;
    g_fDireto[atk][v] += dano;
    g_fDiretoT[atk][v] = agora;
    return mudou ? Plugin_Changed : Plugin_Continue;
}

public void OnMapStart()
{
    PrecacheSound(SOM_EXPLOSAO, true);
}

bool FF2Ativo()
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available;
}

bool EhBoss(int c)
{
    return c > 0 && c <= MaxClients && IsClientInGame(c) && FF2R_GetBossData(c) != null;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity > MaxClients && entity < sizeof(g_bExplodiu) && StrEqual(classname, "tf_projectile_healing_bolt"))
    {
        g_bExplodiu[entity] = false;
        SDKHook(entity, SDKHook_StartTouch, OnToque);
    }
}

public Action OnToque(int flecha, int outro)
{
    if (g_bExplodiu[flecha] || !g_cvLiga.BoolValue || !FF2Ativo())
        return Plugin_Continue;
    int dono = GetEntPropEnt(flecha, Prop_Send, "m_hOwnerEntity");
    if (dono < 1 || dono > MaxClients || !IsClientInGame(dono) || EhBoss(dono))
        return Plugin_Continue;
    if (outro >= 1 && outro <= MaxClients && GetClientTeam(outro) == GetClientTeam(dono))
        return Plugin_Continue;                     // aliado: so cura
    if (outro > MaxClients)
    {
        char cls[32];
        GetEntityClassname(outro, cls, sizeof(cls));
        if (StrContains(cls, "trigger_") == 0 || StrContains(cls, "func_respawnroom") == 0)
            return Plugin_Continue;                 // gatilhos invisiveis do mapa nao contam
    }
    g_bExplodiu[flecha] = true;
    float pos[3];
    GetEntPropVector(flecha, Prop_Data, "m_vecAbsOrigin", pos);
    DataPack dp = new DataPack();
    dp.WriteCell(GetClientUserId(dono));
    dp.WriteFloat(pos[0]);
    dp.WriteFloat(pos[1]);
    dp.WriteFloat(pos[2]);
    RequestFrame(F_Explode, dp);                    // fora do toque, no proximo frame
    return Plugin_Continue;
}

public bool F_SoMundo(int ent, int mask, any dado)
{
    return ent == 0 || ent > MaxClients;
}

public void F_Explode(DataPack dp)
{
    dp.Reset();
    int dono = GetClientOfUserId(dp.ReadCell());
    float pos[3];
    pos[0] = dp.ReadFloat();
    pos[1] = dp.ReadFloat();
    pos[2] = dp.ReadFloat();
    delete dp;
    if (!dono || !IsClientInGame(dono))
        return;

    Efeito(pos);
    float raio = g_cvRaio.FloatValue, dano = g_cvDano.FloatValue, borda = g_cvBorda.FloatValue;
    int tipo = DMG_BLAST;
    if (!g_cvEmpurra.BoolValue)
        tipo |= DMG_PREVENT_PHYSICS_FORCE;
    int time = GetClientTeam(dono);
    float alvo[3];
    for (int v = 1; v <= MaxClients; v++)
    {
        if (v == dono || !IsClientInGame(v) || !IsPlayerAlive(v) || GetClientTeam(v) == time)
            continue;
        GetClientAbsOrigin(v, alvo);
        alvo[2] += 40.0;                            // meio do corpo
        float dist = GetVectorDistance(pos, alvo);
        if (dist > raio)
            continue;
        TR_TraceRayFilter(pos, alvo, MASK_SOLID, RayType_EndPoint, F_SoMundo);
        if (TR_DidHit())
            continue;                               // parede no meio
        float d = dano * (1.0 - (1.0 - borda) * dist / raio);
        float limite = d;
        float teto = g_cvMax.FloatValue;
        if (teto > 0.0)
        {
            float usado = GetGameTime() - g_fDiretoT[dono][v] <= 0.3 ? g_fDireto[dono][v] : 0.0;
            float resta = teto - usado;
            if (resta <= 0.0)
                continue;                           // o acerto direto ja chegou no teto
            if (limite > resta)
                limite = resta;
            if (d > limite)
                d = limite;
        }
        g_iExpAlvo = v;
        g_fExpLimite = limite;
        if (g_cvEmpurra.BoolValue)
        {
            float forca[3];
            MakeVectorFromPoints(pos, alvo, forca);
            NormalizeVector(forca, forca);
            ScaleVector(forca, d * 6.0);
            SDKHooks_TakeDamage(v, dono, dono, d, tipo, -1, forca, pos);
        }
        else
            SDKHooks_TakeDamage(v, dono, dono, d, tipo, -1, NULL_VECTOR, pos);
        g_iExpAlvo = 0;
    }
}

void Efeito(const float pos[3])
{
    int p = CreateEntityByName("info_particle_system");
    if (p != -1)
    {
        TeleportEntity(p, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(p, "effect_name", "ExplosionCore_MidAir");
        DispatchSpawn(p);
        ActivateEntity(p);
        AcceptEntityInput(p, "Start");
        SetVariantString("OnUser1 !self:Kill::3:1");
        AcceptEntityInput(p, "AddOutput");
        AcceptEntityInput(p, "FireUser1");
    }
    EmitAmbientSound(SOM_EXPLOSAO, pos, SOUND_FROM_WORLD, SNDLEVEL_GUNFIRE);
}
