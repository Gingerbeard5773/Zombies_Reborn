#include "Hitters.as"
#include "CustomTiles.as"

enum spike_state
{
	normal = 0,
	hidden,
	stabbing,
	falling
};

const string state_prop = "popup state";
const string timer_prop = "popout timer";
const u8 delay_stab = 10;
const u8 delay_retract = 30;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false; // we have our own map collision

	this.Tag("place norotate");
	this.Tag("builder always hit");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.set_u8(state_prop, normal);
	this.set_u8(timer_prop, 0);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	tileCheck(this, this.getPosition(), getMap(), false, false);

	this.getSprite().PlaySound("/build_wall2.ogg");
}

const Vec2f[] directions = { Vec2f(0, -8),  Vec2f(8, 0), Vec2f(0, 8) , Vec2f(-8, 0) };

void tileCheck(CBlob@ this, Vec2f pos, CMap@ map, bool&out onSurface, bool&out onStone)
{
	onSurface = onStone = false;
	for (f32 i = 0; i < 4; i++)
	{
		Tile tile = map.getTile(pos + directions[i]);
		if (!map.isTileSolid(tile)) continue;

		const f32 angle = i * 90.0f - 180.0f;
		this.setAngleDegrees(angle);
		onSurface = true;
		onStone = canRetractSpike(tile.type, map);

		if (onStone) return;
	}
}

bool canRetractSpike(TileType tile, CMap@ map)
{
	return map.isTileCastle(tile) || isTileIron(tile);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	u8 state = this.get_u8(state_prop);
	if (state == falling)
	{
		this.getShape().SetStatic(false);
		this.setAngleDegrees(180.0f);
		if (isServer() && (map.isTileSolid(map.getTile(pos)) || map.rayCastSolid(pos - this.getVelocity(), pos)))
		{
			this.server_Hit(this, pos, Vec2f(0, -1), 3.0f, Hitters::fall, true);
		}
		if (isClient())
		{
			this.getSprite().SetAnimation("default");
			onHealthChange(this, 1.0f);
		}
		return;
	}

	//check support/placement status
	bool onSurface, onStone;
	tileCheck(this, pos, map, onSurface, onStone);
	
	if (!onSurface)
	{
		this.getCurrentScript().tickFrequency = 1;
		
		if (isServer())
		{
			this.set_u8(state_prop, falling);
			this.Sync(state_prop, true);
		}
		return;
	}

	if (isClient() && !this.hasTag("_frontlayer"))
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetZ(500.0f);

		CSpriteLayer@ panel = sprite.addSpriteLayer("panel", sprite.getFilename() , 8, 16, this.getTeamNum(), this.getSkinNum());
		if (panel !is null)
		{
			panel.SetOffset(Vec2f(0, 3));
			panel.SetRelativeZ(500.0f);

			Animation@ animcharge = panel.addAnimation("default", 0, false);
			animcharge.AddFrame(6);
			animcharge.AddFrame(7);

			this.Tag("_frontlayer");
		}
	}

	if (onStone)
	{
		u8 timer = this.get_u8(timer_prop);
		const u32 tickFrequency = 3;
		this.getCurrentScript().tickFrequency = tickFrequency;

		if (state == hidden)
		{
			this.getSprite().SetAnimation("hidden");
			const int team = this.getTeamNum();
			CBlob@[] overlapping;
			if (this.getOverlapping(@overlapping))
			{
				for (u16 i = 0; i < overlapping.length; i++)
				{
					CBlob@ b = overlapping[i];
					if (team == b.getTeamNum() || !canStab(b)) continue;

					state = stabbing;
					timer = delay_stab;
					break;
				}
			}
		}
		else if (state == stabbing)
		{
			if (timer >= tickFrequency)
			{
				timer -= tickFrequency;
			}
			else
			{
				state = normal;
				timer = delay_retract;

				this.getSprite().SetAnimation("default");
				this.getSprite().PlaySound("/SpikesOut.ogg");

				CBlob@[] overlapping;
				if (this.getOverlapping(@overlapping))
				{
					for (u16 i = 0; i < overlapping.length; i++)
					{
						CBlob@ b = overlapping[i];
						if (!canStab(b)) continue;

						this.server_Hit(b, pos, b.getVelocity() * -1, 0.75f, Hitters::spikes, true);
					}
				}
			}
		}
		else //state is normal
		{
			if (timer >= tickFrequency)
			{
				timer -= tickFrequency;
			}
			else
			{
				state = hidden;
				timer = 0;
			}
		}
		this.set_u8(state_prop, state);
		this.set_u8(timer_prop, timer);
	}
	else
	{
		this.getCurrentScript().tickFrequency = 25;
		this.getSprite().SetAnimation("default");
		this.set_u8(timer_prop, 0);
	}
	onHealthChange(this, 1.0f);
}

