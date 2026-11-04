// SKYNET FF2 Rodizio: escolhe o boss da rodada sem repetir os ultimos N (padrao 10).
//   Na hora em que o FF2 sorteia o boss, troca por um sorteio entre os bosses que NAO sairam nas ultimas N rodadas.
//   Depois de N rodadas o boss volta para o sorteio. Escolha forcada por admin (ff2_makeboss / ff2_override) nao e mexida.
//   O historico fica salvo em data/skynet_ff2_rodizio.txt (vale tambem depois de trocar mapa ou reiniciar).
//   !rodizio mostra quais bosses estao fora do sorteio agora.
// 1.1.0: boss duplo (com parceiro) so entra no sorteio com skynet_ff2_rodizio_duo_min jogadores ou mais (padrao 21).
#include <sourcemod>
#include <cfgmap>
#include <ff2r>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "SKYNET FF2 Rodizio",
    author      = "SKYNET GAMING",
    description = "FF2: o boss da rodada nao repete nas ultimas N rodadas",
    version     = "1.1.0",
    url         = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

ConVar g_cvRodadas, g_cvDuoMin;
ArrayList g_Historico;          // arquivos dos bosses que sairam, o mais recente no fim
StringMap g_NestaRodada;        // ja gravados nesta rodada (o FF2 avisa a criacao do boss mais de uma vez)
char g_Arquivo[PLATFORM_MAX_PATH];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("FF2R_GetSpecialCount");
    MarkNativeAsOptional("FF2R_GetSpecialData");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvRodadas = CreateConVar("skynet_ff2_rodizio", "10", "Um boss que saiu fica fora do sorteio por esta quantidade de rodadas (0 = desligado)", _, true, 0.0, true, 50.0);
    g_cvDuoMin = CreateConVar("skynet_ff2_rodizio_duo_min", "21", "Boss duplo so sai no sorteio com pelo menos esta quantidade de jogadores (0 = sempre)", _, true, 0.0, true, 64.0);
    AutoExecConfig(true, "skynet_ff2_rodizio");
    g_Historico = new ArrayList(ByteCountToCells(64));
    g_NestaRodada = new StringMap();
    BuildPath(Path_SM, g_Arquivo, sizeof(g_Arquivo), "data/skynet_ff2_rodizio.txt");
    Carrega();
    HookEvent("teamplay_round_start", Ev_Rodada, EventHookMode_PostNoCopy);
    RegConsoleCmd("sm_rodizio", Cmd_Rodizio, "Mostra os bosses que estao fora do sorteio");
}

void Carrega()
{
    g_Historico.Clear();
    File f = OpenFile(g_Arquivo, "r");
    if (f == null)
        return;
    char linha[64];
    while (f.ReadLine(linha, sizeof(linha)))
    {
        TrimString(linha);
        if (linha[0])
            g_Historico.PushString(linha);
    }
    delete f;
}

void Salva()
{
    while (g_Historico.Length > 50)
        g_Historico.Erase(0);
    File f = OpenFile(g_Arquivo, "w");
    if (f == null)
        return;
    char nome[64];
    for (int i = 0; i < g_Historico.Length; i++)
    {
        g_Historico.GetString(i, nome, sizeof(nome));
        f.WriteLine(nome);
    }
    delete f;
}

public void Ev_Rodada(Event e, const char[] nome, bool sem)
{
    g_NestaRodada.Clear();
}

// o boss foi criado de verdade: entra no historico
public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
    char arq[64];
    if (cfg == null || !view_as<ConfigMap>(cfg).Get("filename", arq, sizeof(arq)) || !arq[0])
        return;
    int x;
    if (g_NestaRodada.GetValue(arq, x))
        return;
    g_NestaRodada.SetValue(arq, 1);
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
        LogMessage("boss criado: %s (jogador %N)", arq, client);   // para o relatorio de testes
    bool parceiro;
    if (view_as<ConfigMap>(cfg).GetBool("blocked", parceiro, false) && parceiro)
        return;                         // parceiro de dupla (nao sai sozinho): nao conta como rodada
    int i = g_Historico.FindString(arq);
    if (i != -1)
        g_Historico.Erase(i);
    g_Historico.PushString(arq);
    Salva();
}

