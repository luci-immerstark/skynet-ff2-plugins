// SKYNET FF2 Fila: fila de boss justa. Cada rodada sem ser boss vale +1; quem foi boss volta para o fim.
// O plugin escreve os pontos de fila do FF2 no fim de cada rodada (rodadas esperando x 100 + sorteio para desempate),
// entao o FF2 sempre escolhe quem esta esperando ha mais tempo. !fila mostra a ordem; sm_ff2fila (console) mostra tudo.
// 1.1.0: todo mundo entra na fila (como no VSH oficial): o plugin apaga a opcao "nao quero ser boss" de cada jogador
//   (ff2_pref_toggle 0 tira essa opcao do menu do FF2).
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Fila",
    author      = "SKYNET GAMING",
    description = "Fila de boss justa para o FF2 (quem espera mais vira o boss)",
    version     = "1.1.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

native any FF2R_GetBossData(int client);
native ArrayList FF2R_GetClientListing(int client);
native int FF2_GetQueuePoints(int client);
native void FF2_SetQueuePoints(int client, int points);

StringMap g_Espera;     // conta Steam -> rodadas esperando

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetBossData");
    MarkNativeAsOptional("FF2R_GetClientListing");
    MarkNativeAsOptional("FF2_GetQueuePoints");
    MarkNativeAsOptional("FF2_SetQueuePoints");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_Espera = new StringMap();
    HookEvent("teamplay_round_win", Ev_Fim, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_start", Ev_Inicio, EventHookMode_PostNoCopy);
    RegConsoleCmd("sm_fila", Cmd_Fila, "Mostra a fila para ser boss");
    RegServerCmd("sm_ff2fila", Cmd_Diag, "Diagnostico da fila do FF2");
    if (FF2Ativo())
        Aplica();
}

bool FF2Ativo()
{
    return GetFeatureStatus(FeatureType_Native, "FF2_SetQueuePoints") == FeatureStatus_Available
        && GetFeatureStatus(FeatureType_Native, "FF2R_GetBossData") == FeatureStatus_Available;
}

bool Humano(int c)
{
    return IsClientInGame(c) && !IsFakeClient(c) && GetSteamAccountID(c) != 0;
}

void Chave(int c, char[] k, int len)
{
    IntToString(GetSteamAccountID(c), k, len);
}

int Espera(int c)
{
    char k[16];
    Chave(c, k, sizeof(k));
    int v;
    return g_Espera.GetValue(k, v) ? v : 0;
}

void SetEspera(int c, int v)
{
    char k[16];
    Chave(c, k, sizeof(k));
    g_Espera.SetValue(k, v);
}

bool NaoQuer(int c)
{
    if (GetFeatureStatus(FeatureType_Native, "FF2R_GetClientListing") != FeatureStatus_Available)
        return false;
    ArrayList l = FF2R_GetClientListing(c);
    if (l == null)
        return false;
    for (int i = 0; i < l.Length; i++)
        if (view_as<int>(l.Get(i)) < 0)
            return true;
    return false;
}

// tira o "nao quero ser boss" (valores negativos na lista de bosses do FF2)
void TodosNaFila(int c)
{
    if (GetFeatureStatus(FeatureType_Native, "FF2R_GetClientListing") != FeatureStatus_Available)
        return;
    ArrayList l = FF2R_GetClientListing(c);
    if (l == null)
        return;
    for (int i = l.Length - 1; i >= 0; i--)
        if (view_as<int>(l.Get(i)) < 0)
            l.Erase(i);
}

void Aplica()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!Humano(c))
            continue;
        TodosNaFila(c);
        FF2_SetQueuePoints(c, Espera(c) * 100 + GetRandomInt(0, 99));
    }
}

public void OnClientPostAdminCheck(int c)
{
    if (!IsFakeClient(c))
        CreateTimer(8.0, T_Entrou, GetClientUserId(c), TIMER_FLAG_NO_MAPCHANGE);   // depois que o FF2 carrega o banco
}

