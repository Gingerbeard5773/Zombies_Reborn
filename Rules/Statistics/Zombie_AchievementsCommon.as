// Zombie Fortress Achievements
// Gingerbeard @ Jan 27, 2026

/* Potential achievement ideas
	Fumbled : duplicate something useless (a tile blob, or forage, ladders, etc)
	Society : have 15 surviving workers at the same time
	Pokey Fort : place 500 spikes in one game
*/

#include "Zombie_Translation.as"

funcdef void onUnlockAchievementHandle(CRules@, int);

shared class Achievement
{
	u8 id;
	SColor rarity;
	string description;
	bool hidden;
	Achievement(const u8&in id, SColor rarity, const bool&in hidden, const string&in description)
	{
		this.id = id;
		this.rarity = rarity;
		this.description = description;
		this.hidden = hidden;
	}
}

namespace Achievement
{
	enum Index
	{
		Surviving,              // - Survive to night 10
		Thriving,               // - Survive to night 25
		GettingDangerous,       // - Survive to night 50
		Extreme,                // - Survive to night 75
		Impossible,             // - Survive to night 100
		Butcher,                // - Kill 1000 undead in a game
		Slaughter,              // - Kill 5000 undead in a game
		Bloodbath,              // - Kill 10,000 undead in a game
		Stonemason,             // - Build 1500 blocks in a game
		Architect,              // - Build 3000 blocks in a game
		ZombieFortress,         // - Build 6000 blocks in a game
		Mechanist,              // - Build 300 components in a game
		WorldRecord,            // - Pass the server day record
		NotTodayBuddy,          // - Douse an ignited wraith in water
		SpontaneousCombustion,  // - Instantly explode a wraith with a fire arrow
		TheBoss,                // - Give a worker a job
		Bookworm,               // - Research an upgrade at the library
		Librarian,              // - Research all upgrades at the library in one game
		GreatAwakening,         // - Duplicate the library
		WorthATry,              // - Duplicate a scroll of duplication
		NarrowEscape,           // - Escape from a skelepede's jaws with a scroll of teleport
		PureCarnage,            // - Vaporize 100 undead with one Scroll of Carnage
		SecondChance,           // - Use the scroll of resurrection on yourself
		Savior,                 // - Revive at least three players with only one scroll of resurrection
		ReturningFromHell,      // - Survive getting pulled to the void
		NiceTry,                // - Attempt to crate the library
		Sealed,                 // - Crate Sedgwick
		Kidnapper,              // - Crate the trader
		ThePrincess,            // - Summon Geti
		Vandalism,              // - Scare away the trader
		Industrializing,        // - Setup a factory
		Sweatshop,              // - Setup 10 factories in a game
		Piercing,               // - Kill 15 undead with one ballista bolt
		UhOh,                   // - Activate a portal
		FromBadToWorse,         // - Have multiple portals exist at the same time
		SkyDiving,              // - Get pulled to the sky
		Snatched,               // - Get pulled to the void
		HideAndSeek,            // - Have a skelepede find you inside a crate
		CrowdCrush,             // - Get swarmed and die
		Bucketeer,              // - Wear the bucket
		IronMan,                // - Wear a full set of armor
		Pyromaniac,             // - Scorch the world
		RipAndTear,             // - Kill an undead with a chainsaw
		ThouMayest,             // - Thou mayest blow Thine enemies to tiny bits, in Thy mercy - Use the holy hand grenade
		CrowdControl,           // - Use the shotgun
		PayloadDelivered,       // - Fire the bazooka
		FlyingFortress,         // - Maximize an armored bomber
		Bombardier,             // - Drop big bombs from a bomber
		Plow,                   // - Run over a swarm of zombies with a tank
		Hero,                   // - Save another player who was snatched by a skelepede
		SoleSurvivor,           // - Survive a night as the last player alive (8 minimum players required)
		Juggernaut,             // - Attain a ridiculous amount of health
		Count
	}

	SColor
	Normal     = color_white,              // White
	Uncommon   = SColor(0xff66C6FF),       // Light blue
	Rare       = SColor(255, 255, 0, 255), // Magenta
	Insane     = SColor(255, 255, 0, 0);   // Red

