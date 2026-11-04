// SKYNET Killstreak: todas as armas dos jogadores viram Professional Killstreak (contador de abates, brilho na arma e
//   efeito nos olhos). Cada jogador escolhe o brilho e o efeito em !killstreak (ou !ks); a escolha fica salva.
//   Quem nunca escolheu ganha um brilho e um efeito sorteados. No FF2 o boss nao ganha (as armas dele sao do boss).
//   Os atributos vao pelo VScript do proprio TF2 (AddAttribute), porque o tf2attributes nao funciona em 64 bits.
//   Cvar: skynet_killstreak (1 liga).
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Killstreak",
    author      = "SKYNET GAMING",
    description = "Professional Killstreak em todas as armas, com escolha de brilho e efeito",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native Handle FF2R_GetBossData(int client);

static const char BRILHOS[][] = { "Team Shine", "Deadly Daffodil", "Manndarin", "Mean Green", "Agonizing Emerald", "Villainous Violet", "Hot Rod" };
static const char EFEITOS[][] = { "Fire Horns", "Cerebral Discharge", "Tornado", "Flames", "Singularity", "Incinerator", "Hypno-Beam" };

ConVar g_cvLiga;
Cookie g_ckBrilho, g_ckEfeito;
int g_iBrilho[MAXPLAYERS + 1];      // 0 = desligado, 1-7
int g_iEfeito[MAXPLAYERS + 1];      // 0 = desligado, 1-7 (atributo 2001 + n)

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvLiga = CreateConVar("skynet_killstreak", "1", "Killstreak nas armas dos jogadores (1 = sim)", _, true, 0.0, true, 1.0);
    AutoExecConfig(true, "skynet_killstreak");
    g_ckBrilho = new Cookie("skynet_ks_brilho", "Killstreak: brilho da arma", CookieAccess_Protected);
    g_ckEfeito = new Cookie("skynet_ks_efeito", "Killstreak: efeito nos olhos", CookieAccess_Protected);
    RegConsoleCmd("sm_killstreak", Cmd_Menu, "Escolhe o brilho e o efeito do killstreak");
    RegConsoleCmd("sm_ks", Cmd_Menu, "Escolhe o brilho e o efeito do killstreak");
    HookEvent("post_inventory_application", Ev_Armas);
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && AreClientCookiesCached(c))
            OnClientCookiesCached(c);
}

public void OnClientCookiesCached(int c)
{
    char v[8];
    g_ckBrilho.Get(c, v, sizeof(v));
    if (!v[0])
    {
        g_iBrilho[c] = GetRandomInt(1, 7);
        g_iEfeito[c] = GetRandomInt(1, 7);
        Salva(c);
        return;
    }
    g_iBrilho[c] = StringToInt(v);
    g_ckEfeito.Get(c, v, sizeof(v));
    g_iEfeito[c] = StringToInt(v);
}

void Salva(int c)
{
    char v[8];
    IntToString(g_iBrilho[c], v, sizeof(v));
    g_ckBrilho.Set(c, v);
    IntToString(g_iEfeito[c], v, sizeof(v));
    g_ckEfeito.Set(c, v);
}

bool EhBoss(int c)
{
    return GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available && FF2R_GetBossData(c) != null;
}

public void Ev_Armas(Event e, const char[] nome, bool sem)
{
    RequestFrame(F_Aplica, e.GetInt("userid"));     // depois que os outros plugins trocam as armas
}

public void F_Aplica(int uid)
{
    int c = GetClientOfUserId(uid);
    if (c && IsClientInGame(c) && IsPlayerAlive(c) && !IsFakeClient(c))
        Aplica(c);
}

void Aplica(int c)
{
    if (!g_cvLiga.BoolValue || EhBoss(c) || (!g_iBrilho[c] && !g_iEfeito[c]))
        return;
    char codigo[256];
    for (int slot = 0; slot <= 2; slot++)
    {
        int arma = GetPlayerWeaponSlot(c, slot);
        if (arma <= MaxClients || !IsValidEntity(arma))
            continue;
        FormatEx(codigo, sizeof(codigo), "self.AddAttribute(\"killstreak tier\", 3.0, -1.0)");
        if (g_iBrilho[c])
            Format(codigo, sizeof(codigo), "%s;self.AddAttribute(\"killstreak idleeffect\", %d.0, -1.0)", codigo, g_iBrilho[c]);
        if (g_iEfeito[c])
            Format(codigo, sizeof(codigo), "%s;self.AddAttribute(\"killstreak effect\", %d.0, -1.0)", codigo, 2001 + g_iEfeito[c]);
        SetVariantString(codigo);
        AcceptEntityInput(arma, "RunScriptCode");
    }
}

// ---------------------------------------------------------------- menu
public Action Cmd_Menu(int c, int args)
{
    if (c && IsClientInGame(c))
        MenuPrincipal(c);
    return Plugin_Handled;
}

void MenuPrincipal(int c)
{
    Menu m = new Menu(H_Principal);
    m.SetTitle("Killstreak\nBrilho: %s\nOlhos: %s", g_iBrilho[c] ? BRILHOS[g_iBrilho[c] - 1] : "desligado", g_iEfeito[c] ? EFEITOS[g_iEfeito[c] - 1] : "desligado");
    m.AddItem("b", "Escolher o brilho da arma");
    m.AddItem("e", "Escolher o efeito nos olhos");
    m.AddItem("x", "Desligar tudo");
    m.Display(c, 30);
}

public int H_Principal(Menu m, MenuAction a, int c, int item)
{
    if (a == MenuAction_End)
        delete m;
    else if (a == MenuAction_Select)
    {
        char k[4];
        m.GetItem(item, k, sizeof(k));
        if (k[0] == 'x')
        {
            g_iBrilho[c] = 0;
            g_iEfeito[c] = 0;
            Salva(c);
            PrintToChat(c, "[SKYNET] Killstreak desligado (vale ao renascer).");
        }
        else
            MenuLista(c, k[0] == 'b');
    }
    return 0;
}

void MenuLista(int c, bool brilho)
{
    Menu m = new Menu(brilho ? H_Brilho : H_Efeito);
    m.SetTitle(brilho ? "Brilho da arma" : "Efeito nos olhos");
    m.AddItem("0", "Desligado");
    char k[4];
    for (int i = 0; i < 7; i++)
    {
        IntToString(i + 1, k, sizeof(k));
        m.AddItem(k, brilho ? BRILHOS[i] : EFEITOS[i]);
    }
    m.ExitBackButton = true;
    m.Display(c, 30);
}

public int H_Brilho(Menu m, MenuAction a, int c, int item)
{
    return Escolha(m, a, c, item, true);
}

public int H_Efeito(Menu m, MenuAction a, int c, int item)
{
    return Escolha(m, a, c, item, false);
}

int Escolha(Menu m, MenuAction a, int c, int item, bool brilho)
{
    if (a == MenuAction_End)
        delete m;
    else if (a == MenuAction_Cancel && item == MenuCancel_ExitBack)
        MenuPrincipal(c);
    else if (a == MenuAction_Select)
    {
        char k[4];
        m.GetItem(item, k, sizeof(k));
        if (brilho)
            g_iBrilho[c] = StringToInt(k);
        else
            g_iEfeito[c] = StringToInt(k);
        Salva(c);
        PrintToChat(c, "[SKYNET] Killstreak salvo. Vale quando voce renascer ou pegar armas no armario.");
        MenuPrincipal(c);
    }
    return 0;
}
