void RulesStorage_Load() {
    RulesList_Clear();

    char rulesPath[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, rulesPath, sizeof(rulesPath), RULES_LIST_PATH);

    KeyValues kv = new KeyValues("Phrases");

    kv.ImportFromFile(rulesPath);

    if (!kv.GotoFirstSubKey()) {
        delete kv;

        return;
    }

    char rulePhrase[RULE_PHRASE_SIZE];

    do {
        kv.GetSectionName(rulePhrase, sizeof(rulePhrase));

        RulesList_Add(rulePhrase);
    } while (kv.GotoNextKey());

    delete kv;
}
