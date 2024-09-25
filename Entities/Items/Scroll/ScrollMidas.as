// scroll script that converts stone tiles into gold ore tiles

#include "GenericButtonCommon.as";

const int radius = 5;

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), getTranslatedString("Use this to turn all stone in the area into gold"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;
		bool acted = false;
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
				if (map.isTileStone(t) || map.isTileThickStone(t))
				{
					if (isServer())
					{
						map.server_SetTile(tpos, CMap::tile_gold);
					}
					acted = true;
				}
			}
		}

		if (acted)
		{
			this.Tag("dead");
			this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	Sound::Play("MagicWand.ogg", this.getPosition());
}