public Action T_Entrou(Handle t, int uid)
{
    int c = GetClientOfUserId(uid);
    if (c > 0 && Humano(c) && FF2Ativo())
    {
        TodosNaFila(c);
        FF2_SetQueuePoints(c, Espera(c) * 100 + GetRandomInt(0, 99));
    }
    return Plugin_Stop;
}

public void Ev_Fim(Event e, const char[] nome, bool sem)
{
    CreateTimer(1.0, T_Fim, _, TIMER_FLAG_NO_MAPCHANGE);   // depois do FF2 dar os pontos dele
}

public Action T_Fim(Handle t)
{
    if (!FF2Ativo())
        return Plugin_Stop;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!Humano(c))
            continue;
        if (FF2R_GetBossData(c))
            SetEspera(c, 0);                         // foi boss: volta para o fim da fila
        else if (GetClientTeam(c) >= 2)
            SetEspera(c, Espera(c) + 1);             // jogou a rodada sem ser boss
    }
    Aplica();
    return Plugin_Stop;
}

public void Ev_Inicio(Event e, const char[] nome, bool sem)
{
    CreateTimer(1.5, T_Log, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_Log(Handle t)
{
    if (!FF2Ativo())
        return Plugin_Stop;
    for (int c = 1; c <= MaxClients; c++)
        if (Humano(c) && FF2R_GetBossData(c))
            LogMessage("boss da rodada: %N (esperou %d rodada(s))", c, Espera(c));
    return Plugin_Stop;
}

int Ordem(int[] lista)
{
    int n = 0;
    for (int c = 1; c <= MaxClients; c++)
        if (Humano(c) && GetClientTeam(c) >= 2 && !NaoQuer(c) && !(FF2Ativo() && FF2R_GetBossData(c)))
            lista[n++] = c;
    for (int i = 0; i < n; i++)          // ordena por pontos de fila do FF2 (o que ele usa para escolher)
        for (int j = i + 1; j < n; j++)
            if (FF2_GetQueuePoints(lista[j]) > FF2_GetQueuePoints(lista[i]))
            {
                int x = lista[i];
                lista[i] = lista[j];
                lista[j] = x;
            }
    return n;
}

public Action Cmd_Fila(int client, int args)
{
    if (!FF2Ativo())
        return Plugin_Handled;
    int lista[MAXPLAYERS + 1];
    int n = Ordem(lista);
    ReplyToCommand(client, "\x04[SKYNET]\x01 Fila para ser boss (quem esperou mais rodadas vem primeiro):");
    for (int i = 0; i < n && i < 6; i++)
        ReplyToCommand(client, "\x01 %d. \x03%N\x01 (%d rodada(s) esperando)", i + 1, lista[i], Espera(lista[i]));
    if (n == 0)
        ReplyToCommand(client, "\x01 ninguem na fila agora");
    return Plugin_Handled;
}

public Action Cmd_Diag(int args)
{
    if (!FF2Ativo())
    {
        PrintToServer("FILA FF2 nao esta rodando");
        return Plugin_Handled;
    }
    char lst[96], n[12];
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!Humano(c))
            continue;
        lst[0] = '\0';
        ArrayList l = FF2R_GetClientListing(c);
        if (l != null)
            for (int k = 0; k < l.Length && k < 10; k++)
            {
                IntToString(l.Get(k), n, sizeof(n));
                StrCat(lst, sizeof(lst), n);
                StrCat(lst, sizeof(lst), " ");
            }
        PrintToServer("FILA #%d %N | time %d | %s | %s | pontos FF2 %d | esperando %d | lista: %s", c, c, GetClientTeam(c),
            IsPlayerAlive(c) ? "vivo" : "morto", FF2R_GetBossData(c) ? "BOSS" : "-", FF2_GetQueuePoints(c), Espera(c), lst[0] ? lst : "(vazia)");
    }
    return Plugin_Handled;
}
