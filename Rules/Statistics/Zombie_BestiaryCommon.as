// Zombie Fortress Bestiary
// Gingerbeard @ Jan 29, 2026

#include "Zombie_Translation.as"

funcdef void onUnlockBestiaryEntryHandle(CRules@, string);

shared class BestiaryEntry
{
	string name;
	string description;
	string filename;
	Vec2f frame_dimension;
	u8 team;
	u8[] frames;

	BestiaryEntry(const string&in name, const string&in description, const string&in filename, Vec2f frame_dimension, const u8&in team, const u8[]&in frames)
	{
		this.name = name;
		this.description = description;
		this.filename = filename;
		this.frame_dimension = frame_dimension;
		this.team = team;
		this.frames = frames;
	}
}

namespace Bestiary
{
	const u8[][] animation_frames =
	{
		{0, 1, 2, 3}, //skeleton
		{0, 1, 0, 2}, //zombie
		{0, 1, 2, 3}, //zombie knight
		{3, 2, 1, 0}, //greg
		{0, 1, 2, 3}, //wraith
		{0, 1, 2, 3}, //dark wraith
		{0},          //skelepede
		{0, 1, 2, 3}, //horror
		{0, 1, 2, 3}, //jerry
		{0, 1, 2, 3}, //spectre
		{0},          //sedgwick
		{0},          //trader
		{0}           //timothy
	};

	BestiaryEntry@[] entries =
	{
		BestiaryEntry("skeleton",     Translate::BestiarySkeleton,     "Skeleton",      Vec2f(25, 25), 3, animation_frames[0]),
		BestiaryEntry("zombie",       Translate::BestiaryZombie,       "Zombie",        Vec2f(25, 25), 3, animation_frames[1]),
		BestiaryEntry("zombieknight", Translate::BestiaryZombieKnight, "ZombieKnight",  Vec2f(32, 32), 3, animation_frames[2]),
		BestiaryEntry("greg",         Translate::BestiaryGreg,         "Greg",          Vec2f(32, 32), 3, animation_frames[3]),
		BestiaryEntry("wraith",       Translate::BestiaryWraith,       "Wraith",        Vec2f(32, 32), 3, animation_frames[4]),
		BestiaryEntry("darkwraith",   Translate::BestiaryDarkWraith,   "DarkWraith",    Vec2f(32, 32), 3, animation_frames[5]),
		BestiaryEntry("skelepede",    Translate::BestiarySkelepede,    "SkelepedeIcon", Vec2f(96, 32), 3, animation_frames[6]),
		BestiaryEntry("horror",       Translate::BestiaryHorror,       "Horror",        Vec2f(32, 32), 3, animation_frames[7]),
		BestiaryEntry("jerry",        Translate::BestiaryJerry,        "Jerry",         Vec2f(32, 32), 3, animation_frames[8]),
		BestiaryEntry("spectre",      Translate::BestiarySpectre,      "Spectre",       Vec2f(32, 32), 3, animation_frames[9]),
		BestiaryEntry("sedgwick",     Translate::BestiarySedgwick,     "Necromancer",   Vec2f(24, 24), 3, animation_frames[10]),
		BestiaryEntry("trader",       Translate::BestiaryTrader,       "TraderMale",    Vec2f(16, 16), 0, animation_frames[11]),
		BestiaryEntry("tim",          Translate::BestiaryTimothy,      "Tim",           Vec2f(16, 16), 0, animation_frames[12])
	};

	int find(const string&in name)
	{
		for (u8 i = 0; i < entries.length; i++)
		{
			if (entries[i].name == name) return i;
		}
		return -1;
	}

	const string filename = "Zombie_Statistics.cfg";

	ConfigFile@ openConfig()
	{
		ConfigFile cfg = ConfigFile();
		if (!cfg.loadFile("../Cache/"+filename))
		{
			warn("Creating statistics config ../Cache/"+filename);
			cfg.saveFile(filename);
		}

		return cfg;
	}

	bool isUnlocked(const int&in index, ConfigFile@ cfg = openConfig())
	{
		return isUnlocked(getArray(index, cfg), index);
	}

	bool isUnlocked(const string&in bestiary_entries, const int&in index)
	{
		if (bestiary_entries.length <= index) return false;

		return bestiary_entries[index] == 49; //1 in ascii
	}

	string getArray(const int&in index = 0, ConfigFile@ cfg = openConfig())
	{
		string bestiary_entries = cfg.exists("bestiary_entries") ? cfg.read_string("bestiary_entries") : "";

		if (index >= bestiary_entries.length)
		{
			bool resized = false;
			while (bestiary_entries.length < index)
			{
				bestiary_entries += "0";
				resized = true;
			}
			if (resized)
			{
				print("Resizing bestiary array to accomodate new entries");
				cfg.add_string("bestiary_entries", bestiary_entries);
				cfg.saveFile(filename);
			}
		}

		return bestiary_entries;
	}

	void client_Unlock(const string&in name)
	{
		CRules@ rules = getRules();
		onUnlockBestiaryEntryHandle@ onUnlockBestiaryEntry;
		if (rules.get("onUnlockBestiaryEntry Handle", @onUnlockBestiaryEntry))
		{
			onUnlockBestiaryEntry(rules, name);
		}
	}
}
