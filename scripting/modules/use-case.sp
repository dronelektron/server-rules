static int g_currentPageIndex[MAXPLAYERS + 1];
static bool g_isRulesShown[MAXPLAYERS + 1];

int UseCase_GetCurrentPageIndex(int client) {
    return g_currentPageIndex[client];
}

void UseCase_ResetRulesShown(int client) {
    g_isRulesShown[client] = false;
}

void UseCase_SetRulesShownFromCookies(int client) {
    int cookieTime = Preferences_GetCookieTime(client);
    int currentTime = GetTime();
    int expiryTimeInSeconds = Variable_GetExpiryTime() * SECONDS_IN_MINUTE;
    bool isRulesCookieExpired = currentTime - cookieTime > expiryTimeInSeconds;

    g_isRulesShown[client] = !isRulesCookieExpired;
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

    g_isRulesShown[client] = true;
}

void UseCase_PlayerSpawn(int userId) {
    int client = GetClientOfUserId(userId);
    int team = GetClientTeam(client);
    bool isSpectator = team < TEAM_ALLIES;

    if (g_isRulesShown[client] || !Variable_IsShowRulesOnJoin() || isSpectator) {
        return;
    }

    CreateTimer(MENU_DELAY_SEC, Timer_ShowRules, userId);
}

public Action Timer_ShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == 0) {
        return Plugin_Stop;
    }

    UseCase_ShowRules(client, Page_First);
    EmitSoundToClient(client, MENU_SOUND_OPEN);

    return Plugin_Handled;
}
