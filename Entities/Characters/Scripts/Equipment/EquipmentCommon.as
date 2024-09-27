//Gingerbeard @ August 9, 2024

//Equipment utilizes funcdefs to remotely activate hooks

funcdef void onEquipHandle(CBlob@, CBlob@);
funcdef void onUnequipHandle(CBlob@, CBlob@);
funcdef void onTickHandle(CBlob@, CBlob@);
funcdef void onTickSpriteHandle(CBlob@, CSprite@);
funcdef f32 onHitHandle(CBlob@, CBlob@, Vec2f, Vec2f, f32, CBlob@, u8);
funcdef void onClientJoinHandle(CBlob@, CBlob@);

//shorthand funcdef setting
void addOnEquip(CBlob@ this, onEquipHandle@ handle)                   { this.set("onEquip handle", @handle); }
void addOnUnequip(CBlob@ this, onUnequipHandle@ handle)               { this.set("onUnequip handle", @handle); }
void addOnTickEquipped(CBlob@ this, onTickHandle@ handle)             { this.set("onTickEquipped handle", @handle); }
void addOnTickSpriteEquipped(CBlob@ this, onTickSpriteHandle@ handle) { this.set("onTickSpriteEquipped handle", @handle); }
void addOnHitOwner(CBlob@ this, onHitHandle@ handle)                  { this.set("onHitOwner handle", @handle); }
void addOnClientJoin(CBlob@ this, onClientJoinHandle@ handle)                { this.set("onClientJoin handle", @handle); }

void LoadNewHead(CBlob@ this, const u8&in new_head)
{
	const u8 old_head = this.exists("override head") ? this.get_u8("override head") : 0;
	if (old_head > 0)
	{
		this.set_u8("old override head", old_head);
	}

	this.set_u8("override head", new_head);
	this.getSprite().RemoveSpriteLayer("head");
}

void LoadOldHead(CBlob@ this)
{
	const u8 head = this.exists("old override head") ? this.get_u8("old override head") : 0;
	this.set_u8("override head", head);
	this.getSprite().RemoveSpriteLayer("head");
}
