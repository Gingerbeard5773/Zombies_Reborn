// Magic Missile Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class MagicMissileSpell : Spell
{
	MagicMissileSpell()
	{
		name = "Magic Missiles";
		result_name = "magic_missile";
		icon_name = "$magic_missile$";
		tier = SpellTier::TierI;
		time_to_cast = 30 * 2;
		cooldown_time = 0;
		auto_cast = false;
		fragile = false;
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (isServer())
		{
			const f32 spread = 10;

			Vec2f pos = caster.getPosition() + Vec2f(0.0f, -2.0f);
			Vec2f aim = caster.getAimPos();

			Vec2f vel = (aim - pos);
			vel.Normalize();
			vel *= 2.0f;

			for (u8 i = 0; i < 5; i++)
			{
				CBlob@ result = server_CreateBlob(result_name, caster.getTeamNum(), pos);
				if (result is null) continue;

				result.IgnoreCollisionWhileOverlapped(caster);
				Vec2f newVel = vel;
				newVel.RotateBy(-spread + (spread * 0.5f) * i, Vec2f());
				result.setVelocity(newVel);

				CPlayer@ player = caster.getPlayer();
				result.SetDamageOwnerPlayer(player);

				if (player is null || player.isBot())
				{
					result.set_netid("owner_netid", caster.getNetworkID());
				}
			}
		}

		caster.getSprite().PlaySound("MagicMissile.ogg", 0.8f, 1.0f + XORRandom(3)/10.0f);
	}
}
