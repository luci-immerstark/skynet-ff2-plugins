// SKYNET: !tp liga/desliga a camera em terceira pessoa; !fp volta para primeira pessoa.
//   Usa a camera de provocacao do proprio jogo (SetForcedTauntCam), sem cheats. Volta sozinha a cada spawn.
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Terceira Pessoa",
    author      = "SKYNET GAMING",
    description = "!tp para jogar em terceira pessoa, !fp para voltar",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

bool g_bTP[MAXPLAYERS + 1];

public void OnPluginStart()
{
    RegConsoleCmd("sm_tp", Cmd_TP, "Liga/desliga a terceira pessoa");
    RegConsoleCmd("sm_thirdperson", Cmd_TP, "Liga/desliga a terceira pessoa");
    RegConsoleCmd("sm_fp", Cmd_FP, "Volta para primeira pessoa");
    RegConsoleCmd("sm_firstperson", Cmd_FP, "Volta para primeira pessoa");
    HookEvent("player_spawn", Ev_Spawn);
}

public void OnClientDisconnect(int client)
{
    g_bTP[client] = false;
}

void Camera(int client)
{
    if (client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;
    SetVariantInt(g_bTP[client] ? 1 : 0);
    AcceptEntityInput(client, "SetForcedTauntCam");
}

public Action Cmd_TP(int client, int args)
{
    if (client < 1 || !IsClientInGame(client))
        return Plugin_Handled;
    g_bTP[client] = !g_bTP[client];
    Camera(client);
    PrintToChat(client, "\x01\x07FFD700[CAMERA]\x01 %s", g_bTP[client]
        ? "Terceira pessoa \x0747D16BLIGADA\x01. Digite \x07FFD700!tp\x01 de novo ou \x07FFD700!fp\x01 para voltar."
        : "De volta para a primeira pessoa.");
    return Plugin_Handled;
}

public Action Cmd_FP(int client, int args)
{
    if (client < 1 || !IsClientInGame(client))
        return Plugin_Handled;
    g_bTP[client] = false;
    Camera(client);
    PrintToChat(client, "\x01\x07FFD700[CAMERA]\x01 De volta para a primeira pessoa.");
    return Plugin_Handled;
}

public void Ev_Spawn(Event event, const char[] nome, bool semTransmitir)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && g_bTP[client])
        CreateTimer(0.2, T_Camera, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_Camera(Handle timer, int userid)
{
    Camera(GetClientOfUserId(userid));
    return Plugin_Stop;
}
