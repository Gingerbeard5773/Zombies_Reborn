#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "Zombie_Translation.as"

const f32 flying_force_x = 5.0f;
const f32 flying_force_y = -30.0f;

const u32 maximum_time_flown = 75; //2.5 seconds

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "back");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);

	AddIconToken("$wings$", "WingsItem.png", Vec2f(16, 16), 1, 0);

	this.setInventoryName(name(Translate("Wings")));
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.getSprite().RemoveSpriteLayer("wings");
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	if (isOnGround(equipper))
	{
		this.set_u32("time_flown", 0);
	}

	if (equipper.isKeyPressed(key_up))
	{
		Vec2f vel = equipper.getVelocity();
		u32 time_flown = Maths::Min(this.get_u32("time_flown") + 1, maximum_time_flown);
		if (time_flown < maximum_time_flown)
		{
			if (vel.y > 0)
			{
				equipper.setVelocity(Vec2f(vel.x, vel.y - 1));
			}

			equipper.AddForce(Vec2f(equipper.isKeyPressed(key_left) ? -flying_force_x : equipper.isKeyPressed(key_right) ? flying_force_x : 0.0f, flying_force_y));
		}
		else
		{
			if (vel.y > 0.3f)
			{
				equipper.AddForce(Vec2f(0.0f, flying_force_y / 2));
			}
		}
		
		this.set_u32("time_flown", time_flown);
	}
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ wings = getWingsLayer(equipper_sprite);
	if (wings is null) return;

	CBlob@ equipper = equipper_sprite.getBlob();
	wings.SetVisible(true);
	if (!isOnGround(equipper))
	{
		if (this.get_u32("time_flown") >= maximum_time_flown)
		{
			if (wings.isAnimationEnded())
			{
				wings.SetAnimation("glide");
			}
		}
		else if (equipper.isKeyPressed(key_up) && !wings.isAnimation("fly"))
		{
			wings.SetAnimation("fly");
		}
	}
	
	if (wings.isFrame(1))
	{
		equipper_sprite.PlaySound("wingflap"+XORRandom(4), 1.0f, 1.0f);
	}
	
	if (wings.isAnimationEnded())
	{
		wings.SetAnimation("default");
	}
}

bool isOnGround(CBlob@ equipper)
{
	return equipper.isOnGround() || equipper.isOnLadder() || equipper.isInWater();
}

CSpriteLayer@ getWingsLayer(CSprite@ equipper_sprite)
{
	CSpriteLayer@ wings = equipper_sprite.getSpriteLayer("wings");
	if (wings !is null) return wings;

	CBlob@ equipper = equipper_sprite.getBlob();
	@wings = equipper_sprite.addSpriteLayer("wings", "Wings.png", 64, 64, equipper.getTeamNum(), equipper.getSkinNum());
	if (wings !is null)
	{
		Animation@ anim = wings.addAnimation("default", 0, false);
		anim.AddFrame(0);

		Animation@ fly = wings.addAnimation("fly", 3, true);
		fly.AddFrame(1);
		fly.AddFrame(2);
		fly.AddFrame(3);
		fly.AddFrame(4);

		Animation@ glide = wings.addAnimation("glide", 6, true);
		glide.AddFrame(1);
		glide.AddFrame(2);
		glide.AddFrame(3);
		glide.AddFrame(4);

		wings.SetRelativeZ(-10.0f);
		wings.SetVisible(false);
	}

	return wings;
}
