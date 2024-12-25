void UseCase_OnPlayerSpawn(int client) {
    if (!Variable_ShowRulesOnJoin() || Cookie_IsRulesShown(client) || IsSpectator(client)) {
        return;
    }

    Timer_ShowRules(client);
}

static bool IsSpectator(int client) {
    int team = GetClientTeam(client);

    return team < TEAM_ALLIES;
}
