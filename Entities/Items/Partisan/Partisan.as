//Partisan
//Gingerbeard @ March 28, 2026

#include "Hitters.as"
#include "Zombie_Translation.as"

const u16 attack_time = 13;
const f32 spear_arc_degrees = 12.0f;
const f32 spear_length = 44.0f; // the length we cannot damage enemies in
const f32 spear_range = 38.0f; // the length we can damage enemies in

Vec2f base_offset = Vec2f(16, 0);

void onInit(CBlob@ this)
{
	this.Tag("ignore parent facing");
	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently
	this.getShape().SetOffset(base_offset - Vec2f(16, 0));
	this.setInventoryName(name(Translate::Partisan));
}

void onTick(CBlob@ this)
{
	if (!this.isAttached())
	{
		SetShape(this);
		return;
	}

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	const f32 angle = getAimAngle(this, holder);
	this.setAngleDegrees(angle);

	const u32 end_attack = this.get_u32("end attack");
	const f32 time = end_attack - getGameTime();

	CSprite@ sprite = this.getSprite();
	
	//f32 push_back = getSpearTilePushback(this);
	//sprite.SetOffset(Vec2f(push_back - 16, 0));
	
	if (end_attack > getGameTime())
	{
		Vec2f offset(-time * 2.5f, 0);
		sprite.SetOffset(-base_offset + offset);
	}
	else if (point.isKeyJustPressed(key_action1))
	{
		this.set_u32("end attack", getGameTime() + attack_time);
		this.getSprite().PlaySound("Partisan"+XORRandom(3));
		
		server_SpearAttack(this, holder, angle);
	}
}

void server_SpearAttack(CBlob@ this, CBlob@ holder, f32&in angle)
{
	if (!isServer()) return;
	
	angle += this.isFacingLeft() ? 180 : 0;
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	Vec2f direction = Vec2f(spear_length, 0).RotateBy(angle);

	Vec2f ray1 = pos + Vec2f(0, 2).RotateBy(angle);
	Vec2f ray2 = pos - Vec2f(0, 2).RotateBy(angle);

	HitInfo@[][] rays(3);
	u16[] alreadyHit;

	//three seperate rays, with slight offsets- this is done so we can attack around corners
	map.getHitInfosFromRay(ray1, angle, spear_length + spear_range, this, @rays[0]);
	map.getHitInfosFromRay(ray2, angle, spear_length + spear_range, this, @rays[1]);
	map.getHitInfosFromRay(pos,  angle, spear_length + spear_range, this, @rays[2]);

	for (int r = 0; r < rays.length; r++)
	{
		bool hit = false;

		HitInfo@[] ray = rays[r];
		for (int i = 0; i < ray.length; i++)
		{
			CBlob@ b = ray[i].blob;
			if (b is null) continue;

			if (alreadyHit.find(b.getNetworkID()) != -1) continue;

			if (b.getShape().isStatic() && b.isCollidable() && b.getShape().getConsts().support > 0)
			{
				if (b.isPlatform())
				{
					ShapePlatformDirection@ plat = b.getShape().getPlatformDirection(0);
					Vec2f dir = plat.direction;
					if (!plat.ignore_rotations) dir.RotateBy(b.getAngleDegrees());

					if (Maths::Abs(dir.AngleWith(direction)) < plat.angleLimit)
					{
						continue;
					}
				}

				hit = true;
			}

			if (ray[i].distance > spear_length && b.getTeamNum() != holder.getTeamNum())
			{
				this.server_Hit(b, b.getPosition(), Vec2f_zero, 1.45f, Hitters::sword, true);
				alreadyHit.push_back(b.getNetworkID());
			}

			if (hit)
			{
				break;
			}
		}
	}
}

f32 getAimAngle(CBlob@ this, CBlob@ holder)
{
	Vec2f aim_vec = (this.getPosition() - holder.getAimPos());
	aim_vec.Normalize();

	f32 targetAngle = -(aim_vec.getAngleDegrees() + (!this.isFacingLeft() ? 180 : 0));
	f32 oldAngle = this.getAngleDegrees();

	bool lastFacing = this.get_bool("last_facing_left");
	if (lastFacing != this.isFacingLeft())
	{
		oldAngle += 180.0f;
	}

	this.set_bool("last_facing_left", this.isFacingLeft());

	const f32 lerpStrength = this.get_u32("end attack") > getGameTime() ? 0.05f : 0.15f;
	const f32 newAngle = LerpAngle(oldAngle, targetAngle, lerpStrength);
	return newAngle;
}

f32 getSpearTilePushback(CBlob@ this)
{
	f32 angle = -this.getAngleDegrees();
	angle += this.isFacingLeft() ? -180 : 0;
	Vec2f dir = Vec2f(1, 0).RotateBy(angle);

	const f32 total_length = spear_length + 8.0f;
	Vec2f start = this.getPosition();
	HitInfo@[] hits;
	if (getMap().getHitInfosFromRay(start, -angle, total_length, this, @hits))
	{
		for (uint i = 0; i < hits.length; i++)
		{
			HitInfo@ hit = hits[i];
			if (hit.blob is null && hit.hitpos != Vec2f_zero)
			{
				f32 dist = (hit.hitpos - start).Length();
				f32 pushback = Maths::Min(total_length - dist, 15.0f);
				return Maths::Clamp(pushback, 0, total_length);
			}
		}
	}

	return 0.0f;
}

f32 LerpAngle(f32 a, f32 b, f32 t)
{
	f32 diff = b - a;
	while (diff > 180.0f) diff -= 360.0f;
	while (diff < -180.0f) diff += 360.0f;
	return a + diff * t;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	attachedPoint.SetKeysToTake(key_action1);
	if (attached.getName() != "archer") 
	{
		attachedPoint.SetKeysToTake(key_action1 | key_action2);
	}
	
	if (this.hasTag("full_shape"))
	{
		this.getShape().RemoveShape(1);
		this.Untag("full_shape");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetOffset(-base_offset);
}

void SetShape(CBlob@ this)
{
	if (this.hasTag("full_shape")) return;

	Vec2f[] points = { Vec2f(-10.0f, 0.0f),
					   Vec2f(50.0f, 0.0f),
					   Vec2f(50.0f, 4.0f),
					   Vec2f(-10.0f, 4.0f)
					 };
	this.getShape().AddShape(points);

	this.Tag("full_shape");
}
