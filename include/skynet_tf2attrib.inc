// SKYNET: replacement for tf2attributes (which does not work on the 64-bit server). Uses TF2's own VScript.
#if defined _skynet_tf2attrib_included
 #endinput
#endif
#define _skynet_tf2attrib_included
#define _tf2attributes_included
#include <sdktools>
#include <skynet_atributos>

stock void Skynet_Attrib_Script(int entity, const char[] codigo)
{
    SetVariantString(codigo);
    AcceptEntityInput(entity, "RunScriptCode");
}

stock bool TF2Attrib_SetByName(int entity, const char[] name, float value)
{
    char c[192];
    if (entity >= 1 && entity <= MaxClients)
        FormatEx(c, sizeof(c), "self.AddCustomAttribute(\"%s\", %f, -1)", name, value);
    else
        FormatEx(c, sizeof(c), "self.AddAttribute(\"%s\", %f, -1)", name, value);
    Skynet_Attrib_Script(entity, c);
    return true;
}

stock bool TF2Attrib_SetByDefIndex(int entity, int index, float value)
{
    char nome[96];
    if (!Skynet_NomeAtributo(index, nome, sizeof(nome)))
        return false;
    return TF2Attrib_SetByName(entity, nome, value);
}

stock bool TF2Attrib_RemoveByName(int entity, const char[] name)
{
    char c[160];
    if (entity >= 1 && entity <= MaxClients)
        FormatEx(c, sizeof(c), "self.RemoveCustomAttribute(\"%s\")", name);
    else
        FormatEx(c, sizeof(c), "self.RemoveAttribute(\"%s\")", name);
    Skynet_Attrib_Script(entity, c);
    return true;
}

stock bool TF2Attrib_RemoveByDefIndex(int entity, int index)
{
    char nome[96];
    if (!Skynet_NomeAtributo(index, nome, sizeof(nome)))
        return false;
    return TF2Attrib_RemoveByName(entity, nome);
}

stock Address TF2Attrib_GetByDefIndex(int entity, int index) { return Address_Null; }
stock Address TF2Attrib_GetByName(int entity, const char[] name) { return Address_Null; }
stock float TF2Attrib_GetValue(Address attrib) { return 0.0; }
stock bool TF2Attrib_ClearCache(int entity) { return true; }
