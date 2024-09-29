#include "UndeadAttackCommon.as";
#include "CustomTiles.as";

void onInit(CBlob@ this)
{
	this.addCommandID("undead_attack_client");
}

void onTick(CBlob@ this)
{
	if (!isServer() || this.hasTag("dead")) return;
	
	UndeadAttackVars@ attackVars;
	if (!this.get("attackVars", @attackVars)) return;
	
	CMap@ map = getMap();
	const u32 gameTime = getGameTime();
	Vec2f pos = this.getPosition();
	
	//damage tiles
	if (this.isOnGround() || this.isOnWall())
	{
		if (XORRandom(attackVars.map_factor) == 0)
		{
			Vec2f dir = Vec2f(XORRandom(16) - 8, XORRandom(16) - 8) / 8.0f;
			dir.Normalize();
			Vec2f tp = pos + dir * (this.getRadius() + 4.0f);
			TileType tile = map.getTile(tp).type;
			const u8 tile_strength = getTileStrength(map, tile);
			if (XORRandom(tile_strength) == 0)
			{
				map.server_DestroyTile(tp, 0.1f, this);
			}
		}
	}
	
	//damage nearby blobs
	if ((gameTime + this.getNetworkID()) % 30 == 0)
	{
		CBlob@[] overlapping;
		if (this.getOverlapping(@overlapping))
		{
			const u8 overlappingLength = overlapping.length;
			for (u8 i = 0; i < overlappingLength; i++)
			{
				CBlob@ b = overlapping[i];
				if (b.hasTag("dead") || b.hasTag("player") || b.hasTag("invincible")) continue;
				Vec2f bpos = b.getPosition();
				const bool isFacingBlob = this.isFacingLeft() ? bpos.x < pos.x : bpos.x > pos.x;
				if (isFacingBlob)
				{
					server_UndeadAttack(this, b, attackVars.damage * (b.hasTag("stone") ? 0.2f : 1), false, attackVars);
					this.SendCommand(this.getCommandID("undead_attack_client"));
				}
			}
		}
	}
	
	//attack target
	CBlob@ target = this.getBrain().getTarget();
	if (target !is null && this.getDistanceTo(target) < 70.0f)
	{
		if (gameTime >= attackVars.next_attack)
		{
			attackVars.next_attack = gameTime + attackVars.frequency / 2;

			Vec2f vec = this.getAimPos() - pos;
			const f32 angle = vec.Angle();
			
			HitInfo@[] hitInfos;
			if (map.getHitInfosFromArc(pos, -angle, 90.0f, this.getRadius() * 2 + attackVars.arc_length, this, @hitInfos))
			{
				const u16 hitLength = hitInfos.length;
				for (u16 i = 0; i < hitLength; i++)
				{
					CBlob@ b = hitInfos[i].blob;
					if (b is target)
					{
						server_UndeadAttack(this, b, attackVars.damage, true, attackVars);
						break;
					}
				}
			}

			this.SendCommand(this.getCommandID("undead_attack_client"));
		}
	}
}

void server_UndeadAttack(CBlob@ this, CBlob@ target, const f32&in damage, const bool&in set_next, UndeadAttackVars@ attackVars)
{
	const Vec2f hitvel = target.getPosition() - this.getPosition();
	this.server_Hit(target, target.getPosition(), hitvel, damage, attackVars.hitter, true);
	
	if (set_next)
		attackVars.next_attack = getGameTime() + attackVars.frequency;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("undead_attack_client") && isClient())
	{
		UndeadAttackVars@ attackVars;
		if (!this.get("attackVars", @attackVars)) return;

		CSprite@ sprite = this.getSprite();
		sprite.SetAnimation("attack");
		sprite.PlayRandomSound(attackVars.sound);
	}
}

u8 getTileStrength(CMap@ map, TileType tile)
{
	if (isTileGroundStuff(map, tile)) return 2;
	if (isTileIron(tile))             return 5; //iron STRONG.
	return 0;
}
