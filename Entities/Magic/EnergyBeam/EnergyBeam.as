#include "Hitters.as"
#include "ParticleMagic.as"
#include "ParticleBlast.as"
#include "MagicCircleCommon.as"
#include "CustomTiles.as"

// ZOLTRAKK

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = false;
	consts.mapCollisions = false;

	this.server_SetTimeToDie(2);

	CSprite@ sprite = this.getSprite();
	sprite.PlaySound("GenericExplosion1.ogg", 2.0f, 1.0f);

	CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "EnergyBeam.png", 16, 16);

	MagicCircle@ circle = MagicCircle(0.05f, 1.0f, true);
	circle.current_scale = 0.4f;

	MagicCircleLayer@ layer1 = MagicCircleLayer("MagicCircle0.png", 204, 204, 0.4f, 2.0f, color_white);
	MagicCircleLayer@ layer3 = MagicCircleLayer("MagicCircle1.png", 204, 204, 0.35f, -2.0f, color_white);
	circle.AddLayer(layer1);
	circle.AddLayer(layer3);

	circle.Setup(this);

	this.set("magic_circle", @circle);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	const f32 angle = this.getAngleDegrees();

	Vec2f pos = this.getPosition();
	Vec2f dir = Vec2f(1, 0).RotateBy(angle);

	Vec2f map_dim = map.getMapDimensions();

	f32 tx = 999999.0f;
	f32 ty = 999999.0f;

	// left/right borders
	if (Maths::Abs(dir.x) > 0.001f)
	{
		if (dir.x > 0)
		{
			tx = (map_dim.x - pos.x) / dir.x;
		}
		else
		{
			tx = -pos.x / dir.x;
		}
	}

	// bottom border
	if (dir.y > 0)
	{
		ty = (map_dim.y - pos.y) / dir.y;
	}

	const f32 range = Maths::Min(tx, ty);

	Vec2f hit_pos = pos + dir * range;

	HitInfo@[] hitInfos;
	map.getHitInfosFromRay(pos, angle, range, this, @hitInfos);

	for (int i = 0; i < hitInfos.length; i++)
	{
		HitInfo@ hi = hitInfos[i];

		CBlob@ blob = hi.blob;
		if (blob is null)
		{
			hit_pos = hi.hitpos;
			break;
		}

		if (isServer() && canHitBlob(this, blob))
		{
			const f32 damage = getDamage(this, blob);
			// Only half of the damage is shieldable
			this.server_Hit(blob, hit_pos, dir, damage * 0.5f, Hitters::explosion, true);
			this.server_Hit(blob, hit_pos, Vec2f_zero, damage * 0.5f, Hitters::explosion, true);
		}
	}

	Explode(this, hit_pos);

	if (isClient())
	{
		this.set_Vec2f("hit_pos", hit_pos);

		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ laser = sprite.getSpriteLayer("laser");
		if (laser !is null)
		{
			const f32 dist = (hit_pos - pos).Length();
			const f32 laser_length = dist / 16.0f;

			laser.ResetTransform();
			laser.ScaleBy(Vec2f(laser_length, 1.0f));
			laser.TranslateBy(Vec2f(laser_length * 8.0f, 0.0f));

			laser.setRenderStyle(RenderStyle::additive);
			laser.SetHUD(true);
		}

		MagicCircle@ circle;
		if (this.get("magic_circle", @circle))
		{
			circle.Tick(this);
		}

		const bool has_daddy = this.exists("laser_movement_sign");

		if (!has_daddy)
		{
			ParticleMagic(pos, "MissileFire3");

			ParticleCasterLine(pos, hit_pos, color_white);
		}

		if (hit_pos != pos + dir * range)
		{
			ShakeScreen(200.0f, 20, hit_pos);

			ParticleBlastBig(hit_pos);

			if (!has_daddy)
			{
				ParticleBlastSmall(hit_pos);
			}
		}

		if (getGameTime() % 5 == 0)
		{
			if (!has_daddy)
			{
				ParticleMagicCircleVanish(pos, 2.0f, color_white);
			}

			Sound::Play("FireBlast"+(1+XORRandom(10)), hit_pos, 1.6f, 1.2f);

			Driver@ driver = getDriver();
			Vec2f local_pos = driver.getWorldPosFromScreenPos(driver.getScreenCenterPos());
			Vec2f sound_pos = getClosestPointOnLine(pos, hit_pos, local_pos);
			Sound::Play("FireBlast"+(1+XORRandom(2)), sound_pos, 1.0f, 1.2f);
		}
	}
}

bool canHitBlob(CBlob@ this, CBlob@ blob)
{
	if (blob is getOwner(this)) return false;

	if (blob.hasTag("invincible")) return false;

	return true;
}

CBlob@ getOwner(CBlob@ this)
{
	CPlayer@ player = this.getDamageOwnerPlayer();
	if (player !is null)
	{
		return player.getBlob();
	}

	if (this.exists("owner_netid"))
	{
		return getBlobByNetworkID(this.get_netid("owner_netid"));
	}

	return null;
}

f32 getDamage(CBlob@ this, CBlob@ blob)
{
	if (blob.isCollidable()) return 1.5f;

	if (blob.hasTag("scenary") || blob.hasTag("tree")) return 0.3f;

	return 0.03f;
}

void Explode(CBlob@ this, Vec2f pos)
{
	if (!isServer()) return;

	CMap@ map = getMap();
	const int radius = 2;
	const f32 radsq = radius * 8 * radius * 8;

	for (int x_step = -radius; x_step < radius; ++x_step)
	{
		for (int y_step = -radius; y_step < radius; ++y_step)
		{
			Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
			if (off.LengthSquared() > radsq) continue;

			Vec2f tile_pos = pos + off;

			TileType tile = map.getTile(tile_pos).type;
			if ((isTileIron(tile) || isTileBIron(tile)) && XORRandom(2) != 0) continue;

			if ((isTileGoldBlock(tile) || isTileBGoldBlock(tile)) && XORRandom(4) != 0) continue;

			map.server_DestroyTile(tile_pos, 1.0f, this);
		}
	}
}

Vec2f getClosestPointOnLine(Vec2f start_pos, Vec2f end_pos, Vec2f check_pos)
{
	Vec2f line = end_pos - start_pos;
	const f32 line_length = line.LengthSquared();
	if (line_length == 0.0f) return start_pos;

	f32 t = ((check_pos - start_pos) * line) / line_length;
	t = Maths::Clamp(t, 0.0f, 1.0f);
	return start_pos + line * t;
}

void onDie(CBlob@ this)
{
	if (!isClient() ||!this.exists("hit_pos")) return;

	ParticleCasterLine(this.getPosition(), this.get_Vec2f("hit_pos"), color_white);
}
