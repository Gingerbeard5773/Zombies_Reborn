// Statistic Handler
// For updating statistics

#include "Zombie_StatisticsCommon.as"

class StatisticHandler : EventHandler
{
	Label@ label;
	string name;
	Statistics::Type type;

	StatisticHandler(Label@ label_, const string&in name, const Statistics::Type&in type)
	{
		@label = label_;
		this.name = name;
		this.type = type;
	}

	void Handle()
	{
		if (getGameTime() % 60 != 0) return; //only update every 2 seconds

		UpdateStatisticValue();
	}

	void UpdateStatisticValue()
	{
		const u32 stat_value = Statistics::Get(name, type);

		string stat = stat_value + "";

		if (name == "play_time")
		{
			f32 hours = f32(stat_value) / 3600.0f;
			hours = Maths::Roundf(hours * 10.0f) / 10.0f;

			stat = hours + " " + getTranslatedString("h ");
		}

		label.SetText(stat);
	}
}
