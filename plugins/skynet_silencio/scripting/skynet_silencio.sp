// SKYNET Silencio: esconde do chat dos jogadores as mensagens "Server cvar 'x' changed to y" (configuracoes que
//   plugins mudam durante o jogo, como a velocidade do modo fantasma de alguns bosses). O log do servidor continua igual.
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
