//Gingerbeard @ September 29, 2024

//Firework arrow logic

#include "Hitters.as";
#include "FireParticle.as"
#include "ArcherCommon.as"
#include "KnockedCommon.as"
#include "FW_Explosion.as"
#include "Explosion.as"

const f32 ARROW_PUSH_FORCE = 6.0f;
const f32 ARROW_SPEED = 12.0f;
const f32 ARROW_RANGE = 460.0f;

const string[] streamers = 
{
	"particle_trail_green.png",
	"particle_trail_blue.png",
	"particle_trail_purple.png",
	"particle_trail_darkblue.png",
	"particle_trail_red.png",
	"particle_trail_teal.png",
	"particle_trail_orange.png",
	"particle_trail_grey.png"
};

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(20.0f);
	this.SetLightColor(SColor(255, 255, 200, 50));

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.setDrag(0.0f);

	CSprite@ sprite = this.getSprite();
	{
		Animation@ anim = sprite.addAnimation("firework arrow", 2, true);
		anim.AddFrame(18);
		anim.AddFrame(19);
		anim.AddFrame(20);
		anim.AddFrame(21);
		sprite.SetAnimation(anim);
	}

	//sprite.SetEmitSound("FW_Whistle"+(1 + XORRandom(2))+".ogg");
	sprite.SetEmitSound("FW_Whistle1.ogg");
	sprite.SetEmitSoundVolume(5.0f);
	sprite.SetEmitSoundPaused(false);
	sprite.SetEmitSoundSpeed(0.95f + XORRandom(6)*0.01f);

	this.addCommandID("server_set_explosion_time");

	this.server_SetTimeToDie(1.0f);
	SetExplosionTime(this);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player !is null && player.isMyPlayer())
	{
		CBitStream stream;
		stream.write_Vec2f(getControls().getMouseWorldPos());
		this.SendCommand(this.getCommandID("server_set_explosion_time"), stream);
	}

	return true;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_set_explosion_time") && isServer())
	{
		Vec2f aimpos;
		if (!params.saferead_Vec2f(aimpos)) return;

		SetExplosionTime(this, aimpos);
	}
}

void SetExplosionTime(CBlob@ this, Vec2f aimpos = Vec2f_zero)
{
	if (!isServer()) return;

	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player is null) return;

	CBlob@ caller = player.getBlob();
	if (caller is null) return;

	if (aimpos == Vec2f_zero)
		aimpos = caller.getAimPos();

	Vec2f aimVec = aimpos - caller.getPosition();
	const f32 aimdist = Maths::Min(aimVec.Normalize(), ARROW_RANGE);
	const f32 lifetime = Maths::Max(0.1f + aimdist / ARROW_SPEED / 32.0f, 0.5f);
	this.server_SetTimeToDie(lifetime);
}

void onTick(CBlob@ this)
{
	if (this.hasTag("collided")) return;

	//overload any velocity set by the archer
	Vec2f direction = this.getVelocity();
	direction.Normalize();
	Vec2f vel = Vec2f(ARROW_SPEED, 0).RotateBy(-direction.Angle());
	this.setVelocity(vel);
	
	const u8 index = this.getNetworkID() % streamers.length;
	Fireworks::MakeFireTrail(this.getPosition(), streamers[index]);

	//ParticleAnimated("SmallFire", this.getPosition(), Vec2f(0, -1 - XORRandom(2)), 0, 1.0f, 2, 0.25f, true);

	//prevent leaving the map
	Vec2f pos = this.getPosition();
	if (pos.x < 0.1f ||
		pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

	const f32 angle = this.getVelocity().Angle();
	Pierce(this);
	this.setAngleDegrees(-angle);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob !is null && doesCollideWithBlob(this, blob) && !this.hasTag("collided"))
	{
		if (blob.isPlatform() && !solid) return;

		this.Tag("collided");
		this.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.getTeamNum() != blob.getTeamNum())
	{
		if (blob.hasTag("flesh") || blob.hasTag("vehicle") || blob.hasTag("player"))
			return true;
	}

	return blob.isCollidable() && blob.getShape().isStatic() && blob.getShape().getConsts().support > 0;
}

void Pierce(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f end;
	if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, this.getPosition(), end))
	{
		setPositionToLastOpenArea(this, end, map);

		this.Tag("collided");
		this.server_Die();
	}
}

