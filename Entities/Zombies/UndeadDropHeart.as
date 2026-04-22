//drop a heart on death

#define SERVER_ONLY

void onDie(CBlob@ this)
{
	//no heart if sawed
	if (this.hasTag("switch class") || this.hasTag("sawed")) return;

	CPlayer@ killer = this.getPlayerOfRecentDamage();
	if (killer is null) return;

	CBlob@ killerBlob = killer.getBlob();
	if (killerBlob is null) return;

	//no heart if killer isnt low on health
	if (killerBlob.getHealth() > Maths::Max(killerBlob.getInitialHealth() * 0.5f, 1.0f)) return;
	
	//no heart if we already have a drop heart
	if (killer.exists("drop_heart"))
	{
		CBlob@ old_heart = getBlobByNetworkID(killer.get_netid("drop_heart"));
		if (old_heart !is null && old_heart.getName() == "heart") return;
	}

	CBlob@ heart = server_CreateBlob("heart", -1, this.getPosition());
	if (heart !is null)
	{
		Vec2f vel(XORRandom(2) == 0 ? -2.0 : 2.0f, -5.0f);
		heart.setVelocity(vel);
		heart.set_netid("healer", killer.getNetworkID());
		killer.set_netid("drop_heart", heart.getNetworkID());
	}
}
