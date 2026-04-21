//Trident
//Gingerbeard @ April 19, 2026

#include "Hitters.as"
#include "Zombie_Translation.as"
#include "LimitedAttacks.as"
#include "CustomTiles.as"
#include "ParticleTeleport.as"

const u16 attack_time = 13;
const f32 spear_length = 10.0f; // the length we cannot damage enemies in
const f32 spear_range = 48.0f; // the length we can damage enemies in

Vec2f base_offset = Vec2f(5, 0);

namespace Trident
{
	const u8 charge_ready_time = 30;
	const u8 returning_delay = 15;
	const f32 throw_speed = 20.0f;

	enum State
	{
		none,
		attacking,
		charging,
		thrown,
		returning,
	}
}

shared class TridentVars
{
	u32 end_attack = 0;
	u8 charge = 0;
	u8 state = Trident::none;
	u8 return_time = 0;
	bool shape = false;
}

void onInit(CBlob@ this)
{
	this.Tag("ignore parent facing");
	this.Tag("place norotate"); //stop rotation from locking. blame builder code apparently
	this.getShape().SetOffset(base_offset - Vec2f(5, 0));
	this.setInventoryName(name(Translate("Trident")));

	this.Tag("gun"); //for weapon cursor

	this.addCommandID("client_sync_trident_vars");

	LimitedAttack_setup(this);

	TridentVars trident();
	this.set("tridentVars", trident);
}

void onTick(CBlob@ this)
{
	TridentVars@ vars;
	if (!this.get("tridentVars", @vars)) return;

	// process thrown state
	if (vars.state == Trident::thrown)
	{
		onTridentThrown(this, vars);
		return;
	}

	// process returning state
	if (vars.state == Trident::returning)
	{
		onTridentReturning(this, vars);
		return;
	}

	SetShape(this, vars);

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();
	if (holder is null) return;

	const f32 angle = getAimAngle(this, holder, vars);
	this.setAngleDegrees(angle);

	CSprite@ sprite = this.getSprite();

	// process basic attack
	if (vars.state != Trident::charging)
	{
		vars.state = Trident::none;

		if (vars.end_attack > getGameTime())
		{
			const f32 time = vars.end_attack - getGameTime();
			Vec2f offset(-time * 2.5f, 0);
			sprite.SetOffset(-base_offset + offset);

			vars.state = Trident::attacking;
		}
		else if (point.isKeyJustPressed(key_action1))
		{
			sprite.PlaySound("Partisan"+XORRandom(3));
			server_SpearAttack(this, holder, angle);

			vars.end_attack = getGameTime() + attack_time;
			vars.state = Trident::attacking;
		}
	}

	// process charging & throw
	if (vars.state != Trident::attacking)
	{
		if (point.isKeyPressed(key_action2))
		{
			// charge the trident
			const u8 old_charge = vars.charge;
			vars.charge = Maths::Min(vars.charge + 1, Trident::charge_ready_time);
			vars.state = Trident::charging;

			if (old_charge < Trident::charge_ready_time && vars.charge == Trident::charge_ready_time)
			{
				sprite.PlaySound("charged.ogg", 1.5f, 1.0f);
			}
		}
		else if (vars.charge >= Trident::charge_ready_time)
		{
			sprite.PlaySound("Partisan"+XORRandom(3));
			ThrowTrident(this, angle);

			vars.charge = 0;
			vars.state = Trident::thrown;
		}
		else
		{
			//lose charge overtime
			vars.charge = Maths::Max(vars.charge - 4, 0);
			vars.state = vars.charge > 0 ? Trident::charging : Trident::none;
		}

		// pull back the trident visually if we are charging it
		Vec2f offset(vars.charge * 0.25f, 0);
		sprite.SetOffset(-base_offset + offset);
	}

	// set weapon cursor frame
	if (holder.isMyPlayer())
	{
		int frame = 0;
		if (vars.charge >= Trident::charge_ready_time)
		{
			frame = 18;
		}
		else if (vars.charge > 0)
		{
			frame = int((f32(vars.charge) / f32(Trident::charge_ready_time)) * 9) * 2;
		}
		this.set_u8("frame", frame);
	}
}

