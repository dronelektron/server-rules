static ArrayList g_rules;

void RulesList_Create() {
    int blockSize = ByteCountToCells(RULE_PHRASE_SIZE);

    g_rules = new ArrayList(blockSize);
}

void RulesList_Clear() {
    g_rules.Clear();
}

int RulesList_Size() {
    return g_rules.Length;
}

void RulesList_Add(const char[] phrase) {
    g_rules.PushString(phrase);
}

void RulesList_Get(int index, char[] phrase) {
    g_rules.GetString(index, phrase, RULE_PHRASE_SIZE);
}
