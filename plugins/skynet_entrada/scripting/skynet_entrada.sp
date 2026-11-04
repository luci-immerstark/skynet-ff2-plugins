// SKYNET: colored chat notice when a player joins the server, with the country they connected from.
//   Only on the first join (map changes do not repeat it). Test from the server console: skynet_entrada_teste <ip>
#include <sourcemod>
#include <geoip>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET Entrada",
    author      = "SKYNET GAMING",
    description = "Avisa no chat quem entrou no servidor e de qual pais",
    version     = "1.0.0",
    url         = ""
};

// country with the right Portuguese preposition; the others come out with the English name ("de Germany")
static const char CODIGOS[][] = {
    "BR", "AR", "CL", "UY", "PY", "PE", "BO", "CO", "VE", "EC",
    "MX", "US", "CA", "PT", "ES", "FR", "DE", "IT", "GB", "RU",
    "PL", "NL", "JP", "CR", "PA", "GT", "DO", "CU", "AU", "CN",
    "SV", "HN", "NI", "PR", "BE", "CH", "SE", "IE", "UA", "TR"
};
static const char NOMES[][] = {
    "do Brasil", "da Argentina", "do Chile", "do Uruguai", "do Paraguai", "do Peru", "da Bolívia", "da Colômbia", "da Venezuela", "do Equador",
    "do México", "dos Estados Unidos", "do Canadá", "de Portugal", "da Espanha", "da França", "da Alemanha", "da Itália", "do Reino Unido", "da Rússia",
    "da Polônia", "da Holanda", "do Japão", "da Costa Rica", "do Panamá", "da Guatemala", "da República Dominicana", "de Cuba", "da Austrália", "da China",
    "de El Salvador", "de Honduras", "da Nicarágua", "de Porto Rico", "da Bélgica", "da Suíça", "da Suécia", "da Irlanda", "da Ucrânia", "da Turquia"
};

ArrayList g_Avisados;   // userids already announced (map changes do not announce again)

public void OnPluginStart()
{
    g_Avisados = new ArrayList();
    for (int i = 1; i <= MaxClients; i++)   // players already on the server when the plugin loaded are not announced
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
            g_Avisados.Push(GetClientUserId(i));
    }
    HookEvent("player_disconnect", Ev_Saiu, EventHookMode_Pre);
    RegServerCmd("skynet_entrada_teste", Cmd_Teste, "Mostra de onde e um IP: skynet_entrada_teste <ip>");
}

void Origem(const char[] ip, char[] onde, int tam)
{
    onde[0] = '\0';
    char cc[3];
    if (GeoipCode2(ip, cc))
    {
        for (int i = 0; i < sizeof(CODIGOS); i++)
        {
            if (StrEqual(cc, CODIGOS[i], false))
            {
                strcopy(onde, tam, NOMES[i]);
                return;
            }
        }
    }
    char nome[64];
    if (GeoipCountry(ip, nome, sizeof(nome)) && nome[0])
        Format(onde, tam, "de %s", nome);
}

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client))
        return;
    int uid = GetClientUserId(client);
    if (g_Avisados.FindValue(uid) != -1)
        return;
    g_Avisados.Push(uid);

    char ip[32], onde[64];
    GetClientIP(client, ip, sizeof(ip));
    Origem(ip, onde, sizeof(onde));
    if (onde[0])
        PrintToChatAll("\x01\x07FFD700[SKYNET]\x01 \x0799CCFF%N\x01 entrou no servidor, direto \x0747D16B%s\x01!", client, onde);
    else
        PrintToChatAll("\x01\x07FFD700[SKYNET]\x01 \x0799CCFF%N\x01 entrou no servidor!", client);
}

public void Ev_Saiu(Event event, const char[] nome, bool semTransmitir)
{
    int i = g_Avisados.FindValue(event.GetInt("userid"));
    if (i != -1)
        g_Avisados.Erase(i);
}

public Action Cmd_Teste(int args)
{
    char ip[32], onde[64];
    GetCmdArg(1, ip, sizeof(ip));
    Origem(ip, onde, sizeof(onde));
    PrintToServer("skynet_entrada: %s -> %s", ip, onde[0] ? onde : "(pais nao encontrado: confira o banco GeoIP em configs/geoip)");
    return Plugin_Handled;
}