void server_SpearAttack(CBlob@ this, CBlob@ holder, f32&in angle)
{
	if (!isServer()) return;

	angle += this.isFacingLeft() ? 180 : 0;
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	Vec2f direction = Vec2f(spear_length, 0).RotateBy(angle);

	Vec2f ray1 = pos + Vec2f(0, 3).RotateBy(angle);
	Vec2f ray2 = pos - Vec2f(0, 3).RotateBy(angle);

	HitInfo@[][] rays(3);

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

			if (LimitedAttack_has_hit_actor(this, b)) continue;

			if (canHitTileBlob(b))
			{
				if (b.isPlatform() && PassesPlatform(b, direction)) continue;

				hit = true;
			}

			if (ray[i].distance > spear_length && b.getTeamNum() != holder.getTeamNum())
			{
				this.server_Hit(b, b.getPosition(), Vec2f_zero, 1.75f, Hitters::sword, true);
				LimitedAttack_add_actor(this, b);
			}

			if (hit)
			{
				break;
			}
		}
	}

	LimitedAttack_clear(this);
}

void ThrowTrident(CBlob@ this, const f32&in angle)
{
	this.server_DetachFromAll();

	const f32 sign = !this.isFacingLeft() ? 1 : -1;
	Vec2f vel = Vec2f(Trident::throw_speed * sign, 0).RotateBy(angle);
	this.setVelocity(vel);
}

void onTridentThrown(CBlob@ this, TridentVars@ vars)
{
	if (!isServer()) return;

	const f32 angle = -this.getVelocity().Angle();
	const f32 sign = !this.isFacingLeft() ? 0 : 180;
	this.setAngleDegrees(angle + sign);

	CMap@ map = getMap();
	Vec2f vel = this.getVelocity();
	Vec2f position = this.getPosition();

	HitInfo@[] infos;
	if (map.getHitInfosFromArc(position, angle, 10, 32.0f, this, true, @infos))
	{
		for (uint i = 0; i < infos.length; i ++)
		{
			CBlob@ blob = infos[i].blob;
			Vec2f hit_pos = infos[i].hitpos;
			if (blob is null)
			{
				map.server_DestroyTile(hit_pos, 1.0f, this);
				onTridentHitSolid(this, vars);
				break;
			}

			if (blob.isPlatform() && PassesPlatform(blob, vel)) continue;

			if (!canHitBlob(this, blob) || LimitedAttack_has_hit_actor(this, blob)) continue;

			this.server_Hit(blob, hit_pos, vel, 2.5f, Hitters::sword, true);
			LimitedAttack_add_actor(this, blob);

			if (canHitTileBlob(blob))
			{
				onTridentHitSolid(this, vars);
				break;
			}
		}
	}
}

void onTridentHitSolid(CBlob@ this, TridentVars@ vars)
{
	LimitedAttack_clear(this);
	this.getShape().SetStatic(true);
	vars.state = Trident::returning;
	SyncTridentVars(this);
}

void onTridentReturning(CBlob@ this, TridentVars@ vars)
{
	vars.return_time = Maths::Min(vars.return_time + 1, Trident::returning_delay);

	// wait a bit before returning
	if (vars.return_time < Trident::returning_delay) return;

	if (isClient())
	{
		ParticleTeleportSparks(this.getPosition(), 2, Vec2f_zero);

		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSound("SpellLoop.ogg");
		sprite.SetEmitSoundSpeed(0.65f);
		sprite.SetEmitSoundPaused(false);
	}

	CBlob@ owner = null;
	f32 dist = 0.0f;

	// return towards our owner if available
	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player !is null)
	{
		@owner = player.getBlob();
		if (owner !is null)
		{
			Vec2f pos = this.getPosition();
			Vec2f dir = owner.getPosition() - pos;
			dist = dir.Length();
			dir.Normalize();
			dir *= 16.0f;
			Vec2f target_pos = dir + pos;

			this.setPosition(dir + pos);

			const f32 target_angle = -dir.Angle() + (!this.isFacingLeft() ? 180 : 0);
			const f32 angle = LerpAngle(this.getAngleDegrees(), target_angle, 0.1f);
			this.setAngleDegrees(angle);
		}
	}

	// reached our destination or no destination available
	if (dist < 16.0f)
	{
		this.getShape().SetStatic(false);

		if (owner !is null)
		{
			AttachmentPoint@ point = owner.getAttachments().getAttachmentPointByName("PICKUP");
			if (point !is null && point.getOccupied() is null)
			{
				owner.server_AttachTo(this, point);
			}
		}

		vars.return_time = 0;
		vars.state = Trident::none;
	}
}

