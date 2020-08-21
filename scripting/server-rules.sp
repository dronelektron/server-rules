#include <sourcemod>
#include <sdktools>

#define RULE_DESCRIPTION_SUFFIX " (desc)"
#define MAX_TEXT_LENGTH 192
#define MENU_OPEN_SOUND "buttons/button4.wav"

#define CHOICE_DESCRIPTION "desc"
#define CHOICE_BACK 8

#define TEAM_ALLIES 2
#define TEAM_AXIS 3

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Localized server rules for players",
    version = "0.2.0",
    url = ""
}

static ConVar g_showRulesOnJoin = null;

static char g_rulesPath[PLATFORM_MAX_PATH];
static bool g_rulesShown[MAXPLAYERS + 1] = {false, ...};

public void OnPluginStart() {
    LoadTranslations("server-rules-core.phrases");
    LoadTranslations("server-rules-list.phrases");

    RegConsoleCmd("sm_rules", Command_Rules, "Displays menu with localized rules for a player");
    HookEvent("player_spawn", Event_PlayerSpawn);
    BuildPath(Path_SM, g_rulesPath, sizeof(g_rulesPath), "configs/server-rules.txt");

    g_showRulesOnJoin = CreateConVar("sm_sr_show_on_join", "1", "Show rules menu when player joined the game");

    AutoExecConfig(true, "server-rules");
}

public void OnMapStart() {
    PrecacheSound(MENU_OPEN_SOUND);
}

public void OnClientConnected(int client) {
    g_rulesShown[client] = false;
}

public Action Command_Rules(int client, int args) {
    CreateRulesMenu(client);

    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);
    int team = GetClientTeam(client);
    bool isSpectator = (team != TEAM_ALLIES) && (team != TEAM_AXIS);

    if (g_rulesShown[client] || !IsShowRulesWhenConnected() || isSpectator) {
        return;
    }

    CreateTimer(1.0, Timer_ShowRules, userId);
}

public Action Timer_ShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    g_rulesShown[client] = true;

    CreateRulesMenu(client);
    EmitSoundToClient(client, MENU_OPEN_SOUND);

    return Plugin_Handled;
}

public int MenuHandler_Rules(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char option[MAX_TEXT_LENGTH];

            menu.GetItem(param2, option, sizeof(option));
            CreateRuleDescriptionPanel(param1, option);
        }

        case MenuAction_End: {
            delete menu;
        }
    }
}

public int PanelHandler_RuleDescription(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            if (param2 == CHOICE_BACK) {
                CreateRulesMenu(param1);
            }
        }
    }
}

void CreateRulesMenu(int client) {
    Menu menu = new Menu(MenuHandler_Rules);

    menu.SetTitle("%T", "Server rules", client);

    AddRulesToMenu(menu, client);

    menu.Display(client, MENU_TIME_FOREVER);
}

void CreateRuleDescriptionPanel(int client, char[] phrase) {
    Panel panel = new Panel();
    char ruleDesc[MAX_TEXT_LENGTH];

    Format(ruleDesc, sizeof(ruleDesc), "%s%s", phrase, RULE_DESCRIPTION_SUFFIX);
    AddFormattedPanelTitle(panel, "%T", phrase, client);
    AddFormattedPanelItem(panel, ITEMDRAW_SPACER, "");
    AddFormattedPanelText(panel, "%T", ruleDesc, client);
    AddFormattedPanelItem(panel, ITEMDRAW_SPACER, "");

    panel.CurrentKey = CHOICE_BACK;
    AddFormattedPanelItem(panel, ITEMDRAW_CONTROL, "%T", "Back", client);

    panel.CurrentKey = 10;
    AddFormattedPanelItem(panel, ITEMDRAW_CONTROL, "%T", "Exit", client);

    panel.Send(client, PanelHandler_RuleDescription, MENU_TIME_FOREVER);

    delete panel;
}

void AddRulesToMenu(Menu menu, int client) {
    KeyValues kv = new KeyValues("ServerRules");

    kv.ImportFromFile(g_rulesPath);

    if (!kv.GotoFirstSubKey()) {
        delete kv;

        return;
    }

    char ruleName[MAX_TEXT_LENGTH];

    do {
        kv.GetString("name", ruleName, sizeof(ruleName));

        AddFormattedMenuItem(menu, ruleName, "%T", ruleName, client);
    } while (kv.GotoNextKey());

    delete kv;
}

void AddFormattedMenuItem(Menu menu, const char[] option, const char[] format, any ...) {
    char text[MAX_TEXT_LENGTH];

    VFormat(text, sizeof(text), format, 4);
    menu.AddItem(option, text);
}

void AddFormattedPanelTitle(Panel panel, const char[] format, any ...) {
    char text[MAX_TEXT_LENGTH];

    VFormat(text, sizeof(text), format, 3);
    panel.SetTitle(text);
}

void AddFormattedPanelText(Panel panel, const char[] format, any ...) {
    char text[MAX_TEXT_LENGTH];

    VFormat(text, sizeof(text), format, 3);
    panel.DrawText(text);
}

void AddFormattedPanelItem(Panel panel, int style, const char[] format, any ...) {
    char text[MAX_TEXT_LENGTH];

    VFormat(text, sizeof(text), format, 4);
    panel.DrawItem(text, style);
}

bool IsShowRulesWhenConnected() {
    return g_showRulesOnJoin.IntValue == 1;
}
