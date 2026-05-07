//Gingerbeard @ May 7th, 2026

#define SERVER_ONLY

#include "Zombie_DaysCommon.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"
#include "Zombie_GlobalMessagesCommon.as"
#include "GetSurvivors.as"

bool hit_record = false;

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	ConfigFile@ cfg = Statistics::openConfig();
	const u16 record_day = cfg.exists("record_day") ? cfg.read_u16("record_day") : 1;

	this.set_u16("day_record", record_day);
	this.Sync("day_record", true);

	this.set_u16("day_number", 0);
	this.Sync("day_number", true);

	this.set_u16("last_day_hour", 0);

	hit_record = false;
}

void onTick(CRules@ this)
{
	if (getGameTime() % getTicksASecond() != 0) return;

	const u16 day_hour = Maths::Floor(getMap().getDayTime()*10);
	if (day_hour != this.get_u16("last_day_hour"))
	{
		onDayHourChange(this, day_hour);
	}
}

void onDayHourChange(CRules@ this, const u16&in day_hour)
{
	if (day_hour == this.daycycle_start*10)
	{
		onNewDay(this, day_hour);
	}

	// Trigger remote script hooks
	dictionary@ dict;
	if (this.get("onNewDayHour handles", @dict))
	{
		const string[]@ handle_keys = dict.getKeys();
		for (int i = 0; i < handle_keys.length; ++i)
		{
			onNewDayHourHandle@ handle;
			if (!dict.get(handle_keys[i], @handle)) continue;

			handle(this, day_hour);
		}
	}

	this.set_u16("last_day_hour", day_hour);
}

void onNewDay(CRules@ this, const u16&in day_hour)
{
	const u16 day_number = this.get_u16("day_number") + 1;

	this.set_u16("day_number", day_number);
	this.Sync("day_number", true);

	ConfigFile@ cfg = Statistics::openConfig();
	const u16 record_day = cfg.exists("record_day") ? cfg.read_u16("record_day") : 1;
	if (day_number > record_day)
	{
		cfg.add_u16("record_day", day_number);
		cfg.add_u16("record_day_previous", record_day);
		cfg.saveFile(Statistics::filename);
	}

	if (day_number == 10)
	{
		Achievement::server_Unlock(Achievement::Surviving);
	}
	else if (day_number == 25)
	{
		Achievement::server_Unlock(Achievement::Thriving);
	}
	else if (day_number == 50)
	{
		Achievement::server_Unlock(Achievement::GettingDangerous);
	}
	else if (day_number == 75)
	{
		Achievement::server_Unlock(Achievement::Extreme);
	}
	else if (day_number == 100)
	{
		Achievement::server_Unlock(Achievement::Impossible);
	}

	if (day_number > record_day && !hit_record)
	{
		Achievement::server_Unlock(Achievement::WorldRecord);
		hit_record = true;
		const string[] inputs = {day_number+""};
		server_SendGlobalMessage(this, "Record", 10, inputs);
	}
	else 
	{
		const string[] inputs = {day_number+""};
		server_SendGlobalMessage(this, "Day", 10, inputs);
	}

	// Sole survivor achievement
	if (this.get_u8("survivor player count") >= 6 && day_number > 5)
	{
		CBlob@[]@ survivors = getSurvivors();
		if (survivors.length == 1)
		{
			CPlayer@ player = survivors[0].getPlayer();
			if (player !is null)
			{
				Achievement::server_Unlock(Achievement::SoleSurvivor, player);
			}
		}
	}
}
