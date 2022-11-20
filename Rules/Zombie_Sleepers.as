//Allow reconnecting players to get back into the game fast

#define SERVER_ONLY;

#include "KnockedCommon.as";

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (player is null) return;
	
	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;
	
	const u8 sleepersLength = sleepers.length;
	for (u8 i = 0; i < sleepersLength; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (!sleeper.hasTag("dead") && sleeper.get_string("sleeper_name") == player.getUsername())
		{
			CBlob@ oldBlob = player.getBlob();
			if (oldBlob !is null) oldBlob.server_Die();

			player.server_setTeamNum(sleeper.getTeamNum());
			
			sleeper.server_SetPlayer(player);
			sleeper.set_string("sleeper_name", "");
			sleeper.Untag("sleeper");
			
			//remove knocked
			if (isKnockable(sleeper))
			{
				sleeper.set_u8(knockedProp, 1);

				CBitStream params;
				params.write_u8(1);

				sleeper.SendCommand(sleeper.getCommandID(knockedProp), params);
			}
		}
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();
	if (blob is null || blob.hasTag("undead")) return;
	
	blob.server_SetPlayer(null);
	blob.set_string("sleeper_name", player.getUsername());
	blob.Tag("sleeper");
	
	if (isKnockable(blob))
		setKnocked(blob, 255, true);
}

void onTick(CRules@ this)
{
	if (getGameTime() % 250 != 0) return;
	
	CBlob@[] sleepers;
	if (!getBlobsByTag("sleeper", @sleepers)) return;
	
	const u8 sleepersLength = sleepers.length;
	for (u8 i = 0; i < sleepersLength; i++)
	{
		CBlob@ sleeper = sleepers[i];
		if (isKnockable(sleeper))
			setKnocked(sleeper, 255, true);
	}
}
