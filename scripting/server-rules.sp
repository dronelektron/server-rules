#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define TEAM_ALLIES 2
#define TEAM_AXIS 3

#define MAX_TEXT_LENGTH 192
#define MAX_RULES_ON_PAGE 5

#define MENU_OPEN_SOUND "buttons/button4.wav"
#define MENU_SELECT_SOUND "buttons/button14.wav"
#define MENU_EXIT_SOUND "buttons/combine_button7.wav"
#define MENU_DELAY_SEC 1.0

#define CHOICE_ACCEPT 6
#define CHOICE_DECLINE 7
#define CHOICE_PREV_PAGE 8
#define CHOICE_NEXT_PAGE 9
#define CHOICE_EXIT 10

#define SECONDS_IN_MINUTE 60

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Server rules for players with translation support",
    version = "0.4.0",
    url = ""
}

static ConVar g_showRulesOnJoin = null;
static ConVar g_rulesExpiryTime = null;

static Handle g_rulesCookie = null;

enum struct PlayerState {
    bool rulesAccepted;
    int currentPage;

    void CleanUp() {
        this.rulesAccepted = false;
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
    g_rulesExpiryTime = CreateConVar("sm_sr_expiry_time", "60", "Rules expiry time (in minutes)");
    g_rulesCookie = RegClientCookie("server-rules-accepted", "Did the player accept the rules of the server", CookieAccess_Private);
    g_rulesPanelInfo.LoadRules("configs/server-rules.txt");

    AutoExecConfig(true, "server-rules");
}

public void OnPluginStop() {
    g_rulesPanelInfo.UnloadRules();
}

public void OnMapStart() {
    PrecacheSound(MENU_OPEN_SOUND);
    PrecacheSound(MENU_SELECT_SOUND);
    PrecacheSound(MENU_EXIT_SOUND);
}

public void OnClientConnected(int client) {
    g_playerStates[client].CleanUp();
}

public void OnClientDisconnect(int client) {
    SetClientCookie(client, g_rulesCookie, "");
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

    if (g_playerStates[client].rulesAccepted || !IsShowRulesOnJoin() || isSpectator) {
        return;
    }

    CreateTimer(MENU_DELAY_SEC, Timer_ShowRules, userId);
}

public Action Timer_ShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    if (!AreClientCookiesCached(client) || IsRulesCookieExpired(client)) {
        CreateRulesPanel(client);
        EmitSoundToClient(client, MENU_OPEN_SOUND);
    }

    return Plugin_Handled;
}

public int PanelHandler_Rules(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        switch (param2) {
            case CHOICE_ACCEPT: {
                g_playerStates[param1].rulesAccepted = true;
                g_playerStates[param1].currentPage = 1;
                EmitSoundToClient(param1, MENU_SELECT_SOUND);
            }

            case CHOICE_DECLINE: {
                KickClient(param1, "%t", "You declined the rules");
            }

            case CHOICE_PREV_PAGE: {
                g_playerStates[param1].currentPage--;
                CreateRulesPanel(param1);
                EmitSoundToClient(param1, MENU_SELECT_SOUND);
            }

            case CHOICE_NEXT_PAGE: {
                g_playerStates[param1].currentPage++;
                CreateRulesPanel(param1);
                EmitSoundToClient(param1, MENU_SELECT_SOUND);
            }

            case CHOICE_EXIT: {
                g_playerStates[param1].currentPage = 1;
                EmitSoundToClient(param1, MENU_EXIT_SOUND);
            }
        }
    }
}

void CreateRulesPanel(int client) {
    int style;
    int currentPage = g_playerStates[client].currentPage;
    bool rulesAccepted = g_playerStates[client].rulesAccepted;
    Panel panel = new Panel();

    AddFormattedPanelTitle(panel, "%T", "Server rules", client);
    AddFormattedPanelText(panel, " ");

    g_rulesPanelInfo.AddRulesToPanel(panel, currentPage, client);

    AddFormattedPanelText(panel, " ");

    panel.CurrentKey = CHOICE_ACCEPT;

    if (rulesAccepted) {
        style = ITEMDRAW_DISABLED;
    } else {
        style = ITEMDRAW_DEFAULT;
    }

    AddFormattedPanelItem(panel, style, "%T", "Accept", client);

    panel.CurrentKey = CHOICE_DECLINE;

    if (rulesAccepted) {
        style = ITEMDRAW_DISABLED;
    } else {
        style = ITEMDRAW_DEFAULT;
    }

    AddFormattedPanelItem(panel, style, "%T", "Decline", client);

    panel.CurrentKey = CHOICE_PREV_PAGE;

    if (currentPage == 1) {
        style = ITEMDRAW_DISABLED;
    } else {
        style = ITEMDRAW_DEFAULT;
    }

    AddFormattedPanelItem(panel, style, "%T", "Previous page", client);

    panel.CurrentKey = CHOICE_NEXT_PAGE;

    if (currentPage == g_rulesPanelInfo.pages) {
        style = ITEMDRAW_DISABLED;
    } else {
        style = ITEMDRAW_DEFAULT;
    }

    AddFormattedPanelItem(panel, style, "%T", "Next page", client);

    if (rulesAccepted) {
        panel.CurrentKey = CHOICE_EXIT;
        AddFormattedPanelItem(panel, ITEMDRAW_DEFAULT, "%T", "Exit", client);
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

int GetExpiryTime() {
    return g_rulesExpiryTime.IntValue;
}

bool IsRulesCookieExpired(int client) {
    int cookieTime = GetClientCookieTime(client, g_rulesCookie);
    int currentTime = GetTime();
    int expiryTimeInSeconds = GetExpiryTime() * SECONDS_IN_MINUTE;

    return currentTime - cookieTime > expiryTimeInSeconds;
}
