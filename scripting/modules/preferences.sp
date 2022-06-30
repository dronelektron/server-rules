static Handle g_rulesCookie = null;

void Preferences_Create() {
    g_rulesCookie = RegClientCookie("serverrules_shown", "Server rules have been shown", CookieAccess_Private);
}

void Preferences_Clear(int client) {
    if (AreClientCookiesCached(client)) {
        SetClientCookie(client, g_rulesCookie, "");
    }
}

int Preferences_GetCookieTime(int client) {
    return GetClientCookieTime(client, g_rulesCookie);
}
