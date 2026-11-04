// SKYNET FF2 Preload: loads the boss subplugins (freaks folder) at the start of the map.
//   FF2 Rewrite loads these plugins in the middle of the round start event. If one of them hooks that
//   same event while it is happening, SourceMod's event stack gets misaligned and the server crashes on the next
//   event (crash in CStack<IGameEvent*>::push). Loading them earlier, outside any event, avoids this.
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
