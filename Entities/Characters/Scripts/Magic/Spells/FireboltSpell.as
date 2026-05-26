// Firebolt Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class FireboltSpell : Spell
{
	FireboltSpell()
	{
		name = "Fire Bolt";
		result_name = "firebolt";
		icon_name = "$orb$";
		tier = SpellTier::TierI;
		time_to_cast = 15;
		cooldown_time = 0;
		auto_cast = true;
		fragile = false;
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (isServer())
		{
			Vec2f pos = getPos(caster);
			Vec2f direction = getDirection(caster);

			CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), pos);
			if (result !is null)
			{
				result.setVelocity(direction * 5.0f);
				result.SetDamageOwnerPlayer(caster.getPlayer());
			}
		}
	}

	Vec2f getDirection(CBlob@ caster)
	{
		Vec2f norm = caster.getAimPos() - caster.getPosition();
		norm.Normalize();
		return norm;
	}

	Vec2f getPos(CBlob@ caster)
	{
		return caster.getPosition() + getDirection(caster) * 14.0f;
	}
}
