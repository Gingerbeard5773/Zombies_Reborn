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
void addOnClientJoin(CBlob@ this, onClientJoinHandle@ handle)         { this.set("onClientJoin handle", @handle); }

void LoadNewHead(CBlob@ this, const u8&in new_head)
{
	const u8 old_head = this.exists("override head") ? this.get_u8("override head") : 0;
	if (old_head > 0 && old_head != new_head)
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

void EquipBlob(CBlob@ this, CBlob@ equippedblob)
{
	equippedblob.server_DetachFromAll();
	equippedblob.setPosition(Vec2f(0,0));
	equippedblob.setVelocity(Vec2f(0,0));
	equippedblob.setAngularVelocity(0.0f);
	equippedblob.SetVisible(false);

	SetBlobActive(equippedblob, false);

	onEquipHandle@ onEquip;
	if (equippedblob.get("onEquip handle", @onEquip)) 
		onEquip(equippedblob, this);
}

void UnequipBlob(CBlob@ this, CBlob@ equippedblob, const bool&in put_in_inventory = true)
{
	equippedblob.SetVisible(true);
	equippedblob.setPosition(this.getPosition());
	if (put_in_inventory)
		this.server_PutInInventory(equippedblob);

	SetBlobActive(equippedblob, true);

	onUnequipHandle@ onUnequip;
	if (equippedblob.get("onUnequip handle", @onUnequip)) 
		onUnequip(equippedblob, this);
}

void SetBlobActive(CBlob@ equippedblob, const bool&in active)
{
	CShape@ shape = equippedblob.getShape();
	shape.server_SetActive(active);
	shape.doTickScripts = active;
	shape.SetGravityScale(active ? 1.0f : 0.0f);
	ShapeConsts@ consts = shape.getConsts();
	consts.collidable = active;
	consts.mapCollisions = active;
}
