static int g_pageIndex[MAXPLAYERS + 1];

void Menu_Rules(int client, bool firstTime = true) {
    if (firstTime) {
        g_pageIndex[client] = 0;
    }

    Panel panel = new Panel();

    Menu_SetFormattedTitle(panel, client);
    Menu_AddSpacer(panel);
    Menu_AddRules(panel, client);
    Menu_AddSpacer(panel);
    Menu_AddButtons(panel, client);

    panel.Send(client, MenuHandler_Rules, MENU_TIME_FOREVER);

    delete panel;
}

public int MenuHandler_Rules(Menu menu, MenuAction action, int param1, int param2) {
    PrintToServer("[DEBUG] ==== MenuHandler_Rules ====");
    PrintToServer("[DEBUG] param1: %d", param1);
    PrintToServer("[DEBUG] param2: %d", param2);

    if (action == MenuAction_Select) {
        if (param2 == CHOICE_EXIT) {
            EmitSoundToClient(param1, SOUND_RULES_EXIT);
        } else {
            g_pageIndex[param1] += param2 == CHOICE_BACK ? -1 : 1;

            Menu_Rules(param1, FIRST_TIME_NO);
            EmitSoundToClient(param1, SOUND_RULES_ITEM);
        }
    }

    return 0;
}

void Menu_SetFormattedTitle(Panel panel, int client) {
    char title[ITEM_SIZE];

    Format(title, sizeof(title), "%T", "Server rules", client);

    panel.SetTitle(title);
}

void Menu_AddSpacer(Panel panel) {
    panel.DrawItem("", ITEMDRAW_SPACER);
}

void Menu_AddButtons(Panel panel, int client) {
    int currentPageIndex = g_pageIndex[client];
    bool isPrevPageExists = currentPageIndex > 0;

    if (isPrevPageExists) {
        Menu_AddItem(panel, CHOICE_BACK, "%T", ITEM_BACK, client);
    }

    bool isNextPageExists = (currentPageIndex + 1) < GetPagesAmount();

    if (isNextPageExists) {
        Menu_AddItem(panel, CHOICE_NEXT, "%T", ITEM_NEXT, client);
    }

    Menu_AddItem(panel, CHOICE_EXIT, "%T", ITEM_EXIT, client);
}

void Menu_AddRules(Panel panel, int client) {
    int currentPageIndex = g_pageIndex[client];
    int startRuleIndex = currentPageIndex * RULES_PER_PAGE;
    int endRuleIndex = Math_Min(startRuleIndex + RULES_PER_PAGE, RulesList_Size());
    char rulePhrase[RULE_PHRASE_SIZE];

    for (int ruleIndex = startRuleIndex; ruleIndex < endRuleIndex; ruleIndex++) {
        RulesList_Get(ruleIndex, rulePhrase);
        Menu_AddText(panel, "%d) %T", ruleIndex + 1, rulePhrase, client);
    }
}

void Menu_AddText(Panel panel, const char[] format, any ...) {
    char text[ITEM_SIZE];

    VFormat(text, sizeof(text), format, 3);

    panel.DrawText(text);
}

void Menu_AddItem(Panel panel, int key, const char[] format, any ...) {
    char text[ITEM_SIZE];

    VFormat(text, sizeof(text), format, 4);

    panel.CurrentKey = key;
    panel.DrawItem(text);
}

static int GetPagesAmount() {
    int rulesAmount = RulesList_Size();

    if (rulesAmount == 0) {
        return 0;
    }

    return 1 + (rulesAmount - 1) / RULES_PER_PAGE;
}
