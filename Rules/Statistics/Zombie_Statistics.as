// Zombie Fortress Statistics, Achievements, Bestiary
// Gingerbeard @ Jan 28, 2026

#include "Zombie_GlobalMessagesCommon.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"
#include "Zombie_BestiaryCommon.as"
#include "Zombie_Translation.as"
#include "Events.as"

const u32 SLIDE_TIME = 15;
const u32 HOLD_TIME  = 180;
const u32 TOTAL_TIME = SLIDE_TIME * 2 + HOLD_TIME;

u32 time = 0;
Achievement@[] unlocked_achievements;

void onInit(CRules@ this)
{
	if (isClient())
	{
		dictionary statistics_set;
		this.set("statistics_set", @statistics_set);

		onUnlockAchievementHandle@ onAchievement = @onUnlockAchievement;
		this.set("onUnlockAchievement Handle", @onAchievement);

		onUnlockBestiaryEntryHandle@ onBestiaryEntry = @onUnlockBestiaryEntry;
		this.set("onUnlockBestiaryEntry Handle", @onBestiaryEntry);
	}

	this.addCommandID("client_unlock_achievement");
	this.addCommandID("client_add_statistic");

	server_ResetPlayerStats(this);
	
	if (isCurrentStatsOutdated(this))
	{
		client_ResetCurrentStats(this);
	}
}

void onReload(CRules@ this)
{
	onInit(this);
}

void onRestart(CRules@ this)
{
	server_ResetPlayerStats(this);

	client_ResetCurrentStats(this);
}

bool isCurrentStatsOutdated(CRules@ this)
{
	if (!isClient()) return false;

	ConfigFile@ cfg = Statistics::openConfig();
	const int map_seed = this.get_s32("map_seed");
	const int saved_map_seed = cfg.exists("map_seed") ? cfg.read_s32("map_seed") : 0;

	return map_seed != saved_map_seed;
}

void client_ResetCurrentStats(CRules@ this)
{
	if (!isClient()) return;

	ConfigFile@ cfg = Statistics::openConfig();
	for (u8 i = 0; i < Statistics::statistic_names.length; i++)
	{
		const string statistic_name = Statistics::statistic_names[i];
		const string statistic = cfg.exists(statistic_name) ? cfg.read_string(statistic_name) : "0 0";
		string[]@ values = statistic.split(" ");

		cfg.add_string(statistic_name, "0 " + values[Statistics::AllTime]);
	}

	for (u8 i = 0; i < Bestiary::entries.length; i++)
	{
		const string statistic_name = Bestiary::entries[i].name;
		const string statistic = cfg.exists(statistic_name) ? cfg.read_string(statistic_name) : "0 0";
		string[]@ values = statistic.split(" ");

		cfg.add_string(statistic_name, "0 " + values[Statistics::AllTime]);
	}

	cfg.add_s32("map_seed", this.get_s32("map_seed"));

	cfg.saveFile(Statistics::filename);
}

void server_ResetPlayerStats(CRules@ this)
{
	if (!isServer()) return;

	// Reset player scores
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;
		
		player.setScore(0);
		player.setDeaths(0);
		player.setKills(0);
		player.setAssists(0);
	}

	this.set_u32("undead_killed_total", 0);
	this.Sync("undead_killed_total", true);
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (this.isGameOver() || blob is null) return;

	if (isServer())
	{
		CPlayer@ victim = blob.getPlayer();
		if (victim !is null)
		{
			victim.setDeaths(victim.getDeaths() + 1);
			Statistics::server_Add("deaths", 1, victim);
		}
	}

	if (!blob.hasTag("undead") || blob.hasTag("ignore kill")) return;

	if (isServer())
	{
		this.add_u32("undead_killed_total", 1);
		this.Sync("undead_killed_total", true);
	}

	CPlayer@ hitter_player = blob.getPlayerOfRecentDamage();
	if (hitter_player is null) return;

	const int kills = hitter_player.getKills() + 1;
	hitter_player.setKills(kills);

	if (hitter_player.isMyPlayer())
	{
		const string name = blob.getName();
		ConfigFile@ cfg = Statistics::openConfig();
		Statistics::Add(name, 1, cfg);
		Statistics::Add("undead_killed", 1, cfg);
		Bestiary::client_Unlock(name);
	}
}

