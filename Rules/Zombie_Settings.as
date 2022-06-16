// Zombie Fortress settings

#include "GameplayEvents.as";

void onInit(CRules@ this)
{
	this.set_string("version", "1.0.0");
	sv_contact_info = "none";
	
	print("\n ---- INITIALIZING ZOMBIE FORTRESS ---- \n"+
		  "\n  Version: " + this.get_string("version") +
		  "\n  Mod page: "+sv_contact_info+
		  "\n  Test mode: "+sv_test+
		  "\n  Localhost: "+(isClient() && isServer())+"\n"+
		  "\n -------------------------------------- \n", 0xff66C6FF);
	
	SetupGameplayEvents(this);
	AddIcons(this);
}

void AddIcons(CRules@ this)
{
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
}
