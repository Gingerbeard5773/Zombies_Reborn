// scroll script that converts stone blocks into iron blocks

#include "GenericButtonCommon.as"
#include "Zombie_Translation.as"
#include "CustomTiles.as"
#include "Zombie_StatisticsCommon.as"

const int radius = 9;

void onInit(CBlob@ this)
{
	this.addCommandID("server_execute_spell");
	this.addCommandID("client_execute_spell");

	this.set_f32("scroll_range", radius*8);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("server_execute_spell"), desc(Translate("ScrollIron")));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_execute_spell") && isServer())
	{
		if (this.hasTag("dead")) return;

		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

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

				if (map.isTileCastle(t))
				{
					acted = true;
					map.server_SetTile(tpos, CMap::tile_iron);
				}
				else if (t >= CMap::tile_castle_back && t <= CMap::tile_castle_back + 15 || t == CMap::tile_castle_back_moss)
				{
					acted = true;
					map.server_SetTile(tpos, CMap::tile_biron);
				}
			}
		}
		
		const string[] input =
		{
			"stone_door",
			"spikes"
		};
		
		const string[] result =
		{
			"iron_door",
			"iron_spikes"
		};
		
		CBlob@[] blobs;
		map.getBlobsInRadius(pos, radius*8.0f, @blobs);
		for (u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			const int index = input.find(blob.getName());
			if (index == -1 || blob.hasTag("temp blob")) continue;

			CBlob@ b = server_CreateBlob(result[index], blob.getTeamNum(), blob.getPosition());
			if (b is null) continue;

			b.setAngleDegrees(blob.getAngleDegrees());
			b.getShape().SetStatic(true);

			blob.server_Die();
		}

		if (acted)
		{
			Statistics::server_Add("scrolls_used", 1, player);
			this.Tag("dead");
			this.server_Die();

			this.SendCommand(this.getCommandID("client_execute_spell"));
		}
	}
	else if (cmd == this.getCommandID("client_execute_spell") && isClient())
	{
		Sound::Play("MagicWand.ogg", this.getPosition());
	}
}
