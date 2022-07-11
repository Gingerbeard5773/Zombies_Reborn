#include "UndeadAttackCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("undead_attack");
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
			if (!map.isTileGroundStuff(tile))
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
				Vec2f bpos = b.getPosition();
				if (!b.hasTag("player") && !b.hasTag("invincible") && (this.isFacingLeft() ? bpos.x < pos.x : bpos.x > pos.x))
				{
					CBitStream bs;
					bs.write_netid(b.getNetworkID());
					bs.write_f32(attackVars.damage * (b.hasTag("stone") ? 0.2f : 1));
					bs.write_bool(false);
					this.SendCommand(this.getCommandID("undead_attack"), bs);
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
			
			u16 hitID = 0;
			
			HitInfo@[] hitInfos;
			if (map.getHitInfosFromArc(pos, -angle, 90.0f, this.getRadius() * 2 + attackVars.arc_length, this, @hitInfos))
			{
				const u16 hitLength = hitInfos.length;
				for (u16 i = 0; i < hitLength; i++)
				{
					CBlob@ b = hitInfos[i].blob;
					if (b !is null && b is target)
					{
						hitID = b.getNetworkID();
						break;
					}
				}
			}
			
			CBitStream bs;
			bs.write_netid(hitID);
			bs.write_f32(attackVars.damage);
			bs.write_bool(true);
			this.SendCommand(this.getCommandID("undead_attack"), bs);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("undead_attack"))
	{
		UndeadAttackVars@ attackVars;
		if (!this.get("attackVars", @attackVars)) return;
		
		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			sprite.SetAnimation("attack");
			sprite.PlayRandomSound(attackVars.sound);
		}
		
		if (isServer())
		{
			CBlob@ target = getBlobByNetworkID(params.read_netid());
			if (target !is null)
			{
				const Vec2f hitvel = target.getPosition() - this.getPosition();
				this.server_Hit(target, target.getPosition(), hitvel, params.read_f32(), attackVars.hitter, true);
				
				if (params.read_bool())
					attackVars.next_attack = getGameTime() + attackVars.frequency;
			}
		}
	}
}
