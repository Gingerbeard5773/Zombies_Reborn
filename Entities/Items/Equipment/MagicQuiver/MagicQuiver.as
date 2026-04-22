#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "Zombie_Translation.as"

const u32 arrow_delay = 8 * 30;

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "back");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);

	AddIconToken("$magicquiver$", "MagicQuiver.png", Vec2f(16, 16), 0, 0);

	this.setInventoryName(name(Translate("MagicQuiver")));
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	equipper.getSprite().RemoveSpriteLayer("magicquiver");
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	if (!isServer()) return;

	if (this.get_u32("next_magic_arrow") > getGameTime()) return;

	CInventory@ inv = equipper.getInventory();
	if (inv is null) return;

	CBlob@ arrow = getBlobByNetworkID(this.get_netid("magic_arrow_netid"));
	if (arrow !is null)
	{
		if (!inv.isInInventory(arrow) && !arrow.isAttachedTo(equipper))
		{
			arrow.server_Die();
		}
		return;
	}

	if (inv.isFull()) return;

	const string[] arrow_types = { "mat_waterarrows", "mat_firearrows", "mat_bombarrows", "mat_molotovarrows", "mat_fireworkarrows" };
	const string random_type = arrow_types[XORRandom(arrow_types.length)];
	CBlob@ mat = server_CreateBlob(random_type, equipper.getTeamNum(), equipper.getPosition());
	if (mat is null) return;

	equipper.server_PutInInventory(mat);
	this.set_netid("magic_arrow_netid", mat.getNetworkID());

	this.set_u32("next_magic_arrow", getGameTime() + arrow_delay);
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ quiver = equipper_sprite.getSpriteLayer("magicquiver");
	if (quiver is null)
	{
		@quiver = equipper_sprite.addSpriteLayer("magicquiver", "MagicQuiver.png", 16, 16);
		if (quiver !is null)
		{
			quiver.SetVisible(true);
			quiver.SetRelativeZ(-2);
			quiver.SetOffset(Vec2f(4, -2));

			if (equipper_sprite.isFacingLeft())
				quiver.SetFacingLeft(true);
		}
	}
	if (quiver !is null)
	{
		Vec2f headoffset(equipper_sprite.getFrameWidth() / 2, -equipper_sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(equipper_sprite.getBlob(), -1, 0);

		headoffset += equipper_sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(5, 3);
		quiver.SetOffset(headoffset);
	}
}