void onTick(CRules@ this)
{
	if (!isClient()) return;

	TickStatistics(this);
	TickPlayTime();
	TickAchievementPane();
}

void TickStatistics(CRules@ this)
{
	if (getGameTime() % 30 != 0) return;
	
	// Statistics are batched and then processed gradually over time
	// This is done because writing to config files is extremely expensive and can cause noticeable frame drops if done too often
	
	dictionary@ statistics_set;
	if (!this.get("statistics_set", @statistics_set)) return;
	
	const string[]@ statistic_keys = statistics_set.getKeys();
	if (statistic_keys.length == 0) return;
	
	const string statistic_name = statistic_keys[XORRandom(statistic_keys.length)];

	u32 value = 0;
	if (!statistics_set.get(statistic_name, value)) return;

	Statistics::AddToConfig(statistic_name, value);

	onAddStatistic(statistic_name, value);

	statistics_set.delete(statistic_name);
}

void TickPlayTime()
{
	if (getGameTime() % 150 != 0) return;

	Statistics::Add("play_time", 5);
}

void TickAchievementPane()
{
	if (unlocked_achievements.length == 0) return;

	time++;

	if (time >= TOTAL_TIME)
	{
		unlocked_achievements.erase(0);
		time = 0;
	}
}

void onRender(CRules@ this)
{
	RenderAchievementPane();
}

void RenderAchievementPane()
{
	if (unlocked_achievements.length == 0) return;

	Achievement@ current = unlocked_achievements[0];

	const f32 margin = 8.0f;
	Vec2f icon_pane_dim(64, 64);

	GUI::SetFont("medium font");

	const string title = name(current.description);
	const string description  = desc(current.description);

	Vec2f title_dim, desc_dim;
	GUI::GetTextDimensions(title, title_dim);
	
	GUI::SetFont("menu");
	GUI::GetTextDimensions(description, desc_dim);

	const f32 text_width  = Maths::Max(title_dim.x, desc_dim.x);
	const f32 text_height = title_dim.y + desc_dim.y + margin;
	const f32 pane_width = margin * 4 + icon_pane_dim.x + text_width;
	const f32 pane_height = margin * 2 + Maths::Max(icon_pane_dim.y, text_height);

	f32 slide = getSlidePercent();
	slide = slide * slide * (3.0f - 2.0f * slide); // smoothstep

	const f32 x = Maths::Lerp(-pane_width, 25.0f, slide);
	const f32 y = 25.0f;

	Vec2f tl(x, y);
	Vec2f br(x + pane_width, y + pane_height);

	GUI::DrawWindow(tl, br);

	// Icon
	Vec2f pane_tl = tl + Vec2f(margin, margin);
	GUI::DrawSunkenPane(pane_tl, pane_tl + icon_pane_dim);
	GUI::DrawIcon("Achievements.png", current.id, Vec2f(32, 32), pane_tl, 1.0f);

	// Text
	Vec2f text_tl = tl + Vec2f(margin * 2 + icon_pane_dim.x, margin);
	SColor color = current.rarity == color_white ? color_black : current.rarity;
	GUI::SetFont("medium font");
	GUI::DrawText(title, text_tl, color);
	GUI::SetFont("menu");
	GUI::DrawText(description, text_tl + Vec2f(0, title_dim.y + margin), color_black);
}

f32 getSlidePercent()
{
	if (time < SLIDE_TIME)
	{
		return f32(time) / SLIDE_TIME;
	}
	else if (time < SLIDE_TIME + HOLD_TIME)
	{
		return 1.0f;
	}

	u32 t = time - (SLIDE_TIME + HOLD_TIME);
	return 1.0f - f32(t) / SLIDE_TIME;
}

