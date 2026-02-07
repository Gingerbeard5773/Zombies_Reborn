#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "Zombie_AchievementsCommon.as"

/*
 Zombie fortress modifications for this base script
	* Revival scroll necessary logic
	* Dead bodies turn into their respective zombie variant
	* Inventory access logic for bots
	* Crowd Crush achievement logic
*/

const u32 VANISH_BODY_SECS = 200;
const f32 CARRIED_BLOB_VEL_SCALE = 1.0;
const f32 MEDIUM_CARRIED_BLOB_VEL_SCALE = 0.8;
const f32 HEAVY_CARRIED_BLOB_VEL_SCALE = 0.6;

void onInit(CBlob@ this)
{
	this.set_f32("hit dmg modifier", 0.0f);
	this.getCurrentScript().tickFrequency = 0; // make it not run ticks until dead
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// make dead state
	// make sure this script is at the end of onHit scripts for it gets the final health

	if (this.getHealth() > 0.0f || this.hasTag("dead"))
	{
		this.set_u32("death time", getGameTime());
		return damage;
	}

	if (UseRevivalScroll(this))
	{
		return 0.0f;
	}

	this.Tag("dead");
	this.set_u32("death time", getGameTime());
	this.UnsetMinimapVars(); //remove minimap icon

	// we want the corpse to stay but player to respawn so we force a die event in rules
	if (isServer())
	{
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{
			AttemptAchievement(this, player);

			this.set_string("player_username", player.getUsername()); //for revival scroll

			getRules().server_PlayerDie(player);
			this.server_SetPlayer(null);
		}
		else
		{
			getRules().server_BlobDie(this);
		}
	}

	// add pickup attachment so we can pickup body
	CAttachment@ a = this.getAttachments();
	if (a !is null)
	{
		AttachmentPoint@ pickup = a.getAttachmentPoint("PICKUP", false);
		if (pickup is null)
			@pickup = a.AddAttachmentPoint("PICKUP", false);
		if (pickup !is null)
			pickup.offset = Vec2f(-4, 0);
	}

	// sound

	if (this.getSprite() !is null) //moved here to prevent other logic potentially not getting run
	{
		f32 gibHealth = this.get_f32("gib health");

		if (this !is hitterBlob || customData == Hitters::fall)
		{
			if (this.isInWater())
			{
				if (this.getHealth() > gibHealth)
				{
					this.getSprite().PlaySound("Gurgle");
				}
			}
			else
			{
				if (this.getHealth() > gibHealth / 2.0f)
				{
					this.getSprite().PlaySound("WilhelmShort.ogg", this.getSexNum() == 0 ? 1.0f : 1.5f);
				}
				else if (this.getHealth() > gibHealth)
				{
					this.getSprite().PlaySound("Wilhelm.ogg", 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
				}
			}
		}

		// turn off bow sound (emit sound)
		this.getSprite().SetEmitSoundPaused(true);
	}

	this.getCurrentScript().tickFrequency = 30;

	this.set_f32("hit dmg modifier", 0.5f);

	// new physics vars so bodies don't slide
	this.getShape().setFriction(0.75f);
	this.getShape().setElasticity(0.2f);

	// disable tags
	this.Untag("shielding");
	this.Untag("player");
	this.Tag("dead player");
	this.getShape().getVars().isladder = false;
	this.getShape().getVars().onladder = false;
	this.getShape().checkCollisionsAgain = true;
	this.getShape().SetGravityScale(1.0f);
	//set velocity to blob in hand
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null)
	{
		Vec2f current_vel = this.getVelocity() * CARRIED_BLOB_VEL_SCALE;
		if (carried.hasTag("medium weight"))
			current_vel = current_vel * MEDIUM_CARRIED_BLOB_VEL_SCALE;
		else if (carried.hasTag("heavy weight"))
			current_vel = current_vel * HEAVY_CARRIED_BLOB_VEL_SCALE;
		//the item is detatched from the player before setting the velocity
		//otherwise it wont go anywhere
		this.server_DetachFrom(carried);
		carried.setVelocity(current_vel);
	}
	// fall out of attachments/seats // drop all held things
	this.server_DetachAll();

	StuffFallsOut(this);

	return damage;
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	// can't be put in player inventory.
	return inventoryBlob.getPlayer() is null;
}

void onTick(CBlob@ this)
{
	// (drop anything attached)
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null)
	{
		carried.server_DetachFromAll();
	}

	//die if we've "expired"
	if (this.get_u32("death time") + VANISH_BODY_SECS * getTicksASecond() < getGameTime())
	{
		//make zombie from body
		
		ParticleZombieLightning(this.getPosition());
		
		if (isServer())
		{
			string blobname = "wraith";
			
			if (this.getName() == "knight")        blobname = "zombieknight";
			else if (this.getName() == "builder")  blobname = "zombie";
			
			server_CreateBlob(blobname, -1, this.getPosition());
				
			this.server_Die();
		}
	}
}

// reset vanish counter on pickup
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this.hasTag("dead"))
	{
		this.set_u32("death time", getGameTime());
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (!canSeeButtons(this, forBlob)) return false;

	const u16 inv_access = getRules().get_u16("inventory access");
	if (this.getNetworkID() == inv_access) return true;

	return (this.hasTag("dead") && this.getInventory().getItemsCount() > 0);
}

void StuffFallsOut(CBlob@ this)
{
	if (!isServer()) return;

	CInventory@ inv = this.getInventory();
	while (inv !is null && inv.getItemsCount() > 0)
	{
		CBlob @blob = inv.getItem(0);
		this.server_PutOutInventory(blob);
		blob.setVelocity(this.getVelocity() + getRandomVelocity(90, 4.0f, 40));
	}
}

bool UseRevivalScroll(CBlob@ this)
{
	CBlob@ scroll = getRevivalScroll(this);
	if (scroll is null || this.getPlayer() is null) return false;

	if (isServer())
	{
		//send over the inventory
		u16[] inventory_netids;
		CInventory@ inv = this.getInventory();
		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			inventory_netids.push_back(inv.getItem(i).getNetworkID());
		}
		this.set("revive_inventory_netids", inventory_netids);
	}
	
	if (this.isMyPlayer())
	{
		CBitStream params;
		params.write_bool(true);
		scroll.SendCommand(scroll.getCommandID("server_revive"), params);
	}

	return true;
}

CBlob@ getRevivalScroll(CBlob@ this)
{
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null && carried.hasCommandID("server_revive")) return carried;

	CInventory@ inventory = this.getInventory();
	if (inventory !is null)
	{
		for (u16 i = 0; i < inventory.getItemsCount(); ++i)
		{
			CBlob@ blob = inventory.getItem(i);
			if (blob.hasCommandID("server_revive")) return blob;
		}
	}

	return null;
}

void AttemptAchievement(CBlob@ this, CPlayer@ player)
{
	CBlob@[] blobs;
	getMap().getBlobsInRadius(this.getPosition(), 16*4, @blobs);
	
	u16 undead_count = 0;

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (blob.hasTag("undead") && !blob.hasTag("dead"))
		{
			undead_count++;
		}
	}

	if (undead_count >= 20)
	{
		Achievement::server_Unlock(Achievement::CrowdCrush, player);
	}
}
