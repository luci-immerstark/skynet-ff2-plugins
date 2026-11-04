// SKYNET Mapa Proibido: mapas da lista nunca ficam no ar. Se o servidor abrir num deles (ex.: o mapa inicial do
//   container depois do reinicio diario, arena_lumberyard), troca na hora para o mapa de skynet_mapa_destino
//   (ou, se ele estiver vazio ou nao existir, para um mapa aleatorio da rotacao).
// 1.1: mapa de destino fixo (skynet_mapa_destino).
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Mapa Proibido",
    author      = "SKYNET GAMING",
    description = "Troca na hora para a rotacao se o servidor abrir num mapa proibido",
    version     = "1.1",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

ConVar g_cvLista, g_cvDestino;

public void OnPluginStart()
{
    g_cvLista = CreateConVar("skynet_mapas_proibidos", "arena_lumberyard", "Mapas que nunca ficam no ar, separados por virgula");
    g_cvDestino = CreateConVar("skynet_mapa_destino", "", "Mapa para onde o servidor vai quando abrir num mapa proibido (vazio = aleatorio da rotacao)");
    AutoExecConfig(true, "skynet_mapa_proibido");
}

bool Proibido(const char[] mapa)
{
    char lista[512], itens[32][64];
    g_cvLista.GetString(lista, sizeof(lista));
    int n = ExplodeString(lista, ",", itens, sizeof(itens), sizeof(itens[]));
    for (int i = 0; i < n; i++)
    {
        TrimString(itens[i]);
        if (itens[i][0] && StrEqual(mapa, itens[i], false))
            return true;
    }
    return false;
}

public void OnConfigsExecuted()
{
    char mapa[64];
    GetCurrentMap(mapa, sizeof(mapa));
    if (Proibido(mapa))
        CreateTimer(3.0, T_Troca, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_Troca(Handle t)
{
    char destino[64];
    g_cvDestino.GetString(destino, sizeof(destino));
    TrimString(destino);
    if (destino[0] && !Proibido(destino) && IsMapValid(destino))
    {
        LogMessage("Mapa proibido no ar; trocando para %s", destino);
        ForceChangeLevel(destino, "SKYNET: mapa inicial");
        return Plugin_Stop;
    }
    ArrayList lista = view_as<ArrayList>(ReadMapList(null, _, "default", MAPLIST_FLAG_CLEARARRAY | MAPLIST_FLAG_NO_DEFAULT));
    if (lista == null)
    {
        LogError("Nao consegui ler a rotacao de mapas");
        return Plugin_Stop;
    }
    char m[64];
    ArrayList ok = new ArrayList(ByteCountToCells(64));
    for (int i = 0; i < lista.Length; i++)
    {
        lista.GetString(i, m, sizeof(m));
        if (!Proibido(m) && IsMapValid(m))
            ok.PushString(m);
    }
    delete lista;
    if (ok.Length > 0)
    {
        ok.GetString(GetRandomInt(0, ok.Length - 1), m, sizeof(m));
        LogMessage("Mapa proibido no ar; trocando para %s", m);
        ForceChangeLevel(m, "SKYNET: mapa fora da rotacao");
    }
    delete ok;
    return Plugin_Stop;
}
