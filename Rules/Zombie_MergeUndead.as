// Zombie Fortress undead merging
// primitive script that 'merges' zombies together when there is too many on the map

#define SERVER_ONLY;

const int merge_seconds = 5;
u16 merge_zombies = 300;

void onInit(CRules@ this)
{
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		merge_zombies = cfg.exists("merge_zombies") ? cfg.read_u16("merge_zombies") : 400;
		if (merge_zombies == u16(-1))
		{
			this.RemoveScript(getCurrentScriptName());
		}
	}
}

void onTick(CRules@ this)
{
	if (getGameTime() % (30*merge_seconds) != 0) return;

	if (this.get_u16("undead count") < merge_zombies) return;

	CBlob@[] skeletons; getBlobsByName("skeleton", @skeletons);
	CBlob@[] zombies;   getBlobsByName("zombie", @zombies);
	
	if (skeletons.length > zombies.length)
	{
		if (skeletons.length > 3)
		{
			server_CreateBlob("wraith", -1, skeletons[2].getPosition());
			for (u8 i = 0; i < 4; i++)
			{
				CBlob@ skeleton = skeletons[i];
				skeleton.SetPlayerOfRecentDamage(null, 1.0f);
				skeleton.server_Die();
			}
		}
	}
	else
	{
		if (zombies.length > 1)
		{
			server_CreateBlob("zombieknight", -1, zombies[1].getPosition());
			for (u8 i = 0; i < 2; i++)
			{
				CBlob@ zombie = zombies[i];
				zombie.SetPlayerOfRecentDamage(null, 1.0f);
				zombie.server_Die();
			}
		}
	}
}