void onAddStatistic(string statistic_name, u32 amount)
{
	const u32 current_amount = Statistics::Get(statistic_name, Statistics::Current);

	if (statistic_name == "undead_killed")
	{
		switch (current_amount)
		{
			case 1000:  Achievement::client_Unlock(Achievement::Butcher);         break;
			case 5000:  Achievement::client_Unlock(Achievement::Slaughter);       break;
			case 10000: Achievement::client_Unlock(Achievement::Bloodbath);       break;
		}
	}
	if (statistic_name == "blocks_placed")
	{
		switch (current_amount)
		{
			case 1500:  Achievement::client_Unlock(Achievement::Stonemason);      break;
			case 3000:  Achievement::client_Unlock(Achievement::Architect);       break;
			case 6000:  Achievement::client_Unlock(Achievement::ZombieFortress);  break;
		}
	}
	else if (statistic_name == "components_placed")
	{
		if (current_amount == 300)
		{
			Achievement::client_Unlock(Achievement::Mechanist);
		}
	}
	else if (statistic_name == "factories_setup")
	{
		switch (current_amount)
		{
			case 1:     Achievement::client_Unlock(Achievement::Industrializing); break;
			case 10:    Achievement::client_Unlock(Achievement::Sweatshop);       break;
		}
	}
}

void onUnlockAchievement(CRules@ this, int index)
{
	if (index >= Achievement::achievements.length)
	{ 
		error("Impossible achievement index, no pair found ["+index+"]"); 
		return; 
	}

	ConfigFile@ cfg = Achievement::openConfig();
	string achievements_array = Achievement::getArray(index, cfg);

	if (Achievement::isUnlocked(achievements_array, index)) return;

	achievements_array.erase(index, 1);
	achievements_array.insert(index, "1");

	cfg.add_string("achievements", achievements_array);
	cfg.saveFile(Achievement::filename);

	Achievement@ achievement = Achievement::achievements[index];
	const string achievement_sound = achievement.rarity == Achievement::Insane ? "AchievementGet2" : "AchievementGet1";
	Sound::Play(achievement_sound);

	unlocked_achievements.push_back(achievement);

	this.push("easy_ui_events", Event::Achievement);
}

void onUnlockBestiaryEntry(CRules@ this, string entry_name)
{
	const int index = Bestiary::find(entry_name);
	if (index == -1) return;

	ConfigFile@ cfg = Bestiary::openConfig();
	string bestiary_entries = Bestiary::getArray(index, cfg);

	if (Bestiary::isUnlocked(bestiary_entries, index)) return;

	bestiary_entries.erase(index, 1);
	bestiary_entries.insert(index, "1");

	cfg.add_string("bestiary_entries", bestiary_entries);
	cfg.saveFile(Bestiary::filename);

	Sound::Play("snes_coin.ogg");
	
	const string zombie_name = name(Bestiary::entries[index].description);
	const string message = Translate::BestiaryNewEntry.replace("{INPUT}", zombie_name);
	client_SendGlobalMessage(this, message, 8, SColor(0xff66C6FF));
	
	this.push("easy_ui_events", Event::Bestiary);
}


/// Networking

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_unlock_achievement") && isClient())
	{
		int index;
		if (!params.saferead_s32(index)) return;

		onUnlockAchievement(this, index);
	}
	else if (cmd == this.getCommandID("client_add_statistic") && isClient())
	{
		string statistic_name;
		if (!params.saferead_string(statistic_name)) return;

		u32 amount;
		if (!params.saferead_u32(amount)) return;

		Statistics::Add(statistic_name, amount);
	}
}


/// Testing

/*
bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	if (player !is null && player.isMyPlayer())
	{
		string[]@ tokens = textIn.split(" ");
		if (tokens.length > 1 && tokens[0] == "!achievement")
		{
			Achievement::client_Unlock(parseInt(tokens[1]));
		}
	}
	
	return true;
}*/
