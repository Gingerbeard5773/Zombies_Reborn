void onInit(CBlob@ this)
{
	this.Tag("undead");
	this.Tag("player");

	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.set_u8("knocked", 1);
	this.addCommandID("knocked"); //unused atm, only added to stop console spam

	this.server_setTeamNum(3);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//when this is dead, collide with everything except players
	return (!this.hasTag("dead") ? true : !blob.hasTag("player")) && !blob.hasTag("dead");
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null && player.isMyPlayer())
	{
		CCamera@ cam = getCamera();
		if (cam !is null)
		{
			cam.targetDistance = Maths::Min(1.5f, cam.targetDistance);
		}
		Sound::Play("switch.ogg");
	}
}
