#include "EquipmentCommon.as"
#include "RunnerTextures.as"
#include "Zombie_Translation.as"

void onInit(CBlob@ this)
{
	this.set_string("equipment_slot", "head");
	this.Tag("ignore_saw");
	this.Tag("sawed");//hack

	addOnEquip(this, @OnEquip);
	addOnUnequip(this, @OnUnequip);
	addOnTickEquipped(this, @onTickEquipped);
	addOnTickSpriteEquipped(this, @onTickSpriteEquipped);

	AddIconToken("$crowntelepathy$", "CrownTelepathy.png", Vec2f(16, 16), 0, 0);

	this.SetLightRadius(34.0f);

	#ifdef STAGING
	this.SetLightRadius(60.0f);
	#endif

	this.SetLightColor(SColor(255, 235, 250, 171));

	dictionary telepath_netids;
	this.set("telepath_netids", telepath_netids);

	this.setInventoryName(name(Translate("CrownTelepathy")));
}

void OnEquip(CBlob@ this, CBlob@ equipper)
{
	this.SetLight(true);
}

void OnUnequip(CBlob@ this, CBlob@ equipper)
{
	this.SetLight(false);
	equipper.getSprite().RemoveSpriteLayer("crown");

	if (!equipper.isMyPlayer()) return;

	dictionary@ telepath_netids;
	if (!this.get("telepath_netids", @telepath_netids)) return;

	const string[]@ telepath_keys = telepath_netids.getKeys();
	for (int i = 0; i < telepath_keys.length; i++)
	{
		const u16 netid = parseInt(telepath_keys[i]);
		CBlob@ blob = getBlobByNetworkID(netid);
		if (blob is null) continue;

		SetTelepathed(blob, false);
	}

	telepath_netids.deleteAll();
}

void onTickEquipped(CBlob@ this, CBlob@ equipper)
{
	if (!equipper.isMyPlayer()) return;

	dictionary@ telepath_netids;
	if (!this.get("telepath_netids", @telepath_netids)) return;

	Driver@ driver = getDriver();
	Vec2f tl = driver.getWorldPosFromScreenPos(Vec2f_zero);
	Vec2f br = driver.getWorldPosFromScreenPos(driver.getScreenDimensions());

	CBlob@[] blobs;
	getMap().getBlobsInBox(tl, br, @blobs);

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!canTelepath(blob)) continue;

		if (blob is equipper) continue;

		if (telepath_netids.exists(blob.getNetworkID()+"")) continue;

		SetTelepathed(blob, true);

		telepath_netids.set(blob.getNetworkID()+"", null);
	}
}

void SetTelepathed(CBlob@ blob, const bool&in telepathed)
{
	CSprite@ sprite = blob.getSprite();
	if (sprite is null) return;

	sprite.SetHUD(telepathed);

	const int layer_count = sprite.getSpriteLayerCount();
	for (int i = 0; i < layer_count; i++)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(i);
		if (layer is null) continue;

		#ifdef STAGING
		if (layer is sprite.getLightLayer()) continue;
		#endif

		layer.SetHUD(telepathed);
	}
}

bool canTelepath(CBlob@ blob)
{
	return blob.hasTag("flesh") || blob.hasTag("undead") || blob.hasTag("skelepede");
}

void onTickSpriteEquipped(CBlob@ this, CSprite@ equipper_sprite)
{
	CSpriteLayer@ crown = equipper_sprite.getSpriteLayer("crown");
	if (crown is null)
	{
		@crown = equipper_sprite.addSpriteLayer("crown", "CrownTelepathy.png", 16, 16);
		if (crown !is null)
		{
			crown.SetVisible(true);
			crown.SetRelativeZ(1.0f);
			crown.SetFacingLeft(equipper_sprite.isFacingLeft());

			Animation@ anim = crown.addAnimation("default", 0, false);
			anim.AddFrame(1);
			crown.SetAnimation(anim);
		}
	}
	if (crown !is null)
	{
		Vec2f headoffset(equipper_sprite.getFrameWidth() / 2, -equipper_sprite.getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(equipper_sprite.getBlob(), -1, 0);

		headoffset += equipper_sprite.getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(1, -5);
		crown.SetOffset(headoffset);
	}
}
