void UseCase_OnPlayerSpawn(int client) {
    int team = GetClientTeam(client);
    bool isSpectator = team < TEAM_ALLIES;

    if (!Variable_ShowRulesOnJoin() || Cookie_IsRulesShown(client) || isSpectator) {
        return;
    }

    Timer_ShowRules(client);
}
