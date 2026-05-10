//Gingerbeard @ November 24, 2024

funcdef void onNewDayHourHandle(CRules@, u16);

void addOnNewDayHour(CRules@ this, onNewDayHourHandle@ handle)
{
	if (!isServer()) return;

	dictionary@ dict;
	if (!this.get("onNewDayHour handles", @dict))
	{
		dictionary temp;
		this.set("onNewDayHour handles", temp);
		this.get("onNewDayHour handles", @dict);
	}

	const string script = getFilenameWithoutPath(getCurrentScriptName());
	dict.set(script, handle);
}
