// SKYNET: replacement for the TF2Items extension (the 64-bit build crashes the server).
// Same functions, written in SourcePawn: creates the weapon the way FF2 Rewrite already does when TF2Items is missing
// (entity + index/quality/level). v2: attributes go through TF2's own VScript (AddAttribute), with the name
// taken from the server's items_game.txt (tf2attributes does not work on a 64-bit server).
// Build/sap items (builder, sapper, PDAs) are NOT created: created this way they crash the players' game.
#if defined _tf2items_included
 #endinput
#endif
#define _tf2items_included

#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <skynet_atributos>

#define OVERRIDE_CLASSNAME      (1 << 0)
#define OVERRIDE_ITEM_DEF       (1 << 1)
#define OVERRIDE_ITEM_LEVEL     (1 << 2)
#define OVERRIDE_ITEM_QUALITY   (1 << 3)
#define OVERRIDE_ATTRIBUTES     (1 << 4)
#define OVERRIDE_ALL            (0b11111)
#define PRESERVE_ATTRIBUTES     (1 << 5)
#define FORCE_GENERATION        (1 << 6)

stock Handle TF2Items_CreateItem(int flags)
{
    StringMap item = new StringMap();
    item.SetValue("f", flags);
    item.SetValue("n", 0);
    item.SetValue("q", 0);
    item.SetValue("l", 1);
    item.SetValue("i", 0);
    return item;
}

stock void TF2Items_SetFlags(Handle item, int flags)               { view_as<StringMap>(item).SetValue("f", flags); }
stock void TF2Items_SetClassname(Handle item, const char[] classname) { view_as<StringMap>(item).SetString("c", classname); }
stock void TF2Items_SetItemIndex(Handle item, int itemDefIndex)    { view_as<StringMap>(item).SetValue("i", itemDefIndex); }
stock void TF2Items_SetQuality(Handle item, int quality)           { view_as<StringMap>(item).SetValue("q", quality); }
stock void TF2Items_SetLevel(Handle item, int level)               { view_as<StringMap>(item).SetValue("l", level); }
stock void TF2Items_SetNumAttributes(Handle item, int attributes)  { view_as<StringMap>(item).SetValue("n", attributes); }

stock void TF2Items_SetAttribute(Handle item, int slot, int attribute, float value)
{
    char key[8];
    FormatEx(key, sizeof(key), "a%d", slot);
    view_as<StringMap>(item).SetValue(key, attribute);
    FormatEx(key, sizeof(key), "v%d", slot);
    view_as<StringMap>(item).SetValue(key, value);
}

stock int TF2Items_GetFlags(Handle item)       { int v; view_as<StringMap>(item).GetValue("f", v); return v; }
stock int TF2Items_GetItemIndex(Handle item)   { int v; view_as<StringMap>(item).GetValue("i", v); return v; }
stock int TF2Items_GetQuality(Handle item)     { int v; view_as<StringMap>(item).GetValue("q", v); return v; }
stock int TF2Items_GetLevel(Handle item)       { int v; view_as<StringMap>(item).GetValue("l", v); return v; }
stock int TF2Items_GetNumAttributes(Handle item) { int v; view_as<StringMap>(item).GetValue("n", v); return v; }
stock int TF2Items_GetClassname(Handle item, char[] dest, int size)
{
    dest[0] = '\0';
    view_as<StringMap>(item).GetString("c", dest, size);
    return strlen(dest);
}

// TF2 swaps some generic names for the class-specific one; this does the same for the common cases
stock void TF2Items_Shim_Classe(int client, char[] classname, int size)
{
    TFClassType classe = TF2_GetPlayerClass(client);
    if (StrEqual(classname, "saxxy"))
    {
        switch (classe)
        {
            case TFClass_Scout:    strcopy(classname, size, "tf_weapon_bat");
            case TFClass_Soldier:  strcopy(classname, size, "tf_weapon_shovel");
            case TFClass_DemoMan:  strcopy(classname, size, "tf_weapon_bottle");
            case TFClass_Engineer: strcopy(classname, size, "tf_weapon_wrench");
            case TFClass_Medic:    strcopy(classname, size, "tf_weapon_bonesaw");
            case TFClass_Sniper:   strcopy(classname, size, "tf_weapon_club");
            case TFClass_Spy:      strcopy(classname, size, "tf_weapon_knife");
            default:               strcopy(classname, size, "tf_weapon_fireaxe");
        }
    }
    else if (StrEqual(classname, "tf_weapon_shotgun"))
    {
        switch (classe)
        {
            case TFClass_Pyro:     strcopy(classname, size, "tf_weapon_shotgun_pyro");
            case TFClass_Heavy:    strcopy(classname, size, "tf_weapon_shotgun_hwg");
            case TFClass_Engineer: strcopy(classname, size, "tf_weapon_shotgun_primary");
            default:               strcopy(classname, size, "tf_weapon_shotgun_soldier");
        }
    }
}

stock int TF2Items_GiveNamedItem(int client, Handle item)
{
    StringMap m = view_as<StringMap>(item);
    char classname[64];
    if (!m.GetString("c", classname, sizeof(classname)) || !classname[0])
        return -1;
    TF2Items_Shim_Classe(client, classname, sizeof(classname));
    if (StrEqual(classname, "tf_weapon_builder") || StrEqual(classname, "tf_weapon_sapper") || StrContains(classname, "tf_weapon_pda") == 0)
    {
        LogMessage("[TF2Items substituto] %s nao e criado (derruba o jogo dos jogadores)", classname);
        return -1;
    }

    int entity = CreateEntityByName(classname);
    if (entity == -1)
    {
        LogError("[TF2Items substituto] classe de arma invalida: %s", classname);
        return -1;
    }
    int indice, qualidade, nivel, flags, total;
    m.GetValue("i", indice);
    m.GetValue("q", qualidade);
    m.GetValue("l", nivel);
    m.GetValue("f", flags);
    m.GetValue("n", total);

    SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", indice);
    SetEntProp(entity, Prop_Send, "m_bInitialized", 1);
    SetEntProp(entity, Prop_Send, "m_iEntityQuality", qualidade);
    SetEntProp(entity, Prop_Send, "m_iEntityLevel", nivel > 0 ? nivel : 1);
    DispatchSpawn(entity);

    if (!(flags & PRESERVE_ATTRIBUTES))
        SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", 1);

    char key[8], nome[96], codigo[192];
    int atributo;
    float valor;
    for (int i = 0; i < total && i < 16; i++)
    {
        FormatEx(key, sizeof(key), "a%d", i);
        if (!m.GetValue(key, atributo) || atributo <= 0)
            continue;
        FormatEx(key, sizeof(key), "v%d", i);
        m.GetValue(key, valor);
        if (!Skynet_NomeAtributo(atributo, nome, sizeof(nome)))
            continue;
        FormatEx(codigo, sizeof(codigo), "self.AddAttribute(\"%s\", %f, -1)", nome, valor);
        SetVariantString(codigo);
        AcceptEntityInput(entity, "RunScriptCode");
    }
    return entity;
}
