void Command_Create() {
    RegConsoleCmd("sm_rules", Command_Rules, "Show panel with translated rules for player");
}

public Action Command_Rules(int client, int args) {
    UseCase_ShowRules(client, Page_First);

    return Plugin_Handled;
}
