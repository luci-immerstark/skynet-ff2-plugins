// SKYNET Amplificador (refeito do "The Amplifier" 2.4, de 2010: codigo antigo que nao compila mais e trocava o modelo
//   do dispenser, o que quebra a animacao de construcao). Aqui o Engineer escolhe em !amp e o dispenser que ele
//   construir vira um Amplificador: em vez de curar/dar municao, da CRITICO aos aliados perto (anel colorido mostra o
//   alcance). Cada aliado gasta metal do Amplificador por segundo; o metal regenera sozinho.
//   Sabotado, sendo construido ou carregado, nao funciona. Spy disfarcado ou invisivel nao recebe (para nao se entregar).
//   Cvars: skynet_amp (1 liga), skynet_amp_cond (33 = critico; 16 = mini-critico), skynet_amp_raio (200),
//          skynet_amp_metal_uso (5 por aliado/s), skynet_amp_metal_regen (15/s), skynet_amp_metal_max (400),
//          skynet_amp_parede (1 = nao passa por parede).
// 1.1.0: visual do Amplificador original (modelo, texturas e pedacos ao ser destruido). O dispenser e construido
//   normalmente e, quando fica pronto, vira o modelo do Amplificador (com o efeito de teleporte). Nao sobe de nivel.
//   Os arquivos sao baixados pelos jogadores na troca de mapa: instalado no meio do mapa, o modelo so aparece no
//   proximo mapa (antes disso fica o dispenser colorido, para ninguem ver ERROR).
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Amplificador",
    author      = "SKYNET GAMING (ideia: The Amplifier, RainBolt Dash)",
    description = "Dispenser vira Amplificador: da critico aos aliados perto",
    version     = "1.1.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native Handle FF2R_GetBossData(int client);

#define AMP_MDL "models/buildables/amplifier_test/amplifier.mdl"
static const char MAT[][] = { "amplifier", "amplifier_anim", "amplifier_anim2", "amplifier_anim2_blue", "amplifier_anim_blue",
                              "amplifier_blue", "amplifier_bolt", "amplifier_holo", "amplifier_holo_blue", "amplifier_radar" };
static const char EXT[][] = { ".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy" };
bool g_bTarde, g_bModelo;

ConVar g_cvLiga, g_cvCond, g_cvRaio, g_cvUso, g_cvRegen, g_cvMax, g_cvParede;
Cookie g_ckAmp;
bool g_bQuer[MAXPLAYERS + 1];
bool g_bAmp[2049];
float g_fDica[MAXPLAYERS + 1];
int g_iLaser, g_iHalo;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bTarde = late;
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvLiga   = CreateConVar("skynet_amp", "1", "Amplificador ligado (1 = sim)", _, true, 0.0, true, 1.0);
    g_cvCond   = CreateConVar("skynet_amp_cond", "33", "Condicao dada (33 = critico, 16 = mini-critico)", _, true, 0.0, true, 130.0);
    g_cvRaio   = CreateConVar("skynet_amp_raio", "200", "Alcance do Amplificador", _, true, 50.0, true, 1000.0);
    g_cvUso    = CreateConVar("skynet_amp_metal_uso", "5", "Metal gasto por aliado por segundo", _, true, 0.0, true, 100.0);
    g_cvRegen  = CreateConVar("skynet_amp_metal_regen", "15", "Metal que o Amplificador regenera por segundo", _, true, 0.0, true, 400.0);
    g_cvMax    = CreateConVar("skynet_amp_metal_max", "400", "Metal maximo do Amplificador", _, true, 1.0, true, 400.0);
    g_cvParede = CreateConVar("skynet_amp_parede", "1", "1 = o efeito nao passa por parede", _, true, 0.0, true, 1.0);
    AutoExecConfig(true, "skynet_amp");
    g_ckAmp = new Cookie("skynet_amp", "Dispenser vira Amplificador", CookieAccess_Protected);
    RegConsoleCmd("sm_amp", Cmd_Amp, "Liga/desliga: seu dispenser vira Amplificador (da critico)");
    RegConsoleCmd("sm_amplificador", Cmd_Amp, "Liga/desliga: seu dispenser vira Amplificador (da critico)");
    HookEvent("player_builtobject", Ev_Construiu);
    CreateTimer(1.0, T_Amp, _, TIMER_REPEAT);
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && AreClientCookiesCached(c))
            OnClientCookiesCached(c);
}

