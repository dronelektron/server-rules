static ArrayList g_rules = null;

int RulesStorage_Size() {
    return g_rules.Length;
}

void RulesStorage_Get(int index, char[] rulePhrase) {
    g_rules.GetString(index, rulePhrase, RULE_PHRASE_MAX_SIZE);
}

void RulesStorage_Load() {
    char rulesPath[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, rulesPath, sizeof(rulesPath), "translations/server-rules-list.phrases.txt");

    int blockSize = ByteCountToCells(RULE_PHRASE_MAX_SIZE);

    g_rules = new ArrayList(blockSize);

    KeyValues kv = new KeyValues("Phrases");

    kv.ImportFromFile(rulesPath);

    if (!kv.GotoFirstSubKey()) {
        delete kv;

        return;
    }

    char rulePhrase[RULE_PHRASE_MAX_SIZE];

    do {
        kv.GetSectionName(rulePhrase, sizeof(rulePhrase));
        g_rules.PushString(rulePhrase);
    } while (kv.GotoNextKey());

    delete kv;
}