bool canHitTileBlob(CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable() && blob.getShape().getConsts().support > 0;
}

bool canHitBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("temp blob")) return false;

	const bool same_team = this.getTeamNum() == blob.getTeamNum();
	return (!same_team || blob.getShape().isStatic()) && blob.isCollidable();
}

bool PassesPlatform(CBlob@ blob, Vec2f vel)
{
	ShapePlatformDirection@ plat = blob.getShape().getPlatformDirection(0);
	Vec2f dir = plat.direction;
	if (!plat.ignore_rotations) dir.RotateBy(blob.getAngleDegrees());

	return Maths::Abs(dir.AngleWith(vel)) < plat.angleLimit;
}

f32 getAimAngle(CBlob@ this, CBlob@ holder, TridentVars@ vars)
{
	Vec2f aim_vec = (this.getPosition() - holder.getAimPos());
	aim_vec.Normalize();
	const f32 target_angle = -(aim_vec.getAngleDegrees() + (!this.isFacingLeft() ? 180 : 0));
	const f32 strength = vars.end_attack > getGameTime() ? 0.1f : 0.2f;
	const f32 angle = LerpAngle(this.getAngleDegrees(), target_angle, strength);
	return angle;
}

f32 LerpAngle(f32 a, f32 b, f32 t)
{
	f32 diff = b - a;
	while (diff > 180.0f) diff -= 360.0f;
	while (diff < -180.0f) diff += 360.0f;
	return a + diff * t;
}

void SetShape(CBlob@ this, TridentVars@ vars)
{
	if (this.isAttached())
	{
		if (vars.shape)
		{
			this.getShape().RemoveShape(1);
			vars.shape = false;
		}
	}
	else if (!vars.shape)
	{
		Vec2f[] points = { Vec2f(-10.0f, 0.0f),
		                   Vec2f(35.0f, 0.0f),
		                   Vec2f(35.0f, 4.0f),
		                   Vec2f(-10.0f, 4.0f)
		                 };
		this.getShape().AddShape(points);
		vars.shape = true;
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	TridentVars@ vars;
	if (!this.get("tridentVars", @vars)) return;

	if (vars.state == Trident::thrown || vars.state == Trident::returning)
	{
		vars.state = Trident::none;
	}

	attachedPoint.SetKeysToTake(key_action1 | key_action2);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetOffset(-base_offset);

	TridentVars@ vars;
	if (!this.get("tridentVars", @vars)) return;

	vars.charge = 0;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (isStatic)
		{
			sprite.PlaySound("arrow_hit_ground.ogg", 1.5f, 0.85f);
		}
		else
		{
			sprite.SetEmitSoundPaused(true);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return canHitBlob(this, blob);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	TridentVars@ vars;
	if (!this.get("tridentVars", @vars)) return damage;

	// invincible if this trident is currently being used 
	if (customData == Hitters::fall || vars.state != Trident::none)
	{
		return 0.0f;
	}

	return damage;
}


/// NETWORK

void SyncTridentVars(CBlob@ this)
{
	if (isClient()) return;

	CBitStream stream;
	Serialize(this, stream);
	this.SendCommand(this.getCommandID("client_sync_trident_vars"), stream);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_sync_trident_vars") && isClient())
	{
		Unserialize(this, params);
	}
}

void Serialize(CBlob@ this, CBitStream@ stream)
{
	TridentVars@ vars;
	if (!this.get("tridentVars", @vars)) return;

	stream.write_u32(vars.end_attack);
	stream.write_u8(vars.charge);
	stream.write_u8(vars.state);
	stream.write_u8(vars.return_time);
}

bool Unserialize(CBlob@ this, CBitStream@ stream)
{
	TridentVars@ vars;
	if (!this.get("tridentVars", @vars)) return true;

	if (!stream.saferead_u32(vars.end_attack)) { error("Failed to read Trident [0]"); return false; }
	if (!stream.saferead_u8(vars.charge))      { error("Failed to read Trident [1]"); return false; }
	if (!stream.saferead_u8(vars.state))       { error("Failed to read Trident [2]"); return false; }
	if (!stream.saferead_u8(vars.return_time)) { error("Failed to read Trident [3]"); return false; }

	return true;
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	Serialize(this, stream);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	return Unserialize(this, stream);
}
