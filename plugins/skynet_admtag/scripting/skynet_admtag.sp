#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "SKYNET Admin Tag",
    author = "SKYNET GAMING",
    description = "Tag [ADM] (dourada), [MOD] (azul) e [VIP] (roxa) no chat",
    version = "1.3",
    url = "https://github.com/luci-immerstark/skynet-sourcemod-plugins"
};

// [ADM]: quem pode banir (ou e root). [MOD]: quem tem o acesso basico de admin mas nao bane (grupo Moderador).
// [VIP]: quem so tem a vaga reservada (flag a, grupo VIP: boosters do Discord).
//   Da pra mudar quem recebe cada tag com overrides em admin_overrides.cfg: "sm_tag_adm", "sm_tag_mod" e "sm_tag_vip".
#define COR_ADM "FFD700"
#define COR_MOD "4FC3F7"
#define COR_VIP "B266FF"

public void OnPluginStart()
{
    UserMsg id = GetUserMessageId("SayText2");
    if (id == INVALID_MESSAGE_ID)
        SetFailState("Mensagem SayText2 nao encontrada");
    HookUserMessage(id, OnSayText2, true);
}

public Action OnSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    int author = msg.ReadByte();
    if (author < 1 || author > MaxClients || !IsClientInGame(author) || IsFakeClient(author))
        return Plugin_Continue;
    int tipo = Tipo(author);
    if (tipo == 0)
        return Plugin_Continue;

    bool chat = msg.ReadByte() != 0;
    char fmt[64];
    msg.ReadString(fmt, sizeof(fmt));
    if (StrContains(fmt, "TF_Chat_") == -1)
        return Plugin_Continue;

    char name[MAX_NAME_LENGTH], text[256];
    msg.ReadString(name, sizeof(name));
    msg.ReadString(text, sizeof(text));

    DataPack dp = new DataPack();
    dp.WriteCell(GetClientUserId(author));
    dp.WriteCell(chat);
    dp.WriteCell(tipo);
    dp.WriteString(fmt);
    dp.WriteString(name);
    dp.WriteString(text);
    dp.WriteCell(playersNum);
    for (int i = 0; i < playersNum; i++)
        dp.WriteCell(GetClientUserId(players[i]));
    RequestFrame(Frame_Resend, dp);
    return Plugin_Handled;
}

// 3 = [ADM] (pode banir), 2 = [MOD] (acesso basico de admin), 1 = [VIP] (vaga reservada, grupo VIP), 0 = sem tag
int Tipo(int client)
{
    if (CheckCommandAccess(client, "sm_tag_adm", ADMFLAG_BAN, true))
        return 3;
    if (CheckCommandAccess(client, "sm_tag_mod", ADMFLAG_GENERIC, true))
        return 2;
    if (CheckCommandAccess(client, "sm_tag_vip", ADMFLAG_RESERVATION, true))
        return 1;
    return 0;
}

// Mesmo prefixo que o jogo usaria (morto, time, espectador, coach)
void Prefixo(const char[] fmt, char[] pre, int len)
{
    if (StrContains(fmt, "Team_Dead") != -1)     strcopy(pre, len, "*DEAD*(TEAM) ");
    else if (StrContains(fmt, "AllDead") != -1)  strcopy(pre, len, "*DEAD* ");
    else if (StrContains(fmt, "AllSpec") != -1)  strcopy(pre, len, "*SPEC* ");
    else if (StrContains(fmt, "Team") != -1)     strcopy(pre, len, "(TEAM) ");
    else if (StrContains(fmt, "Spec") != -1)     strcopy(pre, len, "(Spectator) ");
    else if (StrContains(fmt, "Coach") != -1)    strcopy(pre, len, "(Coach) ");
    else pre[0] = '\0';
}

public void Frame_Resend(DataPack dp)
{
    dp.Reset();
    int author = GetClientOfUserId(dp.ReadCell());
    bool chat = view_as<bool>(dp.ReadCell());
    int tipo = dp.ReadCell();
    char fmt[64], name[MAX_NAME_LENGTH], text[256];
    dp.ReadString(fmt, sizeof(fmt));
    dp.ReadString(name, sizeof(name));
    dp.ReadString(text, sizeof(text));
    int num = dp.ReadCell();
    int clients[MAXPLAYERS + 1];
    int total = 0;
    for (int i = 0; i < num; i++)
    {
        int c = GetClientOfUserId(dp.ReadCell());
        if (c > 0 && IsClientInGame(c) && total < MAXPLAYERS)
            clients[total++] = c;
    }
    delete dp;
    if (author == 0 || total == 0)
        return;

    char pre[32], linha[320];
    Prefixo(fmt, pre, sizeof(pre));
    Format(linha, sizeof(linha), "\x01%s\x07%s[%s] \x03%s\x01 :  %s", pre, tipo == 3 ? COR_ADM : (tipo == 2 ? COR_MOD : COR_VIP), tipo == 3 ? "ADM" : (tipo == 2 ? "MOD" : "VIP"), name, text);

    BfWrite bf = UserMessageToBfWrite(StartMessage("SayText2", clients, total, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS));
    bf.WriteByte(author);
    bf.WriteByte(chat ? 1 : 0);
    bf.WriteString(linha);
    bf.WriteString("");
    bf.WriteString("");
    bf.WriteString("");
    bf.WriteString("");
    EndMessage();
}
