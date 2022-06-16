#include "Hitters.as";

void onInit(CBlob@ this)
{
	if (!this.exists("attack frequency"))
		 this.set_u8("attack frequency", 30);
		
	if (!this.exists("attack distance"))
		 this.set_f32("attack distance", 2.5f);
		
	if (!this.exists("attack damage"))
		 this.set_f32("attack damage", 1.0f);
		
	if (!this.exists("attack hitter"))
		 this.set_u8("attack hitter", Hitters::bite);
		
	if (!this.exists("attack sound"))
		 this.set_string("attack sound", "ZombieBite");
		 
	this.addCommandID("undead_attack");
}

void onTick(CBlob@ this)
{
	if (!isServer() || this.hasTag("dead")) return;
	
	CBlob@ target = this.getBrain().getTarget();
	if (target !is null && this.getDistanceTo(target) < 72.0f)
	{
		if (getGameTime() >= this.get_u32("next_attack"))
		{
			this.set_u32("next_attack", getGameTime() + this.get_u8("attack frequency") / 2);

			const f32 radius = this.getRadius();
			const f32 attack_distance = radius + this.get_f32("attack distance");

			Vec2f pos = this.getPosition();
			Vec2f vec = this.getAimPos() - pos;
			const f32 angle = vec.Angle();
			
			u16 hitID = 0;
			
			HitInfo@[] hitInfos;
			if (getMap().getHitInfosFromArc(pos, -angle, 90.0f, radius + attack_distance, this, @hitInfos))
			{
				const u16 hitLength = hitInfos.length;
				for (u16 i = 0; i < hitLength; i++)
				{
					CBlob@ b = hitInfos[i].blob;
					if (b !is null && b is target)
					{
						hitID = b.getNetworkID();
						break;
					}
				}
			}
			
			CBitStream bs;
			bs.write_netid(hitID);
			this.SendCommand(this.getCommandID("undead_attack"), bs);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("undead_attack"))
	{	
		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			sprite.SetAnimation("attack");
			sprite.PlayRandomSound(this.get_string("attack sound"));
		}
		
		CBlob@ target = getBlobByNetworkID(params.read_netid());
		if (target !is null && isServer())
		{
			const Vec2f hitvel = target.getPosition() - this.getPosition();
			this.server_Hit(target, target.getPosition(), hitvel, this.get_f32("attack damage"), this.get_u8("attack hitter"), true);
		
			this.set_u32("next_attack", getGameTime() + this.get_u8("attack frequency"));
		}
	}
}
