//Undead Knocked Common
//Gingerbeard @ May 2nd, 2026

void setUndeadKnocked(CBlob@ blob, const int&in ticks, const bool&in sync = false)
{
	blob.set_u32("stun_time", getGameTime() + ticks);

	if (isServer())
	{
		if (sync)
		{
			blob.Sync("stun_time", true);
		}

		blob.set_u8("brain_delay", ticks);

		blob.setKeyPressed(key_left, false);
		blob.setKeyPressed(key_right, false);
		blob.setKeyPressed(key_up, false);
		blob.setKeyPressed(key_down, false);

		blob.server_DetachAll(); //save players from gregs
	}
}

bool isUndeadKnocked(CBlob@ blob)
{
	return blob.get_u32("stun_time") > getGameTime();
}

bool isUndeadKnockable(CBlob@ blob)
{
	return blob.exists("stun_time");
}
