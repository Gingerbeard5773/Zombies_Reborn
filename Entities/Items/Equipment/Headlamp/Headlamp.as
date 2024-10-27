//Gingerbeard @ October 24, 2024

#include "EquipmentCommon.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack
	
	AddIconToken("$headlamp_icon$", "Headlamp.png", Vec2f(16, 16), 1, 0);
	this.set_string("equipment_icon", "$headlamp_icon$");

	this.SetLightRadius(54.0f);
	
	#ifdef STAGING
	this.SetLightRadius(80.0f);
	#endif
	
	this.SetLightColor(SColor(255, 255, 240, 171));

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);
	addOnClientJoin(this, @onClientJoin);
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	this.set_netid("equipper_id", equipper.getNetworkID());
	this.SetLight(true);
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	this.getSprite().SetVisible(true);
	equipper.getSprite().RemoveSpriteLayer("headlamp");
	
	this.set_netid("equipper_id", 0);
	this.SetLight(false);
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	this.getSprite().SetVisible(false);
	this.setPosition(equipper.getPosition());
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ headlamp = equipper_sprite.getSpriteLayer("headlamp");
	if (headlamp is null)
	{
		//add headlamp spritelayer. done in onTick because KAG ENGINE IS FUCKING SHIT AND CANT SYNC NEW CLIENTS PROPERLY.
		@headlamp = equipper_sprite.addSpriteLayer("headlamp", "Headlamp.png", 16, 16);
		if (headlamp !is null)
		{
			headlamp.SetVisible(true);
			headlamp.SetRelativeZ(1);
			//headlamp.SetOffset(Vec2f(0, -4));

			if (equipper_sprite.isFacingLeft())
				headlamp.SetFacingLeft(true);

			Animation@ anim = headlamp.addAnimation("lit", 3, true);
			anim.AddFrame(1);
			anim.AddFrame(2);
			anim.AddFrame(3);
			headlamp.SetAnimation(anim);
		}
	}
	if (headlamp !is null)
	{
		Vec2f headoffset(equipper_sprite.getFrameWidth() / 2, -equipper_sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(equipper_sprite.getBlob(), -1, 0);
       
		headoffset += equipper_sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(1, -6);
		headlamp.SetOffset(headoffset);
	}
}

void onClientJoin(CBlob@ this, CBlob@ equipper)
{
	OnEquip(this, equipper);
}
