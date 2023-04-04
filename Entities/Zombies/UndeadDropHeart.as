//drop a heart on death

#define SERVER_ONLY

void onDie(CBlob@ this)
{
	if (this.hasTag("switch class") || this.hasTag("sawed")) //no heart if sawed
		return;

	CPlayer@ killer = this.getPlayerOfRecentDamage();
	if (killer is null) return;

	CBlob@ killerBlob = killer.getBlob();
	if (killerBlob is null ||
		killerBlob.getHealth() > killerBlob.getInitialHealth() - 0.25f) return; //no heart if killer doesn't need one

	CBlob@ heart = server_CreateBlob("heart", -1, this.getPosition());
	if (heart !is null)
	{
		Vec2f vel(XORRandom(2) == 0 ? -2.0 : 2.0f, -5.0f);
		heart.setVelocity(vel);
		heart.set_netid("healer", killer.getNetworkID());
	}
}
