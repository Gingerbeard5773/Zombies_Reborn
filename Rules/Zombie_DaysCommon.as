//Gingerbeard @ November 24, 2024

funcdef void onNewDayHourHandle(CRules@, u16, u16);

//shorthand funcdef setting
void addOnNewDayHour(CRules@ this, onNewDayHourHandle@ handle)   { this.push("onNewDayHour handles", @handle); }
