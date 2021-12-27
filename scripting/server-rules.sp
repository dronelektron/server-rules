#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define TEAM_ALLIES 2

#define TEXT_MAX_SIZE 256
#define TEXT_BUFFER_MAX_SIZE (TEXT_MAX_SIZE * 4)

#define RULES_PER_PAGE 5
#define SECONDS_IN_MINUTE 60
#define MENU_DELAY_SEC 0.5
#define MENU_TIME 20

#define MENU_SOUND_OPEN "buttons/button4.wav"
#define MENU_SOUND_ITEM "buttons/button14.wav"
#define MENU_SOUND_EXIT "buttons/combine_button7.wav"

#define CHOICE_BACK 8
#define CHOICE_NEXT 9
#define CHOICE_EXIT 10

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Server rules for players with translation support",
    version = "1.0.3",
    url = ""
};

enum Page {
    Page_First,
    Page_Previous,
    Page_Next
};

ConVar g_showRulesOnJoin = null;
ConVar g_rulesExpiryTime = null;
Handle g_rulesCookie = null;
ArrayList g_rules = null;

int g_currentPageIndex[MAXPLAYERS + 1];
bool g_isRulesShown[MAXPLAYERS + 1];

public void OnPluginStart() {
    g_showRulesOnJoin = CreateConVar("sm_serverrules_show_on_join", "1", "Show (1 - on, 0 - off) rules panel when a player has joined the server");
    g_rulesExpiryTime = CreateConVar("sm_serverrules_expiry_time", "1440", "Rules expiry time (in minutes)");
    g_rulesCookie = RegClientCookie("serverrules_shown", "Server rules have been shown", CookieAccess_Private);

    CookiesLateLoad();
    LoadRules();
    LoadTranslations("server-rules-core.phrases");
    LoadTranslations("server-rules-list.phrases");
    HookEvent("player_spawn", Event_PlayerSpawn);
    RegConsoleCmd("sm_rules", Command_Rules, "Show panel with translated rules for player");
    AutoExecConfig(true, "server-rules");
}

public void OnPluginEnd() {
    UnloadRules();
}

public void OnMapStart() {
    PrecacheSound(MENU_SOUND_OPEN);
    PrecacheSound(MENU_SOUND_ITEM);
    PrecacheSound(MENU_SOUND_EXIT);
}

public void OnClientConnected(int client) {
    g_isRulesShown[client] = false;
}

public void OnClientDisconnect(int client) {
    if (AreClientCookiesCached(client)) {
        SetClientCookie(client, g_rulesCookie, "");
    }
}

public void OnClientCookiesCached(int client) {
    g_isRulesShown[client] = !IsRulesCookieExpired(client);
}

public Action Command_Rules(int client, int args) {
    ShowRulesPanel(client, Page_First);

    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);
    int team = GetClientTeam(client);
    bool isSpectator = team < TEAM_ALLIES;

    if (g_isRulesShown[client] || !IsShowRulesOnJoin() || isSpectator) {
        return;
    }

    CreateTimer(MENU_DELAY_SEC, Timer_ShowRules, userId);
}

public Action Timer_ShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    ShowRulesPanel(client, Page_First);
    EmitSoundToClient(client, MENU_SOUND_OPEN);

    return Plugin_Handled;
}

void CookiesLateLoad() {
    for (int i = 1; i <= MaxClients; i++) {
        if (AreClientCookiesCached(i)) {
            OnClientCookiesCached(i);
        }
    }
}

bool IsRulesCookieExpired(int client) {
    int cookieTime = GetClientCookieTime(client, g_rulesCookie);
    int currentTime = GetTime();
    int expiryTimeInSeconds = GetExpiryTime() * SECONDS_IN_MINUTE;

    return currentTime - cookieTime > expiryTimeInSeconds;
}

void LoadRules() {
    char rulesPath[PLATFORM_MAX_PATH];

    GetRulesPath(rulesPath, sizeof(rulesPath));

    int blockSize = ByteCountToCells(TEXT_MAX_SIZE);

    g_rules = new ArrayList(blockSize);

    KeyValues kv = new KeyValues("Phrases");

    kv.ImportFromFile(rulesPath);

    if (!kv.GotoFirstSubKey()) {
        delete kv;

        return;
    }

    char rulePhrase[TEXT_MAX_SIZE];

    do {
        kv.GetSectionName(rulePhrase, sizeof(rulePhrase));
        g_rules.PushString(rulePhrase);
    } while (kv.GotoNextKey());

    delete kv;
}

