void onInit(CBlob@ this)
{
	this.Tag("undead");
	this.Tag("player");

	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.set_u8("knocked", 1);
	this.addCommandID("knocked"); //unused atm, only added to stop console spam

	this.getSprite().ReloadSprites(3, 0); //change team visual color to purple
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//when this is dead, collide with everything except players
	return (!this.hasTag("dead") ? true : !blob.hasTag("player")) && !blob.hasTag("dead");
}
