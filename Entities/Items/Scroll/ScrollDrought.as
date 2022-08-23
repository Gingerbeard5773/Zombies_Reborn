// scroll script that removes a huge orb of water

#include "GenericButtonCommon.as";

const int radius = 30;

void onInit(CBlob@ this)
{
	this.addCommandID("drought");

	this.set_u32("drought_called", 0);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || (this.getPosition() - caller.getPosition()).Length() > 50.0f) return;

	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("drought"), getTranslatedString("Use this to dry up an orb of water."));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("drought"))
	{
		const u32 timer = getGameTime() - this.get_u32("drought_called");
		if (timer < 30) return;
		
		this.set_u32("drought_called", getGameTime());

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
				if (map.isInWater(tpos))
				{
					map.server_setFloodWaterWorldspace(tpos, false);
					acted = true;
				}
			}
		}


		if (acted)
		{
			this.server_Die();
			Sound::Play("MagicWand.ogg", pos, 1.0f, 0.75f);
		}
	}
}
