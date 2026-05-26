// Orb Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class OrbSpell : Spell
{
	OrbSpell()
	{
		name = "Orb";
		result_name = "orb";
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
			Vec2f pos = caster.getPosition();
			Vec2f aim = caster.getAimPos();

			Vec2f norm = aim - pos;
			norm.Normalize();
			Vec2f vel = norm * 8.0f;

			CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), pos);
			if (result !is null)
			{
				result.setVelocity(vel);
				result.SetDamageOwnerPlayer(caster.getPlayer());
			}
		}
	}
}
