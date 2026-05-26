// Fireball Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class FireballSpell : Spell
{
	FireballSpell()
	{
		name = "Fire Ball";
		result_name = "fireball";
		icon_name = "$orb$";
		tier = SpellTier::TierII;
		time_to_cast = 30;
		cooldown_time = 0;
		auto_cast = false;
		fragile = false;
	}

	void onTick(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onTick(caster, vars);

		vars.spell_position = getPos(caster);
		ParticleMagic(vars.spell_position, "MissileFire1.png");
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
				result.setVelocity(direction * 8.0f);

				CPlayer@ player = caster.getPlayer();
				result.SetDamageOwnerPlayer(player);

				if (player is null || player.isBot())
				{
					result.set_netid("owner_netid", caster.getNetworkID());
				}
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
		return caster.getPosition() + getDirection(caster) * 16.0f;
	}


	/// BOTS

	void setBotAimPos(CBlob@ caster, WizardVars@ vars, Vec2f pos)
	{
		// Aim pos is lerped so this spell can be dodged by players easier
		Vec2f aim_pos = Vec2f_lerp(caster.getAimPos(), pos, 0.15f);
		caster.setAimPos(aim_pos);
	}
}
