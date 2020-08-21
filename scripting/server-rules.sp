#include <sourcemod>

#define RULE_DESCRIPTION_SUFFIX " (desc)"
#define MAX_TEXT_LENGTH 192

#define CHOICE_DESCRIPTION "desc"
#define CHOICE_BACK 8

static char g_rulesPath[PLATFORM_MAX_PATH];

public Plugin myinfo = {
    name = "Server rules",
    author = "Dron-elektron",
    description = "Localized server rules for players",
    version = "0.1.0",
    url = ""
}

public void OnPluginStart() {
    LoadTranslations("server-rules-core.phrases");
    LoadTranslations("server-rules-list.phrases");

    RegConsoleCmd("sm_rules", Command_Rules, "Displays menu with localized rules for a player");

    BuildPath(Path_SM, g_rulesPath, sizeof(g_rulesPath), "configs/server-rules.txt");
}

public Action Command_Rules(int client, int args) {
    CreateRulesMenu(client);

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
