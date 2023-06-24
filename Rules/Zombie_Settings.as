// Zombie Fortress settings

#include "GameplayEvents.as";
#include "Zombie_Scrolls.as";

void onInit(CRules@ this)
{
	this.set_string("version", "1.3.1");
	sv_contact_info = "github.com/Gingerbeard5773/Zombies_Reborn";
	
	print("\n ---- INITIALIZING ZOMBIE FORTRESS ---- \n"+
		  "\n  Version: " + this.get_string("version") +
		  "\n  Mod page: "+sv_contact_info+
		  "\n  Test mode: "+sv_test+
		  "\n  Localhost: "+(isClient() && isServer())+"\n"+
		  "\n -------------------------------------- \n", 0xff66C6FF);
	
	AddIcons();
	AddFonts();
	
	SetupGameplayEvents(this);
	SetupScrolls(this);
	
	this.addCommandID("server_softban"); //Zombie_SoftBans.as
}

void AddIcons()
{
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	AddIconToken("$heart_full$", "/GUI/HeartNBubble.png", Vec2f(12, 12), 1);
	AddIconToken("$heart_half$", "/GUI/HeartNBubble.png", Vec2f(12, 12), 3);
	AddIconToken("$worker_migrant$", "MigrantMale.png", Vec2f(32, 32), 3, 0);
}

void AddFonts()
{
	if (!GUI::isFontLoaded("big font"))
	{
        GUI::LoadFont("big font", g_locale == "ru" ? "GUI/Fonts/Arial.ttf" : "GUI/Fonts/AveriaSerif-Bold.ttf", 50, true);
    }
	
	if (!GUI::isFontLoaded("medium font"))
	{
        GUI::LoadFont("medium font", g_locale == "ru" ? "GUI/Fonts/Arial.ttf" : "GUI/Fonts/AveriaSerif-Regular.ttf", 20, true);
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
