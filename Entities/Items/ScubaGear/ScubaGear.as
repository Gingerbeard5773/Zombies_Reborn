#include "EquipmentCommon.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	CSprite@ sprite = equipper.getSprite();
	CSpriteLayer@ scubahead = sprite.addSpriteLayer("scubahead", "ScubaGear.png", 16, 16);
	if (scubahead !is null)
	{
		scubahead.SetVisible(true);
		scubahead.SetRelativeZ(0.5f);
		scubahead.SetFacingLeft(sprite.isFacingLeft());
	}

	equipper.Tag("scubagear");
	
	if (equipper.exists("air_count"))
	{
		equipper.set_u8("air_count", 180);
		equipper.RemoveScript("RunnerDrowning.as");
	}
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.Untag("scubagear");
	
	if (equipper.exists("air_count"))
	{
		equipper.AddScript("RunnerDrowning.as");
	}

	equipper.getSprite().RemoveSpriteLayer("scubahead");
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ sprite)
{
	CSpriteLayer@ scubahead = sprite.getSpriteLayer("scubahead");
	if (scubahead !is null)
	{
		int layer = 0;
		Vec2f headoffset(sprite.getFrameWidth() / 2, -sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(sprite.getBlob(), -1, layer);
		
		headoffset += sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -1);
		
		scubahead.SetOffset(headoffset);

		scubahead.SetVisible(sprite.isVisible());
		//scubahead.SetRelativeZ(layer * 0.25f + 0.1f);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player") && !attached.hasTag("can use equipment"))
	{
		attached.Tag("can use equipment");
		attached.AddScript("Equipment.as");
		attached.getSprite().AddScript("Equipment.as");
	}
}
