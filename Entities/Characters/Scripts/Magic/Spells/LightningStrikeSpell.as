// Lightning Strike Spell

#include "MagicCircleCommon.as"
#include "ParticleMagic.as"

class LightningStrikeSpell : Spell
{
	LightningStrikeSpell()
	{
		name = "Lightning Strike";
		result_name = "lightning";
		icon_name = "$lightning$";
		time_to_cast = 30 * 4;
		auto_cast = false;

		raycast = false;
	}

	void onComplete(CBlob@ caster, WizardVars@ vars)
	{
		Spell::onComplete(caster, vars);

		if (isServer())
		{
			Vec2f aim = caster.getAimPos();
			vars.spell_position = Vec2f(aim.x, 4.0f);

			CBlob@ result = server_CreateBlobNoInit(result_name);
			if (result !is null)
			{
				result.server_setTeamNum(caster.getTeamNum());
				result.setPosition(vars.spell_position);
				result.SetDamageOwnerPlayer(caster.getPlayer());

				result.set_Vec2f("aim_pos", aim);
				result.Init();
			}
		}
	}
}
