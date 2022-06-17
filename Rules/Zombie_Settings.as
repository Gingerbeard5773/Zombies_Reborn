// Zombie Fortress settings

#include "GameplayEvents.as";

void onInit(CRules@ this)
{
	this.set_string("version", "1.0.0");
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
}

void AddIcons()
{
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
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
