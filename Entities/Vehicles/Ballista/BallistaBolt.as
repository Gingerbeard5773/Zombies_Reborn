// Blame Fuzzle.

#include "Hitters.as";
#include "ShieldCommon.as";
#include "LimitedAttacks.as";
#include "Explosion.as";
#include "CustomTiles.as";

const f32 MEDIUM_SPEED = 9.0f;
const f32 FAST_SPEED = 16.0f;
const u8 BOLT_PIERCE = 2;

void onInit(CBlob@ this)
{
	this.set_u8("blocks_pierced", 0);

	this.server_SetTimeToDie(20);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

	LimitedAttack_setup(this);

	u32[] offsets;
	this.set("offsets", offsets); //tiles that have been hit

	this.Tag("projectile");
	this.getSprite().getConsts().accurateLighting = true;
	this.getSprite().SetFacingLeft(!this.getSprite().isFacingLeft());

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.getSprite().SetFrame(this.hasTag("bomb ammo") ? 1 : 0);
}

void onTick(CBlob@ this)
{
	if (this.getShape().isStatic()) return;

	Vec2f velocity = this.getVelocity();
	const f32 angle = velocity.Angle();

	Pierce(this, velocity, angle);

	this.setAngleDegrees(-angle + 180.0f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("temp blob")) return false;

	const bool same_team = this.getTeamNum() == blob.getTeamNum();
	return (!same_team || blob.getShape().isStatic()) && blob.isCollidable();
}

void onDie(CBlob@ this)
{
	if (this.hasTag("bomb ammo"))
	{
		this.set_bool("map_damage_raycast", false);
		this.set_f32("map_damage_radius", 24.0f);

		Explode(this, 16.0f, 2.0f);
		LinearExplosion(this, this.getOldVelocity(), 64.0f, 8.0f, 2, 4.0f, Hitters::bomb);

		this.getSprite().Gib();
	}
}

void Pierce(CBlob@ this, Vec2f velocity, const f32 angle)
{
	CMap@ map = getMap();

	const f32 speed = velocity.getLength();
	const f32 damage = speed > MEDIUM_SPEED ? 4.0f : 3.5f;

	Vec2f direction = velocity;
	direction.Normalize();

	Vec2f position = this.getPosition();
	Vec2f tip_position = position + direction * 12.0f;
	Vec2f middle_position = position + direction * 6.0f;
	Vec2f tail_position = position - direction * 12.0f;

	Vec2f[] positions = { position, tip_position, middle_position, tail_position };

	for (uint i = 0; i < positions.length; i ++)
	{
		Vec2f temp_position = positions[i];
		if (map.isTileSolid(map.getTile(temp_position)))
		{
			u32[]@ offsets;
			this.get("offsets", @offsets);
			const u32 offset = map.getTileOffset(temp_position);
			if (offsets.find(offset) != -1) continue;

			BallistaHitMap(this, offset, temp_position, velocity, damage, Hitters::ballista);
			this.server_HitMap(temp_position, velocity, damage, Hitters::ballista);
		}
	}

	HitInfo@[] infos;

	if (speed > 0.1f && map.getHitInfosFromArc(tail_position, -angle, 10, (tip_position - tail_position).getLength(), this, true, @infos))
	{
		for (uint i = 0; i < infos.length; i ++)
		{
			CBlob@ blob = infos[i].blob;
			Vec2f hit_position = infos[i].hitpos;
			if (blob is null) continue;

			if (blob.isPlatform())
			{
				ShapePlatformDirection@ plat = blob.getShape().getPlatformDirection(0);
				Vec2f dir = plat.direction;
				if (!plat.ignore_rotations) dir.RotateBy(blob.getAngleDegrees());

				if (Maths::Abs(dir.AngleWith(velocity)) < plat.angleLimit) continue;
			}

			if (!doesCollideWithBlob(this, blob) || LimitedAttack_has_hit_actor(this, blob)) continue;

			this.server_Hit(blob, hit_position, velocity, damage, Hitters::ballista, true);
			BallistaHitBlob(this, hit_position, velocity, damage, blob, Hitters::ballista);
			LimitedAttack_add_actor(this, blob);
		}
	}
}

bool DoExplosion(CBlob@ this)
{
	if (this.hasTag("bomb ammo") && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.server_Die();
		return true;
	}

	return false;
}

void BallistaHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, const f32 damage, CBlob@ blob, u8 customData)
{
	if (DoExplosion(this)) return;

	const string sound = blob.hasTag("flesh") ? "ArrowHitFleshFast.ogg" : "ArrowHitGroundFast.ogg";
	this.getSprite().PlaySound(sound);

	if (blob.getHealth() <= 0.0f) return;

	if (blob.hasTag("wooden"))
	{
		this.setVelocity(velocity * 0.5f);

		u8 blocks_pierced = this.get_u8("blocks_pierced");
		const f32 speed = velocity.getLength();

		if (blocks_pierced < BOLT_PIERCE && speed > FAST_SPEED)
		{
			this.set_u8("blocks_pierced", blocks_pierced + 1);
			return;
		}
	}

	if (blob.getShape().isStatic() && blob.getName() != "skelepedebody")
	{
		SetStatic(this);
	}
}

void BallistaHitMap(CBlob@ this, const u32 offset, Vec2f hit_position, Vec2f velocity, const f32 damage, u8 customData)
{
	if (DoExplosion(this)) return;

	this.getSprite().PlaySound("ArrowHitGroundFast.ogg");

	CMap@ map = getMap();
	Tile tile = map.getTile(offset);
	const f32 angle = velocity.Angle();

	if (map.isTileBedrock(tile.type))
	{
		this.Tag("dead");
		this.server_Die();
		this.getSprite().Gib();
		return;
	}

	if ((map.isTileGroundStuff(tile.type) || isTileIron(tile.type)) && map.isTileSolid(tile))
	{
		SetStatic(this);
		return;
	}

	if (map.getSectorAtPosition(hit_position, "no build") is null)
		map.server_DestroyTile(hit_position, 1.0f, this);

	const f32 speed = velocity.getLength();

	this.setVelocity(velocity * 0.5f);
	this.push("offsets", offset);

	u8 blocks_pierced = this.get_u8("blocks_pierced");
	if (blocks_pierced < BOLT_PIERCE && speed > FAST_SPEED && map.isTileWood(tile.type))
	{
		this.set_u8("blocks_pierced", blocks_pierced + 1);
		return;
	}

	SetStatic(this);
}

void SetStatic(CBlob@ this)
{
	this.setVelocity(Vec2f_zero);
	this.getShape().SetStatic(true);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
