// scroll script that repairs tiles around the player

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";
#include "CustomTiles.as";

const int radius = 30;
const f32 radsq = radius * 8 * radius * 8;

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollRepair);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;
		this.Tag("dead");
		
		CMap@ map = getMap();
		Vec2f pos = this.getPosition();
		for (int x_step = -radius; x_step < radius; ++x_step)
		{
			for (int y_step = -radius; y_step < radius; ++y_step)
			{
				Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
				if (off.LengthSquared() > radsq) continue;

				Vec2f tpos = pos + off;
				TileType t = map.getTile(tpos).type;
				if (t == CMap::tile_empty) continue;

				if (map.isTileGround(t))
				{
					map.server_SetTile(tpos, CMap::tile_ground);
				}
				else if (map.isTileStone(t) && !map.isTileThickStone(t))
				{
					map.server_SetTile(tpos, CMap::tile_stone);
				}
				else if (map.isTileCastle(t))
				{
					map.server_SetTile(tpos, CMap::tile_castle);
				}
				else if (t >= CMap::tile_castle_back && t <= CMap::tile_castle_back + 15)
				{
					map.server_SetTile(tpos, CMap::tile_castle_back);
				}
				else if (isTileIron(t))
				{
					map.server_SetTile(tpos, CMap::tile_iron);
				}
				else if (isTileBIron(t))
				{
					map.server_SetTile(tpos, CMap::tile_biron);
				}
			}
		}
		
		CBlob@[] blobs;
		map.getBlobsInRadius(pos, radius, @blobs);
		for (u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob.hasTag("flesh") || blob.hasTag("scenary") || blob.hasTag("undead") || blob.hasTag("player")) continue;
			
			if (blob.getHealth() >= blob.getInitialHealth()) continue;

			blob.server_SetHealth(blob.getInitialHealth());
		}

		this.server_Die();

		this.SendCommand(this.getCommandID("client_execute_spell"));
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		CMap@ map = getMap();
		Vec2f pos = this.getPosition();
		for (int x_step = -radius; x_step < radius; ++x_step)
		{
			for (int y_step = -radius; y_step < radius; ++y_step)
			{
				Vec2f off(x_step * map.tilesize, y_step * map.tilesize);
				if (off.LengthSquared() > radsq) continue;
				
				if (XORRandom(2) == 0)
				{
					Vec2f tpos = pos + off;
					Vec2f vel = getRandomVelocity(-90.0f, 2, 360.0f);
					ParticleAnimated("MediumSteam", tpos, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
				}
			}
		}

		Sound::Play("Powerdown.ogg", pos, 1.5f, 1.5f);
		Sound::Play("MagicWand.ogg", pos, 1.0f, 1.0f);
	}
}