bool canStab(CBlob@ b)
{
	return b.hasTag("flesh") && b.getName() != "chicken";
}

//physics logic
void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point)
{
	if (!isServer() || this.isAttached()) return;

	if (blob is null) return;

	const u8 state = this.get_u8(state_prop);
	if (state == hidden || state == stabbing) return;

	// only hit living things
	if (!blob.hasTag("flesh")) return;

	if (state == falling)
	{
		const f32 vellen = this.getVelocity().Length();
		if (vellen < 4.0f) //slow, minimal dmg
			this.server_Hit(blob, point, Vec2f(0, 1), 1.0f, Hitters::spikes, true);
		else if (vellen < 5.5f) //faster, kill archer
			this.server_Hit(blob, point, Vec2f(0, 1), 2.0f, Hitters::spikes, true);
		else if (vellen < 7.0f) //faster, kill builder
			this.server_Hit(blob, point, Vec2f(0, 1), 3.0f, Hitters::spikes, true);
		else			//fast, instakill
			this.server_Hit(blob, point, Vec2f(0, 1), 4.0f, Hitters::spikes, true);
		return;
	}

	f32 damage = 0.0f;
	const f32 angle = this.getAngleDegrees();
	Vec2f vel = blob.getOldVelocity();
	const bool b_falling = Maths::Abs(vel.y) > 0.5f;
	const f32 verDist = Maths::Abs(this.getPosition().y - blob.getPosition().y);
	const f32 horizDist = Maths::Abs(this.getPosition().x - blob.getPosition().x);

	if (angle > -135.0f && angle < -45.0f && vel.x > 0)
	{
		if (normal.x > 0.5f && verDist < 6.1f && vel.x > 1.0f)
			damage = 1.0f;
		else if (b_falling)
			damage = 0.5f;
	}
	else if (angle > 45.0f && angle < 135.0f && vel.x < 0)
	{
		if (normal.x < -0.5f && verDist < 6.1f && vel.x < -1.0f)
			damage = 1.0f;
		else if (b_falling)
			damage = 0.5f;
	}
	else if ((angle <= -135.0f || angle >= 135.0f) && vel.y < 0)
	{
		if (normal.y < -0.5f && horizDist < 6.1f)
			damage = 1.0f;
	}
	else if (normal.y > 0.5f && horizDist < 6.1f)
	{
		damage = 1.0f;
	}

	if (damage > 0)
	{
		this.server_Hit(blob, point, vel * -1, damage, Hitters::spikes, true);
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null && hitBlob !is this && damage > 0.0f)
	{
		CSprite@ sprite = this.getSprite();
		sprite.PlaySound("/SpikesCut.ogg");

		if (!this.hasTag("bloody"))
		{
			sprite.animation.frame += 3;
			this.Tag("bloody");
		}
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	const f32 hp = this.getHealth();
	const f32 full_hp = this.getInitialHealth();
	int frame = (hp > full_hp * 0.9f) ? 0 : ((hp > full_hp * 0.4f) ? 1 : 2);

	if (this.hasTag("bloody"))
	{
		frame += 3;
	}
	this.getSprite().animation.frame = frame;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	switch (customData)
	{
		case Hitters::bomb:
			dmg *= 0.5f;
			break;

		case Hitters::keg:
			dmg *= 2.0f;

		case Hitters::arrow:
			dmg = 0.0f;
			break;

		case Hitters::cata_stones:
			dmg *= 3.0f;
			break;
	}
	return dmg;
}
