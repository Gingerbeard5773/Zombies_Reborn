//Scythe
//Gingerbeard @ August 5, 2024

#include "Hitters.as"

const u16 attack_time = 10;
const f32 scythe_arc_degrees = 130.0f; 
const f32 scythe_range = 20.0f;
const f32 pickup_radius = 8.0f;
const string[] pickup_names = { "grain" };

void onInit(CBlob@ this)
{
	// Prevent classes from jabbing n stuff
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null) 
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}
	
	this.getShape().SetOffset(Vec2f(0, -4));

	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently
}

void addChopLayer(CSprite@ this)
{
	CSpriteLayer@ chop = this.addSpriteLayer("scythe_chop", "KnightMale.png", 32, 32);
	if (chop !is null)
	{
		Animation@ anim = chop.addAnimation("default", 0, true);
		anim.AddFrame(35);
		anim.AddFrame(43);
		anim.AddFrame(63);
		chop.SetOffset(Vec2f(-5, 0));
		chop.SetVisible(true);
		chop.SetRelativeZ(1000.0f);
	}
}

void onTick(CBlob@ this)
{
	if (!this.isAttached()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null || holder.isAttached()) return;

	const f32 aimAngle = getAimAngle(this, holder);
	this.setAngleDegrees(aimAngle);
	
	const u32 end_attack = this.get_u32("end attack");
	const f32 time = end_attack - getGameTime();
	
	CSprite@ sprite = holder.getSprite();
	CSpriteLayer@ chop = sprite.getSpriteLayer("scythe_chop");
	if (chop !is null)
	{
		bool wantsChopLayer = time <= attack_time && time >= attack_time - 3 ;
		chop.SetVisible(wantsChopLayer);
		if (wantsChopLayer)
		{
			chop.animation.frame = attack_time - time;
			chop.ResetTransform();
			chop.RotateBy(aimAngle, chop.getOffset() * (holder.isFacingLeft() ? 1 : -1));
		}
	}
	else
	{
		addChopLayer(sprite);
	}
	
	if (end_attack > getGameTime())
	{
		const f32 angle = aimAngle + time * 20 * (this.isFacingLeft() ? -1 : 1);
		this.setAngleDegrees(angle);
	}
	else if (point.isKeyJustPressed(key_action1))
	{
		this.set_u32("end attack", getGameTime() + attack_time);
		this.getSprite().PlaySound("SwordSlash.ogg");
		
		server_ScytheAttack(this, holder, aimAngle);
	}
	
	server_PickupCrops(this, holder);
}

void server_ScytheAttack(CBlob@ this, CBlob@ holder, const f32&in aimAngle)
{
	if (!isServer()) return;
	
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	const f32 angle = aimAngle + (holder.isFacingLeft() ? 180 : 0);

	//attack blobs
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, angle, scythe_arc_degrees, scythe_range, this, @hitInfos))
	{
		for (int i = 0; i < hitInfos.size(); i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null)
			{
				if (b.hasTag("has grain") || b.getName() == "bush")
				{
					this.server_Hit(b, b.getPosition(), Vec2f_zero, b.getInitialHealth() + 1.0f, Hitters::sword, true);
				}
				else if (b.hasTag("flesh") && b.getTeamNum() != holder.getTeamNum())
				{
					this.server_Hit(b, b.getPosition(), Vec2f_zero, 1.0f, Hitters::sword, true);
				}
			}
		}
	}
	
	//destroy grass tiles
	Vec2f grass_hitpos(scythe_range*0.7f, 0);
	grass_hitpos.RotateBy(angle);
	const int radius = 2; //size of the circle
	const f32 radsq = radius * 8 * radius * 8;
	for (int x_step = -radius; x_step < radius; ++x_step)
	{
		for (int y_step = -radius; y_step < radius; ++y_step)
		{
			Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
			if (off.LengthSquared() > radsq) continue;
			
			Vec2f checkpos = pos + grass_hitpos + off;
			if (map.isTileGrass(map.getTile(checkpos).type))
			{
				map.server_DestroyTile(checkpos, 1.0f, this);
			}
		}
	}
}

void server_PickupCrops(CBlob@ this, CBlob@ holder)
{
	if (!isServer()) return;

	if (getGameTime() % 15 == 0)
	{
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), 20, @blobs);
		
		for (int i = 0; i < blobs.size(); i++)
		{
			CBlob@ b = blobs[i];
			if (pickup_names.find(b.getName()) != -1)
			{
				holder.server_PutInInventory(b);
			}
		}
	}
}

f32 getAimAngle(CBlob@ this, CBlob@ holder)
{
	Vec2f aim_vec = (this.getPosition() - holder.getAimPos());
	aim_vec.Normalize();
	const f32 angle = aim_vec.getAngleDegrees() + (!this.isFacingLeft() ? 180 : 0);
	return -angle;
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	setChopVisible(detached);
}

void onDie(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder !is null)
	{
		setChopVisible(holder);
	}
}

void setChopVisible(CBlob@ holder, const bool setVisible = false)
{
	CSpriteLayer@ chop = holder.getSprite().getSpriteLayer("scythe_chop");
	if (chop !is null)
	{
		chop.SetVisible(setVisible);
	}
}
