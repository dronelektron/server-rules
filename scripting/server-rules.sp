#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include "sr/cookie"
#include "sr/menu"
#include "sr/rules-storage"
#include "sr/use-case"

#include "modules/console-command.sp"
#include "modules/console-variable.sp"
#include "modules/cookie.sp"
#include "modules/event.sp"
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
    Event_Create();
    RulesStorage_Load();
    CookieLateLoad();
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

static void CookieLateLoad() {
    for (int i = 1; i <= MaxClients; i++) {
        if (AreClientCookiesCached(i)) {
            OnClientCookiesCached(i);
        }
    }
}
