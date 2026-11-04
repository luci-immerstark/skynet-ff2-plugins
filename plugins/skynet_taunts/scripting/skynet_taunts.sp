#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1
#pragma newdecls required

#define MAX_TAUNTS 256
#define TODAS_AS_CLASSES 1022

public Plugin myinfo =
{
    name = "SKYNET Taunts",
    author = "SKYNET GAMING",
    description = "Menu !taunt com todas as taunts do jogo (lista em configs/skynet_taunts.txt)",
    version = "1.0",
    url = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

int g_Id[MAX_TAUNTS];
int g_Mask[MAX_TAUNTS];
char g_Name[MAX_TAUNTS][64];
int g_Count;
float g_Next[MAXPLAYERS + 1];
ConVar g_cvEnabled, g_cvCooldown;

public void OnPluginStart()
{
    g_cvEnabled  = CreateConVar("skynet_taunts_enabled", "1", "Liga (1) ou desliga (0) o comando !taunt", _, true, 0.0, true, 1.0);
    g_cvCooldown = CreateConVar("skynet_taunts_cooldown", "3", "Segundos de espera entre uma taunt e outra", _, true, 0.0);
    AutoExecConfig(true, "skynet_taunts");

    RegConsoleCmd("sm_taunt", Cmd_Taunt, "Abre o menu de taunts");
    RegConsoleCmd("sm_taunts", Cmd_Taunt, "Abre o menu de taunts");
    RegAdminCmd("sm_taunts_reload", Cmd_Reload, ADMFLAG_CONFIG, "Recarrega a lista de taunts");

    LoadTaunts();
}

public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; i++)
        g_Next[i] = 0.0;
}

public void OnClientPutInServer(int client)
{
    g_Next[client] = 0.0;
}

void LoadTaunts()
{
    g_Count = 0;
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/skynet_taunts.txt");
    KeyValues kv = new KeyValues("SkynetTaunts");
    if (!kv.ImportFromFile(path))
    {
        LogError("Lista de taunts nao encontrada: %s", path);
        delete kv;
        return;
    }
    if (kv.GotoFirstSubKey())
    {
        do
        {
            if (g_Count >= MAX_TAUNTS)
                break;
            char sec[16];
            kv.GetSectionName(sec, sizeof(sec));
            g_Id[g_Count] = StringToInt(sec);
            if (g_Id[g_Count] <= 0)
                continue;
            kv.GetString("name", g_Name[g_Count], sizeof(g_Name[]), sec);
            g_Mask[g_Count] = kv.GetNum("classes", TODAS_AS_CLASSES);
            g_Count++;
        } while (kv.GotoNextKey());
    }
    delete kv;
}

public Action Cmd_Reload(int client, int args)
{
    LoadTaunts();
    ReplyToCommand(client, "[SKYNET] Taunts carregadas: %d", g_Count);
    return Plugin_Handled;
}

public Action Cmd_Taunt(int client, int args)
{
    if (client < 1 || !IsClientInGame(client))
    {
        ReplyToCommand(client, "[SKYNET] Este comando so funciona dentro do jogo.");
        return Plugin_Handled;
    }
    if (!g_cvEnabled.BoolValue)
    {
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 O menu de taunts está desligado no momento.");
        return Plugin_Handled;
    }
    if (args >= 1)
    {
        char arg[16];
        GetCmdArg(1, arg, sizeof(arg));
        int id = StringToInt(arg);
        for (int i = 0; i < g_Count; i++)
        {
            if (g_Id[i] == id)
            {
                DoTaunt(client, i);
                return Plugin_Handled;
            }
        }
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 Taunt não encontrada. Digite \x0700E5FF!taunt\x01 para ver o menu.");
        return Plugin_Handled;
    }
    ShowTauntMenu(client, 0);
    return Plugin_Handled;
}

void ShowTauntMenu(int client, int first)
{
    TFClassType cls = TF2_GetPlayerClass(client);
    if (cls == TFClass_Unknown)
    {
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 Escolha uma classe antes de usar o \x0700E5FF!taunt\x01.");
        return;
    }
    int bit = 1 << view_as<int>(cls);
    Menu menu = new Menu(Handler_Taunt);
    menu.SetTitle("Taunts (as da sua classe vêm primeiro)");
    char info[8];
    // Passo 0: taunts exclusivas da classe. Passo 1: taunts de todas as classes.
    for (int passo = 0; passo < 2; passo++)
    {
        for (int i = 0; i < g_Count; i++)
        {
            bool todas = (g_Mask[i] & TODAS_AS_CLASSES) == TODAS_AS_CLASSES;
            if ((passo == 0) == todas)
                continue;
            if ((g_Mask[i] & bit) == 0)
                continue;
            IntToString(i, info, sizeof(info));
            menu.AddItem(info, g_Name[i]);
        }
    }
    if (menu.ItemCount == 0)
    {
        delete menu;
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 Nenhuma taunt disponível.");
        return;
    }
    menu.DisplayAt(client, first, 30);
}

public int Handler_Taunt(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(item, info, sizeof(info));
        DoTaunt(client, StringToInt(info));
        ShowTauntMenu(client, GetMenuSelectionPosition());
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void DoTaunt(int client, int idx)
{
    if (idx < 0 || idx >= g_Count || !IsClientInGame(client))
        return;
    if (!g_cvEnabled.BoolValue)
        return;
    if (!IsPlayerAlive(client) || GetClientTeam(client) < 2)
    {
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 Você precisa estar vivo para usar uma taunt.");
        return;
    }
    int bit = 1 << view_as<int>(TF2_GetPlayerClass(client));
    if ((g_Mask[idx] & bit) == 0)
    {
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 Essa taunt não é da sua classe.");
        return;
    }
    float agora = GetGameTime();
    if (agora < g_Next[client])
    {
        PrintToChat(client, "\x07FFD700[SKYNET GAMING]\x01 Aguarde um instante para usar outra taunt.");
        return;
    }
    g_Next[client] = agora + g_cvCooldown.FloatValue;

    // Usa o proprio sistema de scripts do jogo (VScript): cria um item temporario com o
    // codigo da taunt, manda o jogador provocar e apaga o item em seguida.
    char code[1024];
    FormatEx(code, sizeof(code),
        "local w=Entities.CreateByClassname(\"tf_weapon_bat\");local a=self.GetActiveWeapon();self.StopTaunt(true);self.RemoveCond(7);w.DispatchSpawn();NetProps.SetPropInt(w,\"m_AttributeManager.m_Item.m_iItemDefinitionIndex\",%d);NetProps.SetPropBool(w,\"m_AttributeManager.m_Item.m_bInitialized\",true);NetProps.SetPropBool(w,\"m_bForcePurgeFixedupStrings\",true);NetProps.SetPropEntity(self,\"m_hActiveWeapon\",w);NetProps.SetPropInt(self,\"m_iFOV\",0);self.HandleTauntCommand(0);NetProps.SetPropEntity(self,\"m_hActiveWeapon\",a);w.Kill()",
        g_Id[idx]);
    SetVariantString(code);
    AcceptEntityInput(client, "RunScriptCode");
}
