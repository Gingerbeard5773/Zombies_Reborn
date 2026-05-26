// stun
#include "Hitters.as"
#include "SpellCommon.as"

void onTick(CBlob@ this)
{
	u8 knocked = this.get_u8("wizard_knocked");
	if (knocked == 0)
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
		return;
	}

	knocked--;
	this.set_u8("wizard_knocked", knocked);

	this.DisableKeys(key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3);
	this.DisableMouse(true);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible") || this.hasTag("dead")) return damage;

	if (damage > 1.0f)
	{
		KnockIfUsingFragileSpell(this);
	}

	return damage;
}

void KnockIfUsingFragileSpell(CBlob@ this)
{
	WizardVars@ vars;
	if (!this.get("WizardVars", @vars) || vars.spell is null) return;

	if (vars.spell.active && vars.spell.fragile)
	{
		this.set_u8("wizard_knocked", 20);
	}
}
