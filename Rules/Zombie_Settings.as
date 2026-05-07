// Zombie Fortress settings

#include "Default/DefaultGUI.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"
#include "Zombie_Scrolls.as"

void onInit(CRules@ this)
{
	this.set_string("version", "1.7.0");
	sv_contact_info = "github.com/Gingerbeard5773/Zombies_Reborn";

	getNet().legacy_cmd = false;

	if (isServer())
	{
		getSecurity().reloadSecurity();
	}

	sv_gravity = 9.81f;
	particles_gravity.y = 0.25f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	PrecacheTextures();

	//smooth shader
	Driver@ driver = getDriver();
	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", true);

	//reset var if you came from another gamemode that edits it
	SetGridMenusSize(24, 2.0f, 32);
	
	SColor printColor = 0xff66C6FF;
	
	print("");
	print("---- INITIALIZING ZOMBIE FORTRESS ---- ",                            printColor);
	print("  Version: " + this.get_string("version"),                           printColor);
	print("  Mod page: "+sv_contact_info,                                       printColor);
	print("  Creator: GingerBeard",                                             printColor);
	print("");
	print("  Please ask for permission to host the mod for the public domain.", printColor);
	print("  This also applies for hosting a modified version of the mod.",     printColor);
	print("-------------------------------------- ",  printColor);
	print("");

	LoadDefaultGUI();
	LoadCustomGUI();

	SetupScrolls(this);

	//Zombie_GlobalMessages.as
	this.addCommandID("client_send_global_message");
	this.addCommandID("client_send_global_sound");
}

void onRestart(CRules@ this)
{
	ConfigFile cfg = ConfigFile();
	if (cfg.loadFile("Zombie Fortress/Gamemode.cfg"))
	{
		const u16 config_daycycle_speed = cfg.read_u16("daycycle_speed", 8);
		if (this.daycycle_speed != config_daycycle_speed)
		{
			this.daycycle_speed = config_daycycle_speed;
			print("Incorrect daycycle speed detected :: Correcting back to normal.", ConsoleColour::CRAZY);
		}
	}
}

void LoadCustomGUI()
{
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	AddIconToken("$heart_full$", "/GUI/HeartNBubble.png", Vec2f(12, 12), 1);
	AddIconToken("$heart_half$", "/GUI/HeartNBubble.png", Vec2f(12, 12), 3);
	AddIconToken("$worker_migrant$", "WorkerIcon.png", Vec2f(32, 32), 0, 0);
	AddIconToken("$parachute$", "Crate.png", Vec2f(32, 32), 4, 0);
	AddIconToken("$MolotovArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 4, 0);
	AddIconToken("$mat_molotovarrows_icon$", "MaterialMolotovArrow.png", Vec2f(16, 16), 1, 0);
	AddIconToken("$FireworkArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 5, 0);
	AddIconToken("$mat_coal_icon$", "MaterialCoal.png", Vec2f(16, 16), 3, 0);
	AddIconToken("$mat_iron_icon$", "MaterialIron.png", Vec2f(16, 16), 3, 0);
	AddIconToken("$flowers_icon$", "Flowers.png", Vec2f(16, 16), 6, 0);

	// Fonts

	const bool isRussian = g_locale == "ru";
	if (!GUI::isFontLoaded("big font"))
	{
		const string font = isRussian ? CFileMatcher("VinqueRg.ttf").getFirst() : "GUI/Fonts/AveriaSerif-Bold.ttf";
		GUI::LoadFont("big font", font, isRussian ? 40 : 50, true);
	}

	if (!GUI::isFontLoaded("medium font"))
	{
		const string font = isRussian ? CFileMatcher("Anticva.ttf").getFirst() : "GUI/Fonts/AveriaSerif-Regular.ttf";
		GUI::LoadFont("medium font", font, isRussian ? 17 : 20, true);
	}

	if (!GUI::isFontLoaded("anticva"))
	{
		GUI::LoadFont("anticva", CFileMatcher("Anticva.ttf").getFirst(), 17, true);
	}

	if (!GUI::isFontLoaded("vinque"))
	{
		GUI::LoadFont("vinque", CFileMatcher("VinqueRg.ttf").getFirst(), 30, true);
	}
}


/// Chat emoticons

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "dots", 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "", 0);
}


/// Border

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	// Allow all blobs to go past the top border
	u8 flags = blob.getMapEdgeFlags();
	flags &= ~CBlob::map_collide_up;
	blob.SetMapEdgeFlags(flags);
}


/// Game end effects

void onStateChange(CRules@ this, const u8 oldState)
{
	if (this.getCurrentState() == GAME_OVER)
	{
		Sound::Play("PortalBreach.ogg");
	}
}
