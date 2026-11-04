#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "SKYNET Welcome",
    author = "SKYNET GAMING",
    description = "Mensagem de boas-vindas uma vez por conexao",
    version = "1.1",
    url = ""
};

StringMap g_Shown;

public void OnPluginStart()
{
    g_Shown = new StringMap();
    HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
}

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client))
        return;
    char auth[32];
    bool shown;
    if (!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)) || g_Shown.GetValue(auth, shown))
        return;
    CreateTimer(30.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Welcome(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client < 1 || !IsClientInGame(client))
        return Plugin_Stop;
    char auth[32];
    bool shown;
    if (!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)) || g_Shown.GetValue(auth, shown))
        return Plugin_Stop;
    g_Shown.SetValue(auth, true);
    char msg[256];
    Format(msg, sizeof(msg), "\x01%cFFD700[SKYNET GAMING]\x01 Aproveite a partida! Lembre-se de manter o respeito com o próximo e seguir as regras do servidor.", 7);
    PrintToChat(client, "%s", msg);
    return Plugin_Stop;
}

public void Event_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client < 1)
        return;
    char auth[32];
    if (GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
        g_Shown.Remove(auth);
}