	Achievement@[] achievements =
	{
		Achievement(Surviving,             Normal,     false,   Translate::Surviving),
		Achievement(Thriving,              Normal,     false,   Translate::Thriving),
		Achievement(GettingDangerous,      Uncommon,   false,   Translate::GettingDangerous),
		Achievement(Extreme,               Rare,       false,   Translate::Extreme),
		Achievement(Impossible,            Insane,     false,   Translate::Impossible),
		Achievement(Butcher,               Normal,     false,   Translate::Butcher),
		Achievement(Slaughter,             Uncommon,   false,   Translate::Slaughter),
		Achievement(Bloodbath,             Rare,       false,   Translate::Bloodbath),
		Achievement(Stonemason,            Normal,     false,   Translate::Stonemason),
		Achievement(Architect,             Uncommon,   false,   Translate::Architect),
		Achievement(ZombieFortress,        Rare,       false,   Translate::ZombieFortress),
		Achievement(Mechanist,             Normal,     false,   Translate::Mechanist),
		Achievement(WorldRecord,           Rare,       false,   Translate::WorldRecord),
		Achievement(NotTodayBuddy,         Normal,     false,   Translate::NotTodayBuddy),
		Achievement(SpontaneousCombustion, Normal,     false,   Translate::SpontaneousCombustion),
		Achievement(TheBoss,               Normal,     false,   Translate::TheBoss),
		Achievement(Bookworm,              Normal,     false,   Translate::Bookworm),
		Achievement(Librarian,             Rare,       false,   Translate::Librarian),
		Achievement(GreatAwakening,        Rare,       true,    Translate::GreatAwakening),
		Achievement(WorthATry,             Rare,       true,    Translate::WorthATry),
		Achievement(NarrowEscape,          Uncommon,   false,   Translate::NarrowEscape),
		Achievement(PureCarnage,           Normal,     false,   Translate::PureCarnage),
		Achievement(SecondChance,          Normal,     false,   Translate::SecondChance),
		Achievement(Savior,                Rare,       false,   Translate::Savior),
		Achievement(ReturningFromHell,     Uncommon,   false,   Translate::ReturningFromHell),
		Achievement(NiceTry,               Uncommon,   true,    Translate::NiceTry),
		Achievement(Sealed,                Uncommon,   true,    Translate::Sealed),
		Achievement(Kidnapper,             Uncommon,   true,    Translate::Kidnapper),
		Achievement(ThePrincess,           Normal,     false,   Translate::ThePrincess),
		Achievement(Vandalism,             Normal,     true,    Translate::Vandalism),
		Achievement(Industrializing,       Normal,     false,   Translate::Industrializing),
		Achievement(Sweatshop,             Normal,     false,   Translate::Sweatshop),
		Achievement(Piercing,              Uncommon,   false,   Translate::Piercing),
		Achievement(UhOh,                  Normal,     false,   Translate::UhOh),
		Achievement(FromBadToWorse,        Rare,       false,   Translate::FromBadToWorse),
		Achievement(SkyDiving,             Normal,     false,   Translate::SkyDiving),
		Achievement(Snatched,              Normal,     false,   Translate::Snatched),
		Achievement(HideAndSeek,           Rare,       true,    Translate::HideAndSeek),
		Achievement(CrowdCrush,            Normal,     false,   Translate::CrowdCrush),
		Achievement(Bucketeer,             Normal,     true,    Translate::Bucketeer),
		Achievement(IronMan,               Normal,     false,   Translate::IronMan),
		Achievement(Pyromaniac,            Normal,     false,   Translate::Pyromaniac),
		Achievement(RipAndTear,            Normal,     false,   Translate::RipAndTear),
		Achievement(ThouMayest,            Uncommon,   false,   Translate::ThouMayest),
		Achievement(CrowdControl,          Normal,     false,   Translate::CrowdControl),
		Achievement(PayloadDelivered,      Normal,     false,   Translate::PayloadDelivered),
		Achievement(FlyingFortress,        Uncommon,   false,   Translate::FlyingFortress),
		Achievement(Bombardier,            Normal,     false,   Translate::Bombardier),
		Achievement(Plow,                  Normal,     false,   Translate::Plow),
		Achievement(Hero,                  Uncommon,   false,   Translate::Hero),
		Achievement(SoleSurvivor,          Uncommon,   false,   Translate::SoleSurvivor),
		Achievement(Juggernaut,            Rare,       false,   Translate::Juggernaut)
	};
	
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

	bool isUnlocked(const string&in achievements_array, const int&in index)
	{
		if (achievements_array.length <= index) return false;

		return achievements_array[index] == 49; //1 in ascii
	}

	string getArray(const int&in index, ConfigFile@ cfg = openConfig())
	{
		string achievements_array = cfg.exists("achievements") ? cfg.read_string("achievements") : "";

		if (index >= achievements_array.length)
		{
			bool resized = false;
			while (achievements_array.length < index)
			{
				achievements_array += "0";
				resized = true;
			}
			if (resized)
			{
				print("Resizing achievements array to accomodate new achievements");
				cfg.add_string("achievements", achievements_array);
				cfg.saveFile(filename);
			}
		}

		return achievements_array;
	}

	void client_Unlock(const int&in index)
	{
		if (!isClient()) return;

		CRules@ rules = getRules();
		onUnlockAchievementHandle@ onUnlockAchievement;
		if (rules.get("onUnlockAchievement Handle", @onUnlockAchievement))
		{
			onUnlockAchievement(rules, index);
		}
	}

	void server_Unlock(const int&in index, CPlayer@ player = null)
	{
		if (!isServer()) return;

		CRules@ rules = getRules();
		CBitStream stream;
		stream.write_s32(index);

		if (player is null)
			rules.SendCommand(rules.getCommandID("client_unlock_achievement"), stream);
		else
			rules.SendCommand(rules.getCommandID("client_unlock_achievement"), stream, player);
	}
}
