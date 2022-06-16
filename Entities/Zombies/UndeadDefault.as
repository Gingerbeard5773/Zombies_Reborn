void onInit(CBlob@ this)
{
	this.Tag("undead");
	this.Tag("player");
	
	this.set_u8("knocked", 1);
	this.addCommandID("knocked"); //unused atm, only added to stop console spam
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//when this is dead, collide with everything except players
	return (!this.hasTag("dead") ? true : !blob.hasTag("player")) && !blob.hasTag("dead");
}
