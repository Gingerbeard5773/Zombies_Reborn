// Zombie Fortress undead merging
// merges undead together when there is too many on the map

#define SERVER_ONLY;

const u8 merge_seconds = 5;
u16 merge_zombies = 300;
u16 maximum_skelepedes = 4;

const u8 skeleton_merge_amount = 4;
const u8 zombie_merge_amount = 2;
const u8 zombieknight_merge_amount = 30;

const u8 merge_attempts = 10;

void onInit(CRules@ this)
{
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		merge_zombies = cfg.exists("merge_zombies") ? cfg.read_u16("merge_zombies") : 400;
		maximum_skelepedes = cfg.exists("maximum_skelepedes") ? cfg.read_u16("maximum_skelepedes") : 4;

		if (merge_zombies == u16(-1))
		{
			this.RemoveScript(getCurrentScriptName());
		}
	}
}

void onTick(CRules@ this)
{
	if (getGameTime() % (30*merge_seconds) != 0) return;

	u16 undead_count = this.get_u16("undead count");
	if (undead_count < merge_zombies) return;

	CBlob@[] skeletons;       getBlobsByName("skeleton", @skeletons);
	CBlob@[] zombies;         getBlobsByName("zombie", @zombies);
	CBlob@[] zombieknights;   getBlobsByName("zombieknight", @zombieknights);
	CBlob@[] skelepedes;      getBlobsByName("skelepede", @skelepedes);
	
	int skeletons_length = skeletons.length;
	int zombies_length = zombies.length;
	int zombieknights_length = zombieknights.length;
	int skelepedes_length = skelepedes.length;
	
	for (u8 m = 0; m < merge_attempts; m++)
	{
		//merge skeletons into wraith
		if (skeletons_length >= skeleton_merge_amount)
		{
			skeletons_length--;
			server_CreateBlob("wraith", -1, skeletons[skeletons_length].getPosition());
			for (u8 i = 0; i < skeleton_merge_amount; i++)
			{
				CBlob@ skeleton = skeletons[skeletons_length];
				skeleton.SetPlayerOfRecentDamage(null, 1.0f);
				skeleton.server_Die();

				skeletons_length--;
				undead_count--;
			}
		}

		if (undead_count < merge_zombies) return;

		//merge zombies into zombie knight
		if (zombies_length >= zombie_merge_amount)
		{
			zombies_length--;
			server_CreateBlob("zombieknight", -1, zombies[zombies_length].getPosition());
			for (u8 i = 0; i < zombie_merge_amount; i++)
			{
				CBlob@ zombie = zombies[zombies_length];
				zombie.SetPlayerOfRecentDamage(null, 1.0f);
				zombie.server_Die();

				zombies_length--;
				undead_count--;
			}
		}

		if (undead_count < merge_zombies) return;
		
		//merge zombie knights into skelepede
		/*if (zombieknights_length >= zombieknight_merge_amount && skelepedes_length < maximum_skelepedes)
		{
			zombieknights_length--;
			Vec2f skelepede_spawn_pos = zombieknights[zombieknights_length].getPosition();
			skelepede_spawn_pos.y = getMap().getMapDimensions().y + 100 + XORRandom(200);
			server_CreateBlob("skelepede", -1, skelepede_spawn_pos);
			skelepedes_length++;
			for (u8 i = 0; i < zombieknight_merge_amount; i++)
			{
				CBlob@ zombieknight = zombieknights[zombieknights_length];
				zombieknight.SetPlayerOfRecentDamage(null, 1.0f);
				zombieknight.server_Die();

				zombieknights_length--;
				undead_count--;
			}
		}

		if (undead_count < merge_zombies) return;*/
	}
}
