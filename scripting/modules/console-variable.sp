static ConVar g_showRulesOnJoin = null;
static ConVar g_rulesExpiryTime = null;

void Variable_Create() {
    g_showRulesOnJoin = CreateConVar("sm_serverrules_show_on_join", "1", "Show (1 - on, 0 - off) rules panel when a player has joined the server");
    g_rulesExpiryTime = CreateConVar("sm_serverrules_expiry_time", "1440", "Rules expiry time (in minutes)");
}

bool Variable_ShowRulesOnJoin() {
    return g_showRulesOnJoin.IntValue == 1;
}

int Variable_GetExpiryTime() {
    return g_rulesExpiryTime.IntValue;
}