void UnloadRules() {
    delete g_rules;
}

void GetRulesPath(char[] rulesPath, int maxLength) {
    BuildPath(Path_SM, rulesPath, maxLength, "translations/server-rules-list.phrases.txt");
}

void ShowRulesPanel(int client, Page page) {
    switch (page) {
        case Page_First: {
            g_currentPageIndex[client] = 0;
        }

        case Page_Previous: {
            g_currentPageIndex[client]--;
        }

        case Page_Next: {
            g_currentPageIndex[client]++;
        }
    }

    CreateRulesPanel(client);

    g_isRulesShown[client] = true;
}

void CreateRulesPanel(int client) {
    Panel panel = new Panel();

    SetFormattedTitleForPanel(panel, client);
    AddSpacerToPanel(panel);
    AddRulesToPanel(panel, client);
    AddSpacerToPanel(panel);
    AddButtonsToPanel(panel, client);

    panel.Send(client, PanelHandler_Rules, MENU_TIME);

    delete panel;
}

public int PanelHandler_Rules(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        switch (param2) {
            case CHOICE_BACK: {
                ShowRulesPanel(param1, Page_Previous);
                EmitSoundToClient(param1, MENU_SOUND_ITEM);
            }

            case CHOICE_NEXT: {
                ShowRulesPanel(param1, Page_Next);
                EmitSoundToClient(param1, MENU_SOUND_ITEM);
            }

            case CHOICE_EXIT: {
                EmitSoundToClient(param1, MENU_SOUND_EXIT);
            }
        }
    }

    return 0;
}

void AddRulesToPanel(Panel panel, int client) {
    int currentPageIndex = g_currentPageIndex[client];
    int startRuleIndex = currentPageIndex * RULES_PER_PAGE;
    int endRuleIndex = Min(startRuleIndex + RULES_PER_PAGE, g_rules.Length);
    char rulePhrase[TEXT_MAX_SIZE];

    for (int ruleIndex = startRuleIndex; ruleIndex < endRuleIndex; ruleIndex++) {
        g_rules.GetString(ruleIndex, rulePhrase, sizeof(rulePhrase));

        AddFormattedTextToPanel(panel, "%d) %T", ruleIndex + 1, rulePhrase, client);
    }
}

void AddButtonsToPanel(Panel panel, int client) {
    int currentPageIndex = g_currentPageIndex[client];
    bool isPrevPageExists = currentPageIndex > 0;

    if (isPrevPageExists) {
        AddFormattedItemToPanel(panel, CHOICE_BACK, "%T", "Back", client);
    }

    bool isNextPageExists = currentPageIndex < (g_rules.Length - 1) / RULES_PER_PAGE;

    if (isNextPageExists) {
        AddFormattedItemToPanel(panel, CHOICE_NEXT, "%T", "Next", client);
    }

    AddFormattedItemToPanel(panel, CHOICE_EXIT, "%T", "Exit", client);
}

void SetFormattedTitleForPanel(Panel panel, int client) {
    char title[TEXT_BUFFER_MAX_SIZE];

    Format(title, sizeof(title), "%T", "Server rules", client);

    panel.SetTitle(title);
}

void AddFormattedTextToPanel(Panel panel, const char[] format, any ...) {
    char text[TEXT_BUFFER_MAX_SIZE];

    VFormat(text, sizeof(text), format, 3);

    panel.DrawText(text);
}

void AddFormattedItemToPanel(Panel panel, int key, const char[] format, any ...) {
    char text[TEXT_BUFFER_MAX_SIZE];

    VFormat(text, sizeof(text), format, 4);

    panel.CurrentKey = key;
    panel.DrawItem(text);
}

void AddSpacerToPanel(Panel panel) {
    panel.DrawItem("", ITEMDRAW_SPACER);
}

int Min(int a, int b) {
    return a < b ? a : b;
}

bool IsShowRulesOnJoin() {
    return g_showRulesOnJoin.IntValue == 1;
}

int GetExpiryTime() {
    return g_rulesExpiryTime.IntValue;
}
