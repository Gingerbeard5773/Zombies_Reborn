#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);
	addOnHitOwner(this, @onHitOwner);
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	CSprite@ sprite = equipper.getSprite();
	CSpriteLayer@ buckethead = sprite.addSpriteLayer("buckethead", "BucketHead.png", 16, 16);
	if (buckethead !is null)
	{
		buckethead.SetVisible(true);
		buckethead.SetRelativeZ(1.0f);
		buckethead.SetFacingLeft(sprite.isFacingLeft());
	}
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.getSprite().RemoveSpriteLayer("buckethead");
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ buckethead = equipper_sprite.getSpriteLayer("buckethead");
	if (buckethead is null)
	{
		//add bucket spritelayer. done in onTick because KAG ENGINE IS FUCKING SHIT AND CANT SYNC NEW CLIENTS PROPERLY.
		@buckethead = equipper_sprite.addSpriteLayer("buckethead", "BucketHead.png", 16, 16);
		if (buckethead !is null)
		{
			buckethead.SetVisible(true);
			buckethead.SetRelativeZ(1.0f);
			buckethead.SetFacingLeft(equipper_sprite.isFacingLeft());
		}
	}

	if (buckethead !is null)
	{
		int layer = 0;
		Vec2f headoffset(equipper_sprite.getFrameWidth() / 2, -equipper_sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(equipper_sprite.getBlob(), -1, layer);
		
		headoffset += equipper_sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		
		buckethead.SetOffset(headoffset);

		buckethead.SetVisible(equipper_sprite.isVisible());
		//buckethead.SetRelativeZ(layer * 0.25f + 0.1f);
	}
}

f32 onHitOwner(CBlob@ this, CBlob@ equipper, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f)
	{
		switch(customData)
		{
			case Hitters::bite:
				damage *= 0.95f;
				break;
			case Hitters::sword:
				damage *= 0.95f;
				break;
			case Hitters::bomb:
			case Hitters::explosion:
			case Hitters::keg:
			case Hitters::mine:
			case Hitters::mine_special:
				damage *= 0.95f;
				break;
		}
	}

	return damage;
}
