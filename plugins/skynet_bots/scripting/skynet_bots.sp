// SKYNET Test Bots: admins and moderators add and remove bots for testing (!bots or admin menu)
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Bots de Teste",
    author      = "SKYNET GAMING",
    description = "!bots: menu para colocar 1, 3, 5 ou 10 bots de teste e tirar todos",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

#define PREFIXO "TESTE"

ConVar g_cvAtivos;      // how many test bots exist (Dodgeball Auto Reflect pauses while it is > 0)
int g_iSeq;
TopMenu g_Menu;

public void OnPluginStart()
{
    g_cvAtivos = CreateConVar("skynet_bots_teste", "0", "Bots de teste no servidor (o plugin atualiza sozinho)", FCVAR_DONTRECORD);
    RegAdminCmd("sm_bots", Cmd_Bots, ADMFLAG_GENERIC, "Menu de bots de teste");
    CreateTimer(2.0, T_Contar, _, TIMER_REPEAT);
    TopMenu tm;
    if (LibraryExists("adminmenu") && (tm = GetAdminTopMenu()) != null)
        OnAdminMenuReady(tm);
}

public void OnLibraryRemoved(const char[] nome)
{
    if (StrEqual(nome, "adminmenu"))
        g_Menu = null;
}

public void OnAdminMenuReady(Handle h)
{
    TopMenu tm = TopMenu.FromHandle(h);
    if (tm == g_Menu)
        return;
    g_Menu = tm;
    TopMenuObject cat = tm.FindCategory(ADMINMENU_SERVERCOMMANDS);
    if (cat != INVALID_TOPMENUOBJECT)
        tm.AddItem("sm_bots", Item_Bots, cat, "sm_bots", ADMFLAG_GENERIC);
}

public void Item_Bots(TopMenu tm, TopMenuAction acao, TopMenuObject obj, int client, char[] buf, int len)
{
    if (acao == TopMenuAction_DisplayOption)
        Format(buf, len, "Bots de teste");
    else if (acao == TopMenuAction_SelectOption)
        Menu_Bots(client);
}

bool EhTeste(int i)
{
    if (!IsClientInGame(i) || !IsFakeClient(i) || IsClientSourceTV(i) || IsClientReplay(i))
        return false;
    char nome[MAX_NAME_LENGTH];
    GetClientName(i, nome, sizeof(nome));
    return StrContains(nome, PREFIXO) == 0;
}

int Contar()
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (EhTeste(i))
            n++;
    return n;
}

public Action T_Contar(Handle t)
{
    g_cvAtivos.IntValue = Contar();
    return Plugin_Continue;
}

int VagasLivres()
{
    int usadas = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientConnected(i))
            usadas++;
    int max = GetMaxHumanPlayers();
    return max > usadas ? max - usadas : 0;
}

public Action Cmd_Bots(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "Use no jogo: !bots");
        return Plugin_Handled;
    }
    Menu_Bots(client);
    return Plugin_Handled;
}

void Menu_Bots(int client)
{
    Menu m = new Menu(H_Bots);
    m.SetTitle("Bots de teste (agora: %d, vagas livres: %d)", Contar(), VagasLivres());
    m.AddItem("1", "Colocar 1 bot");
    m.AddItem("3", "Colocar 3 bots");
    m.AddItem("5", "Colocar 5 bots");
    m.AddItem("10", "Colocar 10 bots");
    m.AddItem("0", "Tirar todos os bots de teste", Contar() > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    m.ExitBackButton = g_Menu != null;
    m.Display(client, 30);
}

public int H_Bots(Menu m, MenuAction acao, int client, int item)
{
    if (acao == MenuAction_End)
        delete m;
    else if (acao == MenuAction_Cancel && item == MenuCancel_ExitBack && g_Menu != null)
        g_Menu.Display(client, TopMenuPosition_LastCategory);
    else if (acao == MenuAction_Select)
    {
        char info[8];
        m.GetItem(item, info, sizeof(info));
        int n = StringToInt(info);
        if (n > 0)
            Colocar(client, n);
        else
            Tirar(client);
        Menu_Bots(client);
    }
    return 0;
}

void Colocar(int client, int pedidos)
{
    int n = pedidos;
    int livres = VagasLivres();
    if (n > livres)
        n = livres;
    if (n <= 0)
    {
        PrintToChat(client, "\x04[SKYNET]\x01 Servidor cheio: nao cabe mais bot.");
        return;
    }
    g_cvAtivos.IntValue = Contar() + n;   // tells Dodgeball Auto Reflect before the bots join
    for (int k = 0; k < n; k++)
        ServerCommand("tf_bot_add 1 \"%s %d\"", PREFIXO, ++g_iSeq);
    ShowActivity2(client, "\x04[SKYNET]\x01 ", "colocou %d bot(s) de teste%s.", n, n < pedidos ? " (o servidor encheu)" : "");
    LogAction(client, -1, "\"%L\" colocou %d bot(s) de teste", client, n);
}

void Tirar(int client)
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (EhTeste(i))
        {
            KickClient(i, "Bot de teste removido");
            n++;
        }
    }
    ConVar cota = FindConVar("tf_bot_quota");
    if (cota != null)
        cota.IntValue = cota.IntValue > n ? cota.IntValue - n : 0;   // otherwise the game puts other bots in their place
    g_cvAtivos.IntValue = 0;
    ShowActivity2(client, "\x04[SKYNET]\x01 ", "tirou %d bot(s) de teste.", n);
    LogAction(client, -1, "\"%L\" tirou %d bot(s) de teste", client, n);
}
