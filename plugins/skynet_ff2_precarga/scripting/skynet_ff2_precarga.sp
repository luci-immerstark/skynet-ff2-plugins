// SKYNET FF2 Precarga: carrega os subplugins dos bosses (pasta freaks) no inicio do mapa.
//   O FF2 Rewrite carrega esses plugins no meio do evento de inicio de rodada. Se um deles registra um gancho nesse
//   mesmo evento enquanto ele esta acontecendo, a pilha de eventos do SourceMod desalinha e o servidor cai no proximo
//   evento (crash em CStack<IGameEvent*>::push). Carregando antes, fora de qualquer evento, isso nao acontece.
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Precarga",
    author      = "SKYNET GAMING",
    description = "Carrega os subplugins do FF2 no inicio do mapa, fora de eventos",
    version     = "1.0.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

public void OnConfigsExecuted()
{
    CreateTimer(1.0, T_Carrega, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_Carrega(Handle t)
{
    if (CommandExists("ff2_loadsubplugins"))
    {
        ServerCommand("ff2_loadsubplugins");
        LogMessage("subplugins do FF2 carregados no inicio do mapa");
    }
    return Plugin_Stop;
}
