//Scythe
//Gingerbeard @ August 5, 2024

#include "Hitters.as"
#include "Zombie_Translation.as"

const u16 attack_time = 10;
const f32 spear_arc_degrees = 12.0f; 
const f32 spear_range = 40.0f;

void onInit(CBlob@ this)
{
	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently
	
	this.setInventoryName(name(Translate::Spear));
}

void onTick(CBlob@ this)
{
	if (!this.isAttached()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	const f32 aimAngle = getAimAngle(this, holder);
	this.setAngleDegrees(aimAngle);

	const u32 end_attack = this.get_u32("end attack");
	const f32 time = end_attack - getGameTime();

	CSprite@ sprite = this.getSprite();
	
	if (end_attack > getGameTime())
	{
		Vec2f offset(-time * 2.5f, 0);
		sprite.SetOffset(offset);
	}
	else if (point.isKeyJustPressed(key_action1))
	{
		this.set_u32("end attack", getGameTime() + attack_time);
		this.getSprite().PlaySound("SwordSlash.ogg");
		
		server_SpearAttack(this, holder, aimAngle);
	}
}

void server_SpearAttack(CBlob@ this, CBlob@ holder, const f32&in aimAngle)
{
	if (!isServer()) return;
	
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	const f32 angle = aimAngle + (holder.isFacingLeft() ? 180 : 0);
	Vec2f direction = Vec2f(4, 0).RotateBy(angle);
	pos += direction;

	Vec2f ray1 = pos + Vec2f(0, 2).RotateBy(angle);
	Vec2f ray2 = pos - Vec2f(0, 2).RotateBy(angle);

	HitInfo@[] hitInfos;
	u16[] alreadyHit;

	//three seperate rays, with slight offsets- this is done so we can attack around corners
	map.getHitInfosFromRay(ray1, angle, spear_range, this, @hitInfos);
	map.getHitInfosFromRay(ray2, angle, spear_range, this, @hitInfos);
	map.getHitInfosFromRay(pos,  angle, spear_range, this, @hitInfos);

	for (int i = 0; i < hitInfos.length; i++)
	{
		HitInfo@ hi = hitInfos[i];
		CBlob@ b = hi.blob;
		if (b is null) continue;

		if (alreadyHit.find(b.getNetworkID()) != -1) continue;

		bool hit = false;
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

		if (b.getTeamNum() != holder.getTeamNum())
		{
			this.server_Hit(b, b.getPosition(), Vec2f_zero, 1.3f, Hitters::sword, true);
			alreadyHit.push_back(b.getNetworkID());
		}

		if (hit)
		{
			break;
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

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	this.Tag("invincible");
	
	attachedPoint.SetKeysToTake(key_action1);
	if (attached.getName() != "archer") 
	{
		attachedPoint.SetKeysToTake(key_action1 | key_action2);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.Untag("invincible");
	this.getSprite().SetOffset(Vec2f_zero);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible")) return 0.0f;

	return damage;
}
