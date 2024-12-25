void Timer_ShowRules(int client) {
    int userId = GetClientUserId(client);

    CreateTimer(TIMER_RULES_DELAY, Timer_OnShowRules, userId, TIMER_RULES_FLAGS);
}

public Action Timer_OnShowRules(Handle timer, int userId) {
    int client = GetClientOfUserId(userId);

    if (client == INVALID_CLIENT) {
        return Plugin_Continue;
    }

    Menu_Rules(client);
    Cookie_SetRulesShown(client, COOKIE_RULES_SHOWN_YES);
    EmitSoundToClient(client, SOUND_RULES_OPEN);

    return Plugin_Continue;
}
