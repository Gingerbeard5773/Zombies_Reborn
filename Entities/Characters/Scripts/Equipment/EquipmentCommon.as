//Gingerbeard @ August 9, 2024

//Equipment utilizes funcdefs to remotely activate hooks

funcdef void onEquipHandle(CBlob@, CBlob@);
funcdef void onUnequipHandle(CBlob@, CBlob@);
funcdef void onTickHandle(CBlob@, CBlob@);
funcdef void onTickSpriteHandle(CBlob@, CSprite@);
funcdef f32 onHitHandle(CBlob@, CBlob@, Vec2f, Vec2f, f32, CBlob@, u8);

//shorthand funcdef setting
void addOnEquip(CBlob@ this, onEquipHandle@ handle)                   { this.set("onEquip handle", @handle); }
void addOnUnequip(CBlob@ this, onUnequipHandle@ handle)               { this.set("onUnequip handle", @handle); }
void addOnTickEquipped(CBlob@ this, onTickHandle@ handle)             { this.set("onTickEquipped handle", @handle); }
void addOnTickSpriteEquipped(CBlob@ this, onTickSpriteHandle@ handle) { this.set("onTickSpriteEquipped handle", @handle); }
void addOnHitOwner(CBlob@ this, onHitHandle@ handle)                  { this.set("onHitOwner handle", @handle); }
