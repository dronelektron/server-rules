static Handle g_rulesCookie;
static bool g_rulesShown[MAXPLAYERS + 1];

void Cookie_Create() {
    g_rulesCookie = RegClientCookie("serverrules_shown", "Server rules have been shown", CookieAccess_Private);
}

void Cookie_Load(int client) {
    char rulesShown[COOKIE_RULES_SHOWN_SIZE];

    GetClientCookie(client, g_rulesCookie, rulesShown, sizeof(rulesShown));

    if (rulesShown[0] == NULL_CHARACTER || Cookie_IsExpired(client)) {
        Cookie_SetRulesShown(client, COOKIE_RULES_SHOWN_NO);
    } else {
        Cookie_SetRulesShown(client, COOKIE_RULES_SHOWN_YES);
    }
}

bool Cookie_IsRulesShown(int client) {
    return g_rulesShown[client];
}

void Cookie_SetRulesShown(int client, const char[] rulesShown) {
    SetClientCookie(client, g_rulesCookie, rulesShown);
    Cookie_UpdateRulesShown(client, rulesShown);
}

static bool Cookie_IsExpired(int client) {
    int cookieTime = GetClientCookieTime(client, g_rulesCookie);
    int currentTime = GetTime();
    int expiryTimeInSeconds = Variable_RulesExpiryTime() * SECONDS_IN_MINUTE;

    return currentTime - cookieTime > expiryTimeInSeconds;
}

static void Cookie_UpdateRulesShown(int client, const char[] rulesShown) {
    g_rulesShown[client] = StrEqual(rulesShown, COOKIE_RULES_SHOWN_YES);
}
