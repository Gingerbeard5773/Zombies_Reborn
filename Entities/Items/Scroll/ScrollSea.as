// scroll script that creates water

#include "GenericButtonCommon.as";
#include "Zombie_Translation.as";

const u8 required_ground_at_Y = 8; //amount of ground tiles at the scroll's Y level needed to activate

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), Translate::ScrollSea);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;

		CMap@ map = getMap();
		Vec2f pos = this.getPosition();
		
		int ground_tiles = 0;
		for (int i = 0; i < map.tilemapwidth; i++)
		{
			TileType t = map.getTile(Vec2f(i*map.tilesize, pos.y)).type;
			if (!map.isTileGroundStuff(t)) continue;
			
			ground_tiles++;
			if (ground_tiles >= required_ground_at_Y)
			{
				map.server_setFloodWaterWorldspace(pos, true);
				this.server_Die();
				this.Tag("dead");
				
				break;
			}
		}
	}
}

void onDie(CBlob@ this)
{
	ParticleZombieLightning(this.getPosition());
	Sound::Play("ResearchComplete.ogg");
}
