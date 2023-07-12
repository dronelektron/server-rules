void Menu_Rules(int client) {
    Panel panel = new Panel();

    Menu_SetFormattedTitle(panel, client);
    Menu_AddSpacer(panel);
    Menu_AddRules(panel, client);
    Menu_AddSpacer(panel);
    Menu_AddButtons(panel, client);

    panel.Send(client, MenuHandler_Rules, MENU_TIME);

    delete panel;
}

public int MenuHandler_Rules(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        switch (param2) {
            case CHOICE_BACK: {
                UseCase_ShowRules(param1, Page_Previous);
                EmitSoundToClient(param1, SOUND_RULES_ITEM);
            }

            case CHOICE_NEXT: {
                UseCase_ShowRules(param1, Page_Next);
                EmitSoundToClient(param1, SOUND_RULES_ITEM);
            }

            case CHOICE_EXIT: {
                EmitSoundToClient(param1, SOUND_RULES_EXIT);
            }
        }
    }

    return 0;
}

void Menu_SetFormattedTitle(Panel panel, int client) {
    char title[TEXT_BUFFER_MAX_SIZE];

    Format(title, sizeof(title), "%T", "Server rules", client);

    panel.SetTitle(title);
}

void Menu_AddSpacer(Panel panel) {
    panel.DrawItem("", ITEMDRAW_SPACER);
}

void Menu_AddButtons(Panel panel, int client) {
    int currentPageIndex = UseCase_GetCurrentPageIndex(client);
    bool isPrevPageExists = currentPageIndex > 0;

    if (isPrevPageExists) {
        Menu_AddItem(panel, CHOICE_BACK, "%T", "Back", client);
    }

    bool isNextPageExists = currentPageIndex < (RulesStorage_Size() - 1) / RULES_PER_PAGE;

    if (isNextPageExists) {
        Menu_AddItem(panel, CHOICE_NEXT, "%T", "Next", client);
    }

    Menu_AddItem(panel, CHOICE_EXIT, "%T", "Exit", client);
}

void Menu_AddRules(Panel panel, int client) {
    int currentPageIndex = UseCase_GetCurrentPageIndex(client);
    int startRuleIndex = currentPageIndex * RULES_PER_PAGE;
    int endRuleIndex = Min(startRuleIndex + RULES_PER_PAGE, RulesStorage_Size());
    char rulePhrase[RULE_PHRASE_MAX_SIZE];

    for (int ruleIndex = startRuleIndex; ruleIndex < endRuleIndex; ruleIndex++) {
        RulesStorage_Get(ruleIndex, rulePhrase);
        Menu_AddText(panel, "%d) %T", ruleIndex + 1, rulePhrase, client);
    }
}

void Menu_AddText(Panel panel, const char[] format, any ...) {
    char text[TEXT_BUFFER_MAX_SIZE];

    VFormat(text, sizeof(text), format, 3);

    panel.DrawText(text);
}

void Menu_AddItem(Panel panel, int key, const char[] format, any ...) {
    char text[TEXT_BUFFER_MAX_SIZE];

    VFormat(text, sizeof(text), format, 4);

    panel.CurrentKey = key;
    panel.DrawItem(text);
}

int Min(int a, int b) {
    return a < b ? a : b;
}
