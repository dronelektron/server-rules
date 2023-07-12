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

    Menu_Rules(client);
    Cookie_SetRulesShown(client, COOKIE_RULES_SHOWN_YES);
    EmitSoundToClient(client, SOUND_RULES_OPEN);

    return Plugin_Handled;
}
