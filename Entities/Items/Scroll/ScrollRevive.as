// scroll script that revives a player within a radius

#include "GenericButtonCommon.as"
#include "Zombie_Translation.as"
#include "Zombie_StatisticsCommon.as"
#include "Zombie_AchievementsCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("server_revive");
	this.addCommandID("client_revive");

	this.getCurrentScript().tickFrequency = 2;
	this.SetMapEdgeFlags(CBlob::map_collide_sides | CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_nodeath);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	CBitStream params;
	params.write_bool(false);
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_revive"), desc(Translate::ScrollRevive), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_revive") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		CBlob@ caller = player.getBlob();
		if (caller is null) return;
		
		if (this.hasTag("dead")) return;

		bool self_revive;
		if (!params.saferead_bool(self_revive)) return;
		
		u16 revived_player_count = 0;
		Vec2f[] revived_positions;
		
		if (self_revive) //reviving self
		{
			RevivePlayer(player, caller, revived_positions);
			Achievement::server_Unlock(Achievement::SecondChance, player);
			revived_player_count++;
		}

		CBlob@[] blobsInRadius;
		getMap().getBlobsInRadius(this.getPosition(), 40.0f, @blobsInRadius);

		const u16 blobsLength = blobsInRadius.length;
		for (u16 i = 0; i < blobsLength; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (!b.hasTag("dead") || b.hasTag("undead") || b.getTeamNum() != caller.getTeamNum()) continue;

			if (!b.exists("player_username"))
			{
				//revive bots
				if (b.hasTag("migrant"))
				{
					RevivePlayer(null, b, revived_positions);
				}
				continue;
			}

			//revive dead players from their bodies
			CPlayer@ dead_player = getPlayerByUsername(b.get_string("player_username")); //RunnerDeath.as
			if (dead_player is null || dead_player.getBlob() !is null || dead_player.getTeamNum() != 0) continue;

			RevivePlayer(dead_player, b, revived_positions);
			revived_player_count++;
		}
		
		if (revived_player_count >= 3)
		{
			Achievement::server_Unlock(Achievement::Savior, player);
		}

		const u8 revived_count = revived_positions.length;
		if (revived_count > 0)
		{
			CBitStream stream;
			stream.write_u8(revived_count);
			for (u8 i = 0; i < revived_count; i++)
			{
				stream.write_Vec2f(revived_positions[i]);
			}
			this.SendCommand(this.getCommandID("client_revive"), stream);

			Statistics::server_Add("scrolls_used", 1, player);

			this.Tag("dead");
			this.server_Die();
		}
	}
	else if (cmd == this.getCommandID("client_revive") && isClient())
	{
		u8 revived_count;
		if (!params.saferead_u8(revived_count)) return;

		for (u8 i = 0; i < revived_count; i++)
		{
			Vec2f pos;
			if (!params.saferead_Vec2f(pos)) return;

			ParticleZombieLightning(pos);
			Sound::Play("MagicWand.ogg", pos);
			
			for (u8 i = 0; i < 20; i++)
			{
				Vec2f vel = getRandomVelocity(-90.0f, 4, 360.0f);
				ParticleAnimated("HealParticle", pos, vel, float(XORRandom(360)), 1.2f, 4, 0, false);
			}
		}
	}
}

void RevivePlayer(CPlayer@ player, CBlob@ b, Vec2f[]@ revived_positions)
{
	//create new blob for our dead player to use
	CBlob@ newBlob = server_CreateBlobNoInit(b.getName());
	newBlob.server_setTeamNum(b.getTeamNum());

	Vec2f respawnPos = getRespawnLocation(b, player);
	newBlob.setPosition(respawnPos);
	revived_positions.push_back(respawnPos);

	const u32 netid = b.exists("previous blob netid") ? b.get_u32("previous blob netid") : b.getNetworkID();
	newBlob.set_u32("previous blob netid", netid);
	newBlob.Init();

	//b.MoveInventoryTo(newBlob);
	//silly method to transfer the inventory, as engine method doesnt work on dedi
	u16[]@ inventory_netids;
	if (b.get("revive_inventory_netids", @inventory_netids))
	{
		for (int i = 0; i < inventory_netids.length; i++)
		{
			CBlob@ blob = getBlobByNetworkID(inventory_netids[i]);
			if (blob !is null) newBlob.server_PutInInventory(blob);
		}
	}

	if (player !is null)
	{
		newBlob.server_SetPlayer(player);
		newBlob.server_SetHealth(newBlob.getInitialHealth() * 2.0f);
	}

	//kill dead body
	b.server_Die();
}

Vec2f getRespawnLocation(CBlob@ b, CPlayer@ player)
{
	CMap@ map = getMap();
	Vec2f bpos = b.getPosition();

	//if voided, respawn at dormitory
	if (bpos.y > map.getMapDimensions().y - map.tilesize * 3)
	{
		CBlob@[] dorms;
		if (getBlobsByName("dorm", @dorms))
		{
			if (player !is null)
			{
				Achievement::server_Unlock(Achievement::ReturningFromHell, player);
			}

			return dorms[XORRandom(dorms.length)].getPosition();
		}
	}

	//if stuck in walls, move to nearest available space to avoid map collision cancer
	if (!isPassable(bpos, map))
	{
		bpos = getNearestOpenSpace(bpos, map);
	}

	return bpos;
}

Vec2f getNearestOpenSpace(Vec2f pos, CMap@ map)
{
	pos = map.getAlignedWorldPos(pos);
	f32 closestDistance = 999999.0f;
	Vec2f closestPos = pos;

	for (int y = -10; y <= 10; y++)
	{
		for (int x = -10; x <= 10; x++)
		{
			Vec2f neighborPos = pos + Vec2f(x, y) * 8;
			if (!isPassable(neighborPos, map)) continue;

			const f32 distance = (neighborPos - pos).LengthSquared();
			if (distance < closestDistance)
			{
				closestDistance = distance;
				closestPos = neighborPos;
			}
		}
	}
	return closestPos;
}

Vec2f[] walkableDirections = { Vec2f(4, 4), Vec2f(4, -4), Vec2f(-4, 4), Vec2f(-4, -4) };
bool isPassable(Vec2f tilePos, CMap@ map)
{
	if (tilePos.y >= map.tilemapheight - 24) return false;

	for (u8 i = 0; i < 4; i++)
	{
		if (map.isTileSolid(tilePos + walkableDirections[i])) return false;
	}
	return true;
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	CBlob@ holder = getScrollHolder(this);
	if (holder is null || !holder.hasTag("player")) return;

	//hacky method to hit players before they get voided. this stops insta-death claiming the body before the scroll can initiate
	Vec2f pos = holder.getPosition();
	CMap@ map = getMap();
	if (pos.y > map.getMapDimensions().y - 24 && holder.getHealth() > 0.0f)
	{
		holder.server_SetHealth(0.0f);
		this.server_Hit(holder, pos, Vec2f_zero, 0.0f, 1, true);
	}
}

CBlob@ getScrollHolder(CBlob@ this)
{
	CBlob@ inventory_blob = this.getInventoryBlob();
	if (inventory_blob !is null) return inventory_blob;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	return point.getOccupied();
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
}