// mesmo criterio do FF2 Rewrite para um boss poder sair no sorteio
bool PodeSair(ConfigMap cfg)
{
    bool b;
    if (!cfg.GetBool("enabled", b) || !b)
        return false;
    b = false;
    if (cfg.GetBool("blocked", b, false) && b)
        return false;
    b = false;
    if (cfg.GetBool("owner", b, false) && b)
        return false;
    b = false;
    if (cfg.GetBool("raidboss", b, false) && b)
        return false;
    b = true;
    if (cfg.GetBool("random", b, false) && !b)
        return false;
    char tmp[8];
    if (cfg.Get("admin", tmp, sizeof(tmp)) || cfg.Get("steamid", tmp, sizeof(tmp)) || cfg.Get("cvar", tmp, sizeof(tmp)))
        return false;
    return true;
}

int Jogadores()
{
    int n = 0;
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && !IsFakeClient(c) && GetClientTeam(c) > 1)
            n++;
    return n;
}

bool EhDuplo(ConfigMap cfg)
{
    char tmp[8];
    return cfg.Get("companion", tmp, sizeof(tmp)) > 0;
}

// ultima posicao em que o boss saiu, contando de tras (0 = saiu na ultima rodada); -1 = nao saiu recentemente
int Recencia(const char[] arq)
{
    int i = g_Historico.FindString(arq);
    return i == -1 ? -1 : g_Historico.Length - 1 - i;
}

public Action FF2_OnSpecialSelected(int boss, int &special, char[] specialName, bool preset)
{
    int n = g_cvRodadas.IntValue;
    if (preset || n <= 0 || GetFeatureStatus(FeatureType_Native, "FF2R_GetSpecialCount") != FeatureStatus_Available)
        return Plugin_Continue;

    ConfigMap orig = view_as<ConfigMap>(FF2R_GetSpecialData(special));
    bool raid;
    if (orig != null && orig.GetBool("raidboss", raid, false) && raid)
        return Plugin_Continue;         // rodada especial de raid: deixa com o FF2
    int total = FF2R_GetSpecialCount();
    bool duoOk = Jogadores() >= g_cvDuoMin.IntValue;
    ArrayList livres = new ArrayList(), todos = new ArrayList();
    char arq[64];
    int maisAntigo = -1, idadeMax = -1;
    for (int s = 0; s < total; s++)
    {
        ConfigMap cfg = view_as<ConfigMap>(FF2R_GetSpecialData(s));
        if (cfg == null || !PodeSair(cfg) || !cfg.Get("filename", arq, sizeof(arq)) || !arq[0])
            continue;
        if (!duoOk && EhDuplo(cfg))
            continue;                   // poucos jogadores: sem boss duplo
        todos.Push(s);
        int r = Recencia(arq);
        if (r == -1 || r >= n)
            livres.Push(s);
        else if (r > idadeMax)
        {
            idadeMax = r;
            maisAntigo = s;
        }
    }

    int escolhido = -1;
    if (livres.Length)
        escolhido = livres.Get(GetURandomInt() % livres.Length);
    else if (maisAntigo != -1)
        escolhido = maisAntigo;         // poucos bosses na lista: vai o que saiu ha mais tempo
    int livresN = livres.Length, todosN = todos.Length;
    delete livres;
    delete todos;
    if (escolhido == -1)
        return Plugin_Continue;
    if (escolhido == special)
        return Plugin_Continue;

    ConfigMap cfg = view_as<ConfigMap>(FF2R_GetSpecialData(escolhido));
    cfg.Get("filename", arq, sizeof(arq));
    LogMessage("rodizio: boss sorteado %s (%d livres de %d)", arq, livresN, todosN);
    special = escolhido;
    specialName[0] = '\0';              // vazio: o FF2 usa o numero do boss, nao o nome
    return Plugin_Changed;
}

public Action Cmd_Rodizio(int client, int args)
{
    int n = g_cvRodadas.IntValue;
    char arq[64], lista[512];
    int c = 0;
    for (int i = g_Historico.Length - 1; i >= 0 && c < n; i--, c++)
    {
        g_Historico.GetString(i, arq, sizeof(arq));
        Format(lista, sizeof(lista), "%s%s%s", lista, lista[0] ? ", " : "", arq);
    }
    ReplyToCommand(client, "[SKYNET] Fora do sorteio (sairam nas ultimas %d rodadas): %s", n, lista[0] ? lista : "nenhum");
    return Plugin_Handled;
}
