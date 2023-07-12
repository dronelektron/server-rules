#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#include "sr/cookie"
#include "sr/menu"
#include "sr/rules-storage"
#include "sr/use-case"

#include "modules/console-command.sp"
#include "modules/console-variable.sp"
#include "modules/cookie.sp"
#include "modules/menu.sp"
#include "modules/rules-storage.sp"
#include "modules/use-case.sp"

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Server rules for players with translation support",
    version = "1.0.5",
    url = "https://github.com/dronelektron/server-rules"
};

public void OnPluginStart() {
    Command_Create();
    Variable_Create();
    Cookie_Create();
    RulesStorage_Load();
    CookieLateLoad();
    HookEvent("player_spawn", Event_PlayerSpawn);
    LoadTranslations("server-rules-core.phrases");
    LoadTranslations("server-rules-list.phrases");
    AutoExecConfig(true, "server-rules");
}

public void OnPluginEnd() {
    RulesStorage_Unload();
}

public void OnMapStart() {
    PrecacheSound(MENU_SOUND_OPEN);
    PrecacheSound(MENU_SOUND_ITEM);
    PrecacheSound(MENU_SOUND_EXIT);
}

public void OnClientCookiesCached(int client) {
    Cookie_Load(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);

    UseCase_OnPlayerSpawn(client);
}

static void CookieLateLoad() {
    for (int i = 1; i <= MaxClients; i++) {
        if (AreClientCookiesCached(i)) {
            OnClientCookiesCached(i);
        }
    }
}
