void Command_Create() {
    RegConsoleCmd("sm_rules", Command_Rules, "Show a menu with rules");
}

public Action Command_Rules(int client, int args) {
    Menu_Rules(client);

    return Plugin_Handled;
}
