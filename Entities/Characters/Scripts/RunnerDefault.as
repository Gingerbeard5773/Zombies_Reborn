#include "RunnerCommon.as";
#include "Hitters.as";
#include "KnockedCommon.as"
#include "FireCommon.as"
#include "Help.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.Tag("medium weight");
	
	this.Tag("ignore saw");
	this.Tag("sawed");//hack

	//default player minimap dot - not for migrants
	if (this.getName() != "migrant")
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
	}

	this.set_s16(burn_duration , 130);
	this.set_f32("heal amount", 0.0f);

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	InitKnockable(this);
}

void onTick(CBlob@ this)
{
	this.Untag("prevent crouch");
	DoKnockedUpdate(this);
}

// pick up efffects
// something was picked up

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PutInInventory.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	this.getSprite().PlaySound("/Pickup.ogg");

	this.ClearButtons();

	if (isClient())
	{
		RemoveHelps(this, "help throw");

		if (!attached.hasTag("activated"))
			SetHelp(this, "help throw", "", getTranslatedString("${ATTACHED}$Throw    $KEY_C$").replace("{ATTACHED}", getTranslatedString(attached.getName())), "", 2);
	}

	if (!attachedPoint.socket && attachedPoint.name == "PICKUP")
	{
		attachedPoint.offsetZ = -10.0f;
		this.getSprite().SetRelativeZ(-10.0f);
	}
}

// set the Z back
// The baseZ is assumed to be 0
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetZ(0.0f);
	
	if (!attachedPoint.socket && attachedPoint.name == "PICKUP")
	{
		attachedPoint.offsetZ = 0.0f;
		this.getSprite().SetRelativeZ(0.0f);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	if (this.hasTag("sleeper") && this.getTeamNum() == byBlob.getTeamNum() && this.getDistanceTo(byBlob) < 16.0f)
		return true;

	return this.hasTag("migrant") || this.hasTag("dead");
}

// make Suicide ignore invincibility
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible"))
	{
		if (customData == Hitters::suicide)
			this.Untag("invincible");
		else
			return 0.0f; //added so we can have immunity while in special vehicles - gingerbeard @ August 18 2024
	}

	switch(customData)
	{
		case Hitters::mine:
		case Hitters::mine_special:
			damage *= 0.2f;
			break;
	}
	return damage;
}
