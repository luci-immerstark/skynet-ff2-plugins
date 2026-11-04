// SKYNET Silence: hides the "Server cvar 'x' changed to y" messages from players' chat (settings that
//   plugins change during the game, like the ghost mode speed of some bosses). The server log stays the same.
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Silencio",
    author      = "SKYNET GAMING",
    description = "Esconde do chat os avisos de cvar alterada",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

public void OnPluginStart()
{
    HookEvent("server_cvar", Ev_Cvar, EventHookMode_Pre);
}

public Action Ev_Cvar(Event e, const char[] nome, bool sem)
{
    e.BroadcastDisabled = true;
    return Plugin_Changed;
}
