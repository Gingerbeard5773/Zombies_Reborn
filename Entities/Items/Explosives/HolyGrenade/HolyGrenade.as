//Gingerbeard @ November 18, 2024

#include "Hitters.as";
#include "ActivationThrowCommon.as"
#include "Zombie_Translation.as"
#include "BombCommon.as";

void onInit(CBlob@ this)
{	
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action3);
	}

	this.Tag("activatable");

	Activate@ activation_handle = @onActivate;
	this.set("activate handle", @activation_handle);

	this.addCommandID("activate client");
	
	this.getSprite().SetEmitSound("/Sparkle.ogg");
	this.getSprite().SetEmitSoundPaused(true);
	this.SetLightRadius(25.0f);
	
	this.setInventoryName(name(Translate::HolyGrenade));
}

void onTick(CBlob@ this)
{
	if (isServer() && this.isAttached() && !this.hasTag("activated"))
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (ap !is null && ap.isKeyJustPressed(key_action3) && ap.getOccupied() !is null && !ap.getOccupied().isAttached())
		{
			server_Activate(this);
		}
	}
}

void onActivate(CBitStream@ params)
{
	if (!isServer()) return;

	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;
	
	this.SetLight(true);
	this.server_SetTimeToDie(5);
	this.SendCommand(this.getCommandID("activate client"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("activate client") && isClient())
	{
		Sound::Play("HolyGrenadePin.ogg", this.getPosition());
		this.SetLight(true);
		this.getSprite().SetEmitSoundPaused(false);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("activated"))
	{
		this.SetFrame(1);

		this.RotateAllBy(5 * blob.getVelocity().x, Vec2f_zero);
		sparks(blob.getPosition(), blob.getAngleDegrees(), 3.5f + (XORRandom(10) / 5.0f), blob.getLightColor());
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid) return;

	const f32 vellen = this.getOldVelocity().Length();
	if (vellen > 1.7f)
	{
		Sound::Play("/BombBounce.ogg", this.getPosition(), Maths::Min(vellen / 8.0f, 1.1f));
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("dead") || !this.hasTag("activated")) return;

	if (isServer())
	{
		CBlob@ blob = server_CreateBlobNoInit("nukeexplosion");
		blob.setPosition(this.getPosition());
		blob.server_setTeamNum(this.getTeamNum());
		blob.set_u8("nuke_explosions_max", 10);
		blob.set_f32("nuke_explosion_radius", 2.0f);
	}
	
	this.getSprite().PlaySound("HolyGrenadeExplosion.ogg", 13.0f, 1.f);
	Sound::Play2D("HolyGrenadeExplosion.ogg", 0.4f, 0.0f);

	this.Tag("dead");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return !this.hasTag("activated");
}
