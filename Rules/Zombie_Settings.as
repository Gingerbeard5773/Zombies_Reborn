// Zombie Fortress settings

#include "Zombie_Scrolls.as";

void onInit(CRules@ this)
{
	this.set_string("version", "1.4.1");
	sv_contact_info = "github.com/Gingerbeard5773/Zombies_Reborn";
	
	sv_visiblity_scale = 1.25f;
	
	SColor printColor = 0xff66C6FF;
	
	print("");
	print("---- INITIALIZING ZOMBIE FORTRESS ---- ",  printColor);
	print("  Version: " + this.get_string("version"), printColor);
	print("  Mod page: "+sv_contact_info,             printColor);
	print("-------------------------------------- ",  printColor);
	print("");
	
	AddIcons();
	AddFonts();

	SetupScrolls(this);
	
	this.addCommandID("client_send_global_message"); //Zombie_GlobalMessages.as
}

void AddIcons()
{
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	AddIconToken("$heart_full$", "/GUI/HeartNBubble.png", Vec2f(12, 12), 1);
	AddIconToken("$heart_half$", "/GUI/HeartNBubble.png", Vec2f(12, 12), 3);
	AddIconToken("$worker_migrant$", "MigrantMale.png", Vec2f(32, 32), 3, 0);
	AddIconToken("$parachute$", "Crate.png", Vec2f(32, 32), 4, 0);
	AddIconToken("$MolotovArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 4, 0);
	AddIconToken("$mat_molotovarrows_icon$", "MaterialMolotovArrow.png", Vec2f(16, 16), 1, 0);
	AddIconToken("$FireworkArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 5, 0);
	AddIconToken("$mat_coal_icon$", "MaterialCoal.png", Vec2f(16, 16), 3, 0);
	AddIconToken("$mat_iron_icon$", "MaterialIron.png", Vec2f(16, 16), 3, 0);
	AddIconToken("$flowers_icon$", "Flowers.png", Vec2f(16, 16), 6, 0);
}

void AddFonts()
{
	const bool isRussian = g_locale == "ru";
	if (!GUI::isFontLoaded("big font"))
	{
        GUI::LoadFont("big font", isRussian ? "GUI/Fonts/Arial.ttf" : "GUI/Fonts/AveriaSerif-Bold.ttf", isRussian ? 25 : 50, true);
    }
	
	if (!GUI::isFontLoaded("medium font"))
	{
        GUI::LoadFont("medium font", isRussian ? "GUI/Fonts/Arial.ttf" : "GUI/Fonts/AveriaSerif-Regular.ttf", isRussian ? 10 : 20, true);
    }
}
