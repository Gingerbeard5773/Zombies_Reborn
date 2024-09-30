// Zombie Fortress settings

#include "Zombie_Scrolls.as";

void onInit(CRules@ this)
{
	this.set_string("version", "1.3.2");
	sv_contact_info = "github.com/Gingerbeard5773/Zombies_Reborn";
	
	print("\n ---- INITIALIZING ZOMBIE FORTRESS ---- \n"+
		  "\n  Version: " + this.get_string("version") +
		  "\n  Mod page: "+sv_contact_info+
		  "\n  Test mode: "+sv_test+
		  "\n  Localhost: "+(isClient() && isServer())+"\n"+
		  "\n -------------------------------------- \n", 0xff66C6FF);
	
	AddIcons();
	AddFonts();

	SetupScrolls(this);
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

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	//keep gold from decaying
	if (isServer() && blob.getName() == "mat_gold")
	{
		blob.RemoveScript("DecayQuantity.as");
	}
}