public void OnMapStart()
{
    g_iLaser = PrecacheModel("materials/sprites/laser.vmt");
    g_iHalo = PrecacheModel("materials/sprites/halo01.vmt");
    g_bModelo = false;
    if (!FileExists(AMP_MDL, true))
        return;
    char a[PLATFORM_MAX_PATH];
    for (int e = 0; e < sizeof(EXT); e++)
    {
        FormatEx(a, sizeof(a), "models/buildables/amplifier_test/amplifier%s", EXT[e]);
        AddFileToDownloadsTable(a);
        for (int g = 1; g <= 8; g++)
        {
            FormatEx(a, sizeof(a), "models/buildables/amplifier_test/gibs/amp_gib%d%s", g, EXT[e]);
            AddFileToDownloadsTable(a);
        }
    }
    for (int m = 0; m < sizeof(MAT); m++)
    {
        FormatEx(a, sizeof(a), "materials/models/buildables/amplifier_test/%s.vmt", MAT[m]);
        AddFileToDownloadsTable(a);
        FormatEx(a, sizeof(a), "materials/models/buildables/amplifier_test/%s.vtf", MAT[m]);
        AddFileToDownloadsTable(a);
    }
    PrecacheModel(AMP_MDL, true);
    for (int g = 1; g <= 8; g++)
    {
        FormatEx(a, sizeof(a), "models/buildables/amplifier_test/gibs/amp_gib%d.mdl", g);
        PrecacheModel(a, true);
    }
    g_bModelo = !g_bTarde;      // instalado no meio do mapa: quem esta jogando ainda nao baixou o modelo
    g_bTarde = false;
}

void Particula(int ent, const char[] efeito)
{
    int p = CreateEntityByName("info_particle_system");
    if (p == -1)
        return;
    float pos[3];
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
    TeleportEntity(p, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(p, "effect_name", efeito);
    DispatchSpawn(p);
    ActivateEntity(p);
    AcceptEntityInput(p, "Start");
    SetVariantString("OnUser1 !self:Kill::2:1");
    AcceptEntityInput(p, "AddOutput");
    AcceptEntityInput(p, "FireUser1");
}

public void OnClientCookiesCached(int c)
{
    char v[4];
    g_ckAmp.Get(c, v, sizeof(v));
    g_bQuer[c] = v[0] == '1';
}

public void OnClientDisconnect(int c)
{
    g_bQuer[c] = false;
}

public void OnEntityDestroyed(int ent)
{
    if (ent > 0 && ent < sizeof(g_bAmp))
        g_bAmp[ent] = false;
}

bool EhBoss(int c)
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available && FF2R_GetBossData(c) != null;
}

public Action Cmd_Amp(int c, int args)
{
    if (!c || !IsClientInGame(c))
        return Plugin_Handled;
    g_bQuer[c] = !g_bQuer[c];
    if (AreClientCookiesCached(c))
        g_ckAmp.Set(c, g_bQuer[c] ? "1" : "0");
    PrintToChat(c, g_bQuer[c] ? "[SKYNET] Amplificador LIGADO: o proximo dispenser que voce construir da critico aos aliados perto (nao cura)."
                              : "[SKYNET] Amplificador DESLIGADO: seus dispensers voltam ao normal.");
    return Plugin_Handled;
}