void setPositionToLastOpenArea(CBlob@ this, Vec2f hitpos, CMap@ map)
{
	//ensure we are exploding in an open area for maximum effect
	Vec2f original = hitpos;
	Vec2f dir = this.getOldVelocity();
	dir.Normalize();
	dir *= map.tilesize;

	for (u8 i = 0; i < 4; i++)
	{
		hitpos -= dir;
		if (!map.isTileSolid(hitpos)) break;
	}

	this.setPosition(hitpos);
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSoundPaused(true);
		sprite.Gib();

		string explodesound;
		switch (XORRandom(4))
		{
			case 0: explodesound = "FW_Deep1.ogg"; break;
			case 1: explodesound = "FW_Deep2.ogg"; break;
			case 2: explodesound = "FW_Deep3.ogg"; break;
			case 3: explodesound = "FW_PopAndCrackle.ogg"; break;
		}
		//sprite.PlaySound(explodesound, 5.0f, 0.5f);
		//Sound::Play(explodesound, 5.0f, 0.0f);
		Sound::Play(explodesound);

		Fireworks::Explode(pos, Vec2f_zero);
	}

	ParticleAnimated("Entities/Effects/Sprites/FireFlash.png", pos, Vec2f(0, 0.5f), 0.0f, 1.0f, 2, 0.0f, true);

	Random rand(this.getNetworkID());
	Explode(this, 64.0f, 2.0f);
	for (u8 i = 0; i < 4; i++)
	{
		Vec2f dir = Vec2f(1 - i / 2.0f, -1 + i / 2.0f);
		Vec2f jitter = Vec2f((int(rand.NextRanged(200)) - 100) / 200.0f, (int(rand.NextRanged(200)) - 100) / 200.0f);

		LinearExplosion(this, Vec2f(dir.x * jitter.x, dir.y * jitter.y), 32.0f + rand.NextRanged(32), 15.0f, 6, 2.0f, Hitters::explosion);
	}

	if (isServer())
	{
		if (this.hasTag("collided"))
		{
			const u8 flame_count = 2 + XORRandom(2);
			for (u8 i = 0; i < flame_count; i++)
			{
				CBlob@ blob = server_CreateBlob("flame", -1, pos + Vec2f(0, -8));
				if (blob is null) continue;

				Vec2f nv = Vec2f((XORRandom(100) * 0.01f * 1.30f), -(XORRandom(100) * 0.01f * 3.00f));
				if (Maths::Abs(nv.x) < 1.0f)
				{
					nv.x = XORRandom(nv.Length() * 2 * 100)/100;
					if (XORRandom(100) < 50) nv.x *= -1;
				}

				blob.setVelocity(nv);
				blob.server_SetTimeToDie(2 + XORRandom(3));
				blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			}
		}

		CMap@ map = getMap();
		const int radius = 3; //size of the circle
		const f32 radsq = radius * 8 * radius * 8;
		CBlob@[] blobs;
		if (map.getBlobsInRadius(pos, radius * 8, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				map.server_setFireWorldspace(blob.getPosition(), true);
				this.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 1.5f, Hitters::fire);
			}
		}

		for (int x_step = -radius; x_step < radius; ++x_step)
		{
			for (int y_step = -radius; y_step < radius; ++y_step)
			{
				Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
				if (off.LengthSquared() > radsq) continue;

				if (!map.hasTileFlag(map.getTileOffset(pos + off), Tile::FLAMMABLE)) continue;

				map.server_setFireWorldspace(pos + off, true);
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::sword)
	{
		return 0.0f; //no cut arrows
	}

	return damage;
}

/*void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (this is hitBlob) return;

	// affect players velocity

	Vec2f vel = velocity;
	const f32 speed = vel.Normalize();
	if (speed > ArcherParams::shoot_max_vel * 0.5f)
	{
		f32 force = (ARROW_PUSH_FORCE * 0.125f) * Maths::Sqrt(hitBlob.getMass() + 1);

		if (this.hasTag("bow arrow"))
		{
			force *= 1.3f;
		}

		hitBlob.AddForce(velocity * force);

		// stun if shot real close
		if (this.getTickSinceCreated() <= 4 &&
			speed > ArcherParams::shoot_max_vel * 0.845f &&
			hitBlob.hasTag("player") && !hitBlob.hasTag("undead"))
		{
			setKnocked(hitBlob, 20, true);
			Sound::Play("/Stun", hitBlob.getPosition(), 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
		}
	}
}*/
