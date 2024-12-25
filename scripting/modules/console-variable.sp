static ConVar g_showRulesOnJoin = null;
static ConVar g_rulesExpiryTime = null;

void Variable_Create() {
    g_showRulesOnJoin = CreateConVar("sm_serverrules_show_on_join", "1", "Show the menu with rules (On - 1, Off - 0) on the first spawn");
    g_rulesExpiryTime = CreateConVar("sm_serverrules_expiry_time", "10080", "Rules expiry time (in minutes)");
}

bool Variable_ShowRulesOnJoin() {
    return g_showRulesOnJoin.IntValue == 1;
}

int Variable_RulesExpiryTime() {
    return g_rulesExpiryTime.IntValue;
}