public void Ev_Construiu(Event e, const char[] nome, bool sem)
{
    if (view_as<TFObjectType>(e.GetInt("object")) != TFObject_Dispenser)
        return;
    int c = GetClientOfUserId(e.GetInt("userid"));
    int ent = e.GetInt("index");
    if (!c || ent <= MaxClients || ent >= sizeof(g_bAmp) || !IsValidEntity(ent))
        return;
    if (!g_cvLiga.BoolValue || !g_bQuer[c] || EhBoss(c))
    {
        if (g_cvLiga.BoolValue && !g_bQuer[c] && GetGameTime() > g_fDica[c])
        {
            g_fDica[c] = GetGameTime() + 300.0;
            PrintToChat(c, "[SKYNET] Dica: digite !amp e seu dispenser vira um Amplificador (critico para os aliados perto).");
        }
        return;
    }
    g_bAmp[ent] = true;
    SetEntProp(ent, Prop_Send, "m_bDisabled", 1);       // nao cura nem da municao
    if (g_bModelo)
        SetEntityRenderColor(ent, 255, 255, 255, 255);
    else if (GetClientTeam(c) == view_as<int>(TFTeam_Red))
        SetEntityRenderColor(ent, 255, 120, 60, 255);
    else
        SetEntityRenderColor(ent, 90, 150, 255, 255);
    PrintToChat(c, "[SKYNET] Amplificador construido: aliados perto ganham critico enquanto ele tiver metal.");
}

public bool F_Mundo(int ent, int mask, any amp)
{
    return ent == 0 || (ent > MaxClients && ent != amp);
}

public Action T_Amp(Handle t)
{
    if (!g_cvLiga.BoolValue)
        return Plugin_Continue;
    TFCond cond = view_as<TFCond>(g_cvCond.IntValue);
    float raio = g_cvRaio.FloatValue;
    int uso = g_cvUso.IntValue, regen = g_cvRegen.IntValue, max = g_cvMax.IntValue;
    float pa[3], pc[3];
    int cor[4];
    for (int ent = MaxClients + 1; ent < sizeof(g_bAmp); ent++)
    {
        if (!g_bAmp[ent] || !IsValidEntity(ent))
            continue;
        if (GetEntProp(ent, Prop_Send, "m_bBuilding") || GetEntProp(ent, Prop_Send, "m_bCarried") || GetEntProp(ent, Prop_Send, "m_bPlacing"))
            continue;
        SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
        SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", 0);      // nao sobe de nivel (manteria o modelo de dispenser)
        if (g_bModelo && GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") >= 1.0)
        {
            char mdl[PLATFORM_MAX_PATH];
            GetEntPropString(ent, Prop_Data, "m_ModelName", mdl, sizeof(mdl));
            if (!StrEqual(mdl, AMP_MDL))
            {
                SetEntityModel(ent, AMP_MDL);
                Particula(ent, GetEntProp(ent, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Red) ? "teleported_red" : "teleported_blue");
            }
        }
        int metal = GetEntProp(ent, Prop_Send, "m_iAmmoMetal");
        metal = metal + regen > max ? max : metal + regen;
        if (GetEntProp(ent, Prop_Send, "m_bHasSapper"))
        {
            SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);
            continue;
        }
        int time = GetEntProp(ent, Prop_Send, "m_iTeamNum");
        int dono = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
        if (dono < 1 || dono > MaxClients || !IsClientInGame(dono))
            dono = 0;
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pa);
        pa[2] += 40.0;
        for (int c = 1; c <= MaxClients; c++)
        {
            if (metal < uso || !IsClientInGame(c) || !IsPlayerAlive(c) || GetClientTeam(c) != time || EhBoss(c))
                continue;
            if (TF2_IsPlayerInCondition(c, TFCond_Cloaked) || TF2_IsPlayerInCondition(c, TFCond_Disguised))
                continue;
            GetClientAbsOrigin(c, pc);
            pc[2] += 40.0;
            if (GetVectorDistance(pa, pc) > raio)
                continue;
            if (g_cvParede.BoolValue)
            {
                TR_TraceRayFilter(pa, pc, MASK_SOLID, RayType_EndPoint, F_Mundo, ent);
                if (TR_DidHit())
                    continue;
            }
            TF2_AddCondition(c, cond, 1.2, dono);
            metal -= uso;
        }
        SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);
        cor[3] = 160;
        if (time == view_as<int>(TFTeam_Red)) { cor[0] = 255; cor[1] = 90; cor[2] = 40; }
        else { cor[0] = 60; cor[1] = 120; cor[2] = 255; }
        pa[2] -= 30.0;
        TE_SetupBeamRingPoint(pa, raio * 2.0 - 10.0, raio * 2.0, g_iLaser, g_iHalo, 0, 15, 1.0, 4.0, 0.0, cor, 10, 0);
        TE_SendToAll();
    }
    return Plugin_Continue;
}
