#include <sourcemod>
#include <sdktools>

#define TEAM_ALLIES 2
#define TEAM_AXIS 3

#define MAX_TEXT_LENGTH 192
#define MAX_RULES_ON_PAGE 5

#define MENU_OPEN_SOUND "buttons/button4.wav"
#define MENU_DELAY_SEC 1.0

#define CHOICE_ACCEPT 6
#define CHOICE_DECLINE 7
#define CHOICE_PREV_PAGE 8
#define CHOICE_NEXT_PAGE 9

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Server rules for players with translation support",
    version = "0.3.0",
    url = ""
}

static ConVar g_showRulesOnJoin = null;

enum struct PlayerState {
    bool rulesShown;
    int currentPage;

    void CleanUp() {
        this.rulesShown = false;
        this.currentPage = 1;
    }
}

enum struct RulesPanelInfo {
    KeyValues ruleLinks;
    int pages;

    void LoadRules(char[] rulesPath) {
        char rulesFullPath[PLATFORM_MAX_PATH];

        BuildPath(Path_SM, rulesFullPath, sizeof(rulesFullPath), rulesPath);

        this.ruleLinks = new KeyValues("ServerRules");
        this.ruleLinks.ImportFromFile(rulesFullPath);

        if (!this.ruleLinks.GotoFirstSubKey()) {
            delete this.ruleLinks;

            return;
        }

        int rulesAmount = 0;

        do {
            rulesAmount++;
        } while (this.ruleLinks.GotoNextKey());

        this.pages = (rulesAmount / MAX_RULES_ON_PAGE + (rulesAmount % MAX_RULES_ON_PAGE == 0 ? 0 : 1));
    }

    void AddRulesToPanel(Panel panel, int page, int client) {
        char currentRuleKeyStr[MAX_TEXT_LENGTH];
        char ruleName[MAX_TEXT_LENGTH];
        int currentRuleKey = (page - 1) * MAX_RULES_ON_PAGE + 1;
        int rulesCounter = 0;

        IntToString(currentRuleKey, currentRuleKeyStr, sizeof(currentRuleKeyStr));

        this.ruleLinks.Rewind();
        this.ruleLinks.JumpToKey(currentRuleKeyStr, false);

        do {
            this.ruleLinks.GetString("name", ruleName, sizeof(ruleName));

            AddFormattedPanelText(panel, "%d) %T", currentRuleKey, ruleName, client);

            currentRuleKey++;
            rulesCounter++;
        } while (this.ruleLinks.GotoNextKey() && rulesCounter < MAX_RULES_ON_PAGE);
    }

    void UnloadRules() {
        delete this.ruleLinks;

        this.pages = 0;
    }
}

static PlayerState g_playerStates[MAXPLAYERS + 1];
static RulesPanelInfo g_rulesPanelInfo;

public void OnPluginStart() {
    LoadTranslations("server-rules-core.phrases");
    LoadTranslations("server-rules-list.phrases");

    RegConsoleCmd("sm_rules", Command_Rules, "Display menu with translated rules for a player");
    HookEvent("player_spawn", Event_PlayerSpawn);

    g_showRulesOnJoin = CreateConVar("sm_sr_show_on_join", "1", "Show rules menu when player joined the game (0 - don't show, 1 - show)");
    g_rulesPanelInfo.LoadRules("configs/server-rules.txt");

    AutoExecConfig(true, "server-rules");
}

public void OnPluginStop() {
    g_rulesPanelInfo.UnloadRules();
}

public void OnMapStart() {
    PrecacheSound(MENU_OPEN_SOUND);
}

public void OnClientConnected(int client) {
    g_playerStates[client].CleanUp();
}

public Action Command_Rules(int client, int args) {
    CreateRulesPanel(client);

    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);
    int team = GetClientTeam(client);
    bool isSpectator = (team != TEAM_ALLIES) && (team != TEAM_AXIS);

    if (g_playerStates[client].rulesShown || !IsShowRulesOnJoin() || isSpectator) {
        return;
    }

    CreateTimer(MENU_DELAY_SEC, Timer_ShowRules, userId);
}

public Action Timer_ShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    g_playerStates[client].rulesShown = true;

    CreateRulesPanel(client);
    EmitSoundToClient(client, MENU_OPEN_SOUND);

    return Plugin_Handled;
}

public int PanelHandler_Rules(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        switch (param2) {
            case CHOICE_ACCEPT: {
                g_playerStates[param1].currentPage = 1;
            }

            case CHOICE_DECLINE: {
                KickClient(param1, "%t", "You declined the rules");
            }

            case CHOICE_PREV_PAGE: {
                g_playerStates[param1].currentPage--;
                CreateRulesPanel(param1);
            }

            case CHOICE_NEXT_PAGE: {
                g_playerStates[param1].currentPage++;
                CreateRulesPanel(param1);
            }
        }
    }
}

void CreateRulesPanel(int client) {
    int currentPage = g_playerStates[client].currentPage;
    Panel panel = new Panel();

    AddFormattedPanelTitle(panel, "%T", "Server rules", client);
    AddFormattedPanelText(panel, " ");

    g_rulesPanelInfo.AddRulesToPanel(panel, currentPage, client);

    AddFormattedPanelText(panel, " ");

    panel.CurrentKey = CHOICE_ACCEPT;
    AddFormattedPanelItem(panel, ITEMDRAW_DEFAULT, "%T", "Accept", client);

    panel.CurrentKey = CHOICE_DECLINE;
    AddFormattedPanelItem(panel, ITEMDRAW_DEFAULT, "%T", "Decline", client);

    panel.CurrentKey = CHOICE_PREV_PAGE;

    if (currentPage == 1) {
        AddFormattedPanelItem(panel, ITEMDRAW_DISABLED, "%T", "Previous page", client);
    } else {
        AddFormattedPanelItem(panel, ITEMDRAW_DEFAULT, "%T", "Previous page", client);
    }

    panel.CurrentKey = CHOICE_NEXT_PAGE;

    if (currentPage == g_rulesPanelInfo.pages) {
        AddFormattedPanelItem(panel, ITEMDRAW_DISABLED, "%T", "Next page", client);
    } else {
        AddFormattedPanelItem(panel, ITEMDRAW_DEFAULT, "%T", "Next page", client);
    }

    panel.Send(client, PanelHandler_Rules, MENU_TIME_FOREVER);

    delete panel;
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

bool IsShowRulesOnJoin() {
    return g_showRulesOnJoin.IntValue == 1;
}
