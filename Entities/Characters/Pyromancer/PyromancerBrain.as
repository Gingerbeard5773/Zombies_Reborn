#define SERVER_ONLY

#include "SpellCommon.as"

//TODO

/*
	Complete sprite / head

	assess if cmd is necessary for onComplete

	Effects for any remaining spells

	"hell portal" calamity spell

	Sound effects (Laughing n shit)
*/

const int movement_delay = 30 * 3;
const int target_delay = 45;

const f32 teleport_distance = 240.0f;

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	CPlayer@ player = blob.getPlayer();
	if (player is null || player.isBot())
	{
		this.server_SetActive(true);
	}

	blob.set_Vec2f("brain_destination", blob.getPosition());
	blob.set_u16("brain_movement_delay", movement_delay);
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;

	WizardVars@ vars;
	if (!blob.get("WizardVars", @vars)) return;

	blob.setKeyPressed(key_action1, false);
	
	if (blob.isInInventory()) return;

	if (vars.spell is null) return;

	CBlob@ target = this.getTarget();
	if (target !is null)
	{
		Vec2f pos = blob.getPosition();
		Vec2f target_pos = target.getPosition();

		const bool introduction = blob.get_u8("introduction_time") < 15;
		const bool phasing = blob.getShape().isStatic();

		u16 delay = blob.get_u16("brain_movement_delay");

		if (!phasing)
		{
			delay = Maths::Max(delay - 1, 0);
		}

		if (introduction)
		{
			blob.setAimPos(target_pos);
		}

		// Handle spell casting
		const bool has_time_to_cast = vars.spell.time_to_cast - vars.cast_time < delay;
		const bool incomplete_spell = vars.cast_time < vars.spell.time_to_cast;
		if (vars.spell.canCast(blob, vars) && incomplete_spell && has_time_to_cast && !introduction)
		{
			vars.spell.setBotAimPos(blob, vars, target_pos);

			if (!phasing)
			{
				blob.setKeyPressed(key_action1, true);
			}
		}

		// Handle movement
		if (delay == 0)
		{
			Vec2f old_destination = blob.get_Vec2f("brain_destination");
			Vec2f destination = old_destination;

			// Handle introduction movement
			if (introduction)
			{
				// Move away if we are too close to our target
				const f32 target_distance = (pos - target_pos).Length();
				if (target_distance < 80.0f)
				{
					Navigator navigator(target_pos);
					navigator.cost_evaluators = { @getProximityCost, @getRandomCost };
					navigator.valid_evaluators = { @isInMap, @isOpenSpace, @isUnobstructedByBlobs };
					destination = navigator.getBestPositionFromOrigin(160.0f);
				}
				
				delay = movement_delay;
			}
			// Handle spell movement
			else
			{
				SetRandomSpell(blob, vars);

				vars.spell.setBotStartPos(blob, vars, target_pos);

				destination = vars.spell.getBotMovePos(blob, vars, target_pos);

				delay = vars.spell.getBotMoveDelay(blob, vars);
			}

			if (destination != old_destination)
			{
				blob.set_Vec2f("brain_destination", destination);
				blob.Sync("brain_destination", true);

				const f32 distance = (pos - destination).Length();
				if (distance > teleport_distance)
				{
					// Teleport if destination is far
					blob.setPosition(destination);

					CBitStream stream;
					stream.write_Vec2f(pos);
					stream.write_Vec2f(destination);
					blob.SendCommand(blob.getCommandID("client_teleport"), stream);
				}
				else
				{
					// Otherwise begin phasing
					blob.getShape().SetStatic(true);
				}
			}
		}

		blob.set_u16("brain_movement_delay", delay);
	}

	if ((getGameTime() + blob.getNetworkID() * 33) % target_delay == 0)
	{
		SetBestTarget(this, blob);
	}
}

void SetBestTarget(CBrain@ this, CBlob@ blob)
{
	u16[]@ blobs;
	if (!getRules().get("target netids", @blobs)) return;

	const Vec2f pos = blob.getPosition();

	CBlob@ best_target;
	f32 closest_distance = 999999.9f;

	for (int i = 0; i < blobs.length; ++i)
	{
		CBlob@ candidate = getBlobByNetworkID(blobs[i]);
		if (candidate is null || candidate.hasTag("dead")) continue;

		if (candidate.hasTag("sleeper")) continue;

		Vec2f candidate_pos = candidate.getPosition();
		f32 distance = (candidate_pos - pos).Length();

		// Npcs are lower priority
		if (candidate.hasTag("migrant")) distance *= 2.5f;

		// Non visible candidates are lower priority
		if (getMap().rayCastSolid(pos, candidate_pos)) distance *= 2.0f;

		if (distance < closest_distance)
		{
			@best_target = candidate;
			closest_distance = distance;
		}
	}

	this.SetTarget(best_target);
}

void SetRandomSpell(CBlob@ blob, WizardVars@ vars)
{
	u8 index = 0;
	for (int i = 0; i < 10; ++i)
	{
		const u8 potential = XORRandom(vars.spells.length);
		if (vars.spells[potential].canCast(blob, vars))
		{
			index = potential;
			break;
		}
	}

	vars.SetSpell(index);

	if (!isClient())
	{
		CBitStream stream;
		stream.write_u8(index);
		blob.SendCommand(blob.getCommandID("client_setspell"), stream);
	}
}
