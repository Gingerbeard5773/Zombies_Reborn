// Zombie Fortress undead merging
// primitive script that 'merges' zombies together when there is too many on the map

#define SERVER_ONLY;

const int merge_seconds = 5;
u16 maximum_zombies = 400;

void onInit(CRules@ this)
{
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		maximum_zombies = cfg.exists("maximum_zombies") ? cfg.read_u16("maximum_zombies") : 400;
		
		const bool merge_zombies = cfg.exists("merge_zombies") ? cfg.read_bool("merge_zombies") : true;
		if (!merge_zombies)
		{
			this.RemoveScript(getCurrentScriptName());
		}
	}
}

void onTick(CRules@ this)
{
	if (getGameTime() % (30*merge_seconds) != 0) return;

	if (this.get_u16("undead count") < maximum_zombies) return;

	CBlob@[] skeletons; getBlobsByName("skeleton", @skeletons);
	CBlob@[] zombies;   getBlobsByName("zombie", @zombies);
	
	if (skeletons.length > zombies.length)
	{
		if (skeletons.length > 3)
		{
			server_CreateBlob("wraith", -1, skeletons[2].getPosition());
			for (u8 i = 0; i < 4; i++)
			{
				skeletons[i].server_Die();
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
				zombies[i].server_Die();
			}
		}
	}
}
