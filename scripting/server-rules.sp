#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include "server-rules/cookie"
#include "server-rules/menu"
#include "server-rules/rules-list"
#include "server-rules/rules-storage"
#include "server-rules/sound"
#include "server-rules/use-case"

#include "modules/console-command.sp"
#include "modules/console-variable.sp"
#include "modules/cookie.sp"
#include "modules/event.sp"
#include "modules/math.sp"
#include "modules/menu.sp"
#include "modules/rules-list.sp"
#include "modules/rules-storage.sp"
#include "modules/sound.sp"
#include "modules/use-case.sp"

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Server rules for players with translation support",
    version = "1.0.6",
    url = "https://github.com/dronelektron/server-rules"
};

public void OnPluginStart() {
    Command_Create();
    Variable_Create();
    Cookie_Create();
    Event_Create();
    RulesList_Create();
    CookieLateLoad();
    LoadTranslations("server-rules-core.phrases");
    LoadTranslations("server-rules-list.phrases");
    AutoExecConfig(_, "server-rules");
}

public void OnMapStart() {
    Sound_Precache();
    RulesStorage_Load();
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
