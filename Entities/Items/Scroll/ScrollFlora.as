// scroll script that spawns plants nearby

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

const int radius = 14;

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollFlora);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;
		this.Tag("dead");

		CreateFlora(this);
		
		this.SendCommand(this.getCommandID("client_execute_spell"));
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		Vec2f pos = this.getPosition();
		Sound::Play("MagicWand.ogg", pos);
		Sound::Play("OrbExplosion.ogg", pos, 3.5f);

		if (!isServer()) //no localhost
		{
			CreateFlora(this);
		}
	}
}

void CreateFlora(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	const f32 radsq = radius * 8 * radius * 8;

	for (int x_step = -radius; x_step < radius; ++x_step)
	{
		for (int y_step = -radius; y_step < radius; ++y_step)
		{
			Vec2f off(x_step * map.tilesize, y_step * map.tilesize);

			if (off.LengthSquared() > radsq) continue;

			Vec2f tpos = pos + off;

			TileType t = map.getTile(tpos).type;
			if (t == CMap::tile_empty && map.isTileGround(map.getTile(tpos+Vec2f(0,8)).type))
			{
				map.server_SetTile(tpos, CMap::tile_grass);
			}
			else if (t == CMap::tile_castle && XORRandom(3) == 0)
			{
				map.server_SetTile(tpos, CMap::tile_castle_moss);
			}
			else if (t == CMap::tile_castle_back && XORRandom(3) == 0)
			{
				map.server_SetTile(tpos, CMap::tile_castle_back_moss);
			}
			
			if (!map.isTileSolid(t) && map.isTileGround(map.getTile(tpos+Vec2f(0,8)).type))
			{
				Vec2f vel = getRandomVelocity(90, 1 + float(XORRandom(500)/100), 20);
				string blob_name = "flowers";
				
				if (XORRandom(2) == 0)
				{
					blob_name = "bush";
				}
				else if (XORRandom(3) == 0)
				{
					vel *= 1.2f;
					blob_name = "grain_plant";
				}
				else if (XORRandom(8) == 0)
				{
					vel *= 1.5f;
					blob_name = "tree_bushy";
				}
				
				if (isServer())
				{
					server_CreateBlob(blob_name, -1, tpos);
				}
				
				if (isClient())
				{
					makeGibParticle("GenericGibs.png", tpos, vel, 7, 1+XORRandom(4), Vec2f(8, 8), 2.0f, 20, "fall2");
				}
			}
		}
	}
	
	this.server_Die();
}
