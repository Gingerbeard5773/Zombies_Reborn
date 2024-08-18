#include "Hitters.as";
#include "ActivationThrowCommon.as"

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
	
	this.SetLight(false);
	this.SetLightRadius(20.0f);
	this.SetLightColor(SColor(255, 255, 200, 50));
}

void onInit(CSprite@ this)
{
	//burning sound	    
    this.SetEmitSound("MolotovBurning.ogg");
    this.SetEmitSoundVolume(5.0f);
    this.SetEmitSoundPaused(true);
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
	
	this.server_SetTimeToDie(5);
	this.SendCommand(this.getCommandID("activate client"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("activate client") && isClient())
	{
		this.SetLight(true);
		CSprite@ sprite = this.getSprite();
		sprite.PlaySound("/FireFwoosh.ogg");
		sprite.SetEmitSoundPaused(false);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("activated"))
	{
		this.SetFrame(1);
		ParticleAnimated("SmallFire", blob.getPosition() + Vec2f(1 - XORRandom(3), -4), Vec2f(0, -1 - XORRandom(2)), 0, 1.0f, 2, 0.25f, false);

		this.RotateAllBy(5 * blob.getVelocity().x, Vec2f_zero);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!isServer() || !this.hasTag("activated")) return;

	const f32 vellen = this.getOldVelocity().Length();
	if (solid && blob is null)
	{
		if (vellen > 4.0f)
			this.server_Die();
	}
	else if (blob !is null)
	{
		if (solid || blob.hasTag("player") && blob.getTeamNum() != this.getTeamNum())
		{
			if (vellen > 2.0f)
			this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

void DoExplosion(CBlob@ this)
{
	if (!this.hasTag("dead") && this.hasTag("activated"))
	{
		if (isServer())
		{
			CMap@ map = getMap();
			Vec2f pos = this.getPosition();
			const int radius = 2; //size of the circle
			const f32 radsq = radius * 8 * radius * 8;
			for (int x_step = -radius; x_step < radius; ++x_step)
			{
				for (int y_step = -radius; y_step < radius; ++y_step)
				{
					Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
					if (off.LengthSquared() > radsq) continue;
					
					map.server_setFireWorldspace(pos + off, true);
				}
			}

			Vec2f vel = this.getOldVelocity();
			for (int i = 0; i < 6 + XORRandom(2); i++)
			{
				CBlob@ blob = server_CreateBlob("flame", -1, pos + Vec2f(0, -8));
				if (blob is null) continue;
				
				Vec2f nv = Vec2f((XORRandom(100) * 0.01f * vel.x * 1.30f), -(XORRandom(100) * 0.01f * 3.00f));
				if (Maths::Abs(nv.x) < 1.0f)
				{
					nv.x = XORRandom(nv.Length() * 2 * 100)/100;
					if (XORRandom(100) < 50) nv.x *= -1;
				}

				blob.setVelocity(nv);
				blob.server_SetTimeToDie(5 + XORRandom(6));
				blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			}
		}

		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSoundPaused(true);
		sprite.PlaySound("MolotovExplosion.ogg", 1.6f);
		sprite.Gib();

		this.Tag("dead");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isServer() && !this.hasTag("activated") && (isExplosionHitter(customData) || customData == Hitters::fire))
	{
		server_Activate(this);
		this.server_SetTimeToDie(1 + XORRandom(3));
	}

	return 0.0f;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    if ((blob.isCollidable() && blob.getShape().isStatic()) || (blob.hasTag("player") && blob.getTeamNum() != this.getTeamNum()))
		return true;

    return false;
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return !this.hasTag("activated");
}
