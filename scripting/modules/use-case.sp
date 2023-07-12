static int g_currentPageIndex[MAXPLAYERS + 1];

int UseCase_GetCurrentPageIndex(int client) {
    return g_currentPageIndex[client];
}

void UseCase_ShowRules(int client, Page page) {
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

    Menu_Rules(client);
    Cookie_SetRulesShown(client, COOKIE_RULES_SHOWN_YES);
}

void UseCase_OnPlayerSpawn(int client) {
    int team = GetClientTeam(client);
    bool isSpectator = team < TEAM_ALLIES;

    if (!Variable_ShowRulesOnJoin() || Cookie_IsRulesShown(client) || isSpectator) {
        return;
    }

    int userId = GetClientUserId(client);

    CreateTimer(MENU_DELAY_SECONDS, Timer_ShowRules, userId);
}

public Action Timer_ShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Handled;
    }

    UseCase_ShowRules(client, Page_First);
    EmitSoundToClient(client, SOUND_RULES_OPEN);

    return Plugin_Handled;
}
