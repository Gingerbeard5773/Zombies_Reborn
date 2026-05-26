// Wizard logic

#include "ActivationThrowCommon.as"
#include "SpellCommon.as"

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false; //spell spritelayers must always get rendered

	this.set_f32("gib health", -3.0f);

	this.Tag("player");
	this.Tag("flesh");

	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);

	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.addCommandID("server_setspell");
	this.addCommandID("client_setspell");
	this.addCommandID("server_sync_wizardvars");
	this.addCommandID("client_sync_wizardvars");
	this.addCommandID("server_spell_command");
	this.addCommandID("client_spell_command");

	Spell@[] wizard_spells =
	{
		OrbSpell(),
		MagicMissileSpell(),
		NukeSpell(),
		IncinerateSpell(),
		EnergyBeamSpell(),
		FireballSpell(),
		FireboltSpell(),
		DisruptionWaveSpell(),
		FirebreathSpell(),
		ChainLightningSpell(),
		EnergyBeamStormSpell(),
		ZombiePortalSpell(),
		SummonJerrySpell(),
		TeleportSpell()
	};

	WizardVars vars(@wizard_spells);
	this.set("WizardVars", vars);

	if (isServer())
	{
		CBlob@ spellemit = server_CreateBlob("spellemit", this.getTeamNum(), this.getPosition()); 
		if (spellemit !is null)
		{
			this.set_netid("spellemit_netid", spellemit.getNetworkID());
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick(CBlob@ this)
{
	WizardVars@ vars;
	if (!this.get("WizardVars", @vars) || vars.spell is null) return;

	CPlayer@ player = this.getPlayer();
	const bool bot = player is null || player.isBot();
	const bool ismyplayer = this.isMyPlayer();
	const bool server_authority = isServer() && bot;
	const bool authority = server_authority || ismyplayer;
	const bool action1 = this.isKeyPressed(key_action1);

	// activate/throw
	if (ismyplayer && this.isKeyJustPressed(key_action3))
	{
		client_SendThrowOrActivateCommand(this);
	}

	// interrupt old spell if we changed spells
	if (vars.old_spell !is null && vars.old_spell !is vars.spell && vars.old_spell.active)
	{
		vars.old_spell.onInterrupted(this, vars);
	}

	if (action1 && vars.spell.canCast(this, vars))
	{
		// start the spell by our authority
		if (authority && !vars.spell.active && !this.isKeyPressed(key_inventory))
		{
			vars.spell_position = server_authority ? vars.spell.getBotStartPos(this, vars) : this.getAimPos();
			vars.spell.active = true;
			vars.Synchronize(this);
		}

		if (vars.spell.active)
		{
			if (vars.cast_time == 0)
			{
				vars.spell.onStart(this, vars);
			}

			vars.cast_time = Maths::Min(vars.cast_time + 1, vars.spell.time_to_cast);
			vars.spell.onTick(this, vars);
		}
	}

	if ((!action1 || vars.spell.auto_cast) && vars.cast_time >= vars.spell.time_to_cast)
	{
		// complete the spell if we are charged up
		vars.spell.onComplete(this, vars);
	}
	else if (!action1 && vars.spell.active)
	{
		// interrupt the spell if we stop charging mid-way
		vars.spell.onInterrupted(this, vars);
	}

	// set cursor frame
	if (ismyplayer && !getHUD().hasButtons())
	{
		int frame = 0;
		if (vars.cast_time > vars.spell.time_to_cast)
		{
			frame = 11 + vars.cast_time % 15 / 5;
		}
		else if (vars.cast_time > 0)
		{
			frame = vars.cast_time * 11 / vars.spell.time_to_cast; 
		}
		getHUD().SetCursorFrame(frame);
	}

	if (this.hasTag("dead"))
	{
		onDie(this);
		this.getCurrentScript().tickFrequency = 0;
	}
}

void onDie(CBlob@ this)
{
	CBlob@ spellemit = getBlobByNetworkID(this.get_netid("spellemit_netid"));
	if (spellemit !is null)
	{
		spellemit.server_Die();
	}

	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return;

	if (vars.spell !is null && vars.spell.active)
	{
		vars.spell.onInterrupted(this, vars);
	}
}

/// SPELL MENU

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return;

	this.ClearGridMenusExceptInventory();

	Vec2f tl = gridmenu.getUpperLeftPosition();
	Vec2f lr = gridmenu.getLowerRightPosition();
	Vec2f pos(tl.x + 0.5f * (lr.x - tl.x), tl.y - 32 * 1 - 2 * 24);

	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(vars.spells.length, 1), "Current Spell");
	if (menu is null) return;

	menu.deleteAfterClick = false;

	for (int i = 0; i < vars.spells.length; i++)
	{
		Spell@ spell = vars.spells[i];
		CBitStream params;
		params.write_u8(i);

		CGridButton@ button = menu.AddButton(spell.icon_name, spell.name, "WizardLogic.as", "Callback_PickSpell", params);
		if (button is null) continue;

		button.SetEnabled(true);
		button.selectOneOnClick = true;

		if (vars.spell_index == i)
		{
			button.SetSelected(1);
		}
	}
}

void Callback_PickSpell(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	CBlob@ this = player.getBlob();
	if (this is null) return;

	u8 index;
	if (!params.saferead_u8(index)) return;

	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return;

	vars.SetSpell(index);

	if (!isServer())
	{
		CBitStream stream;
		stream.write_u8(index);
		this.SendCommand(this.getCommandID("server_setspell"), stream);
	}
}


/// NETWORK

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return;

	if (cmd == this.getCommandID("server_setspell") && isServer())
	{
		u8 index;
		if (!params.saferead_u8(index)) { error("Failed to read index [0] [WizardLogic]"); return; }

		vars.SetSpell(index);

		CBitStream stream;
		stream.write_u8(index);
		this.SendCommand(this.getCommandID("client_setspell"), stream);
	}
	else if (cmd == this.getCommandID("client_setspell") && isClient())
	{
		u8 index;
		if (!params.saferead_u8(index)) { error("Failed to read index [1] [WizardLogic]"); return; }

		vars.SetSpell(index);
	}
	else if (cmd == this.getCommandID("server_sync_wizardvars") && isServer())
	{
		vars.Unserialize(params);
		vars.Synchronize(this);
	}
	else if (cmd == this.getCommandID("client_sync_wizardvars") && isClient())
	{
		if (this.isMyPlayer()) return;

		vars.Unserialize(params);
	}
	else if (cmd == this.getCommandID("server_spell_command") && isServer())
	{
		SpellCommand(this, cmd, params);
	}
	else if (cmd == this.getCommandID("client_spell_command") && isClient())
	{
		SpellCommand(this, cmd, params);
	}
}

void SpellCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	u8 index;
	if (!params.saferead_u8(index)) { error("Failed to read index [2] [WizardLogic]"); return; }

	CBitStream stream;
	if (!params.saferead_CBitStream(stream)) { error("Failed to load CBitStream [WizardLogic]"); return; }

	stream.ResetBitIndex();

	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return;

	if (index >= vars.spells.length) { error("Failed to send spell cmd - index out of bounds [WizardLogic]"); return; }

	vars.spells[index].onCommand(this, vars, cmd, stream);
} 

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return;

	vars.Serialize(stream);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	WizardVars@ vars;
	if (!this.get("WizardVars", @vars)) return true;

	vars.Unserialize(stream);

	if (vars.spell !is null && vars.spell.active)
	{
		vars.spell.onStart(this, vars);
	}

	return true;
}
