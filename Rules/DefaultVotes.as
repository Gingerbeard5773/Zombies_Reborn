//Zombie Fortress Voting

//Only kicking is allowed. Kicked players are sent into zombie team.

#include "VoteCommon.as"
#include "Zombie_SoftBansCommon.as"

const float required_minutes = 10; //time you have to wait after joining w/o skip_votewait.
const float required_minutes_nextmap = 10; //global nextmap vote cooldown

const s32 VoteKickTime = 30; //minutes (30min default)

//kicking related globals and enums
enum kick_reason
{
	kick_reason_griefer = 0,
	kick_reason_hacker,
	kick_reason_teamkiller,
	kick_reason_spammer,
	kick_reason_non_participation,
	kick_reason_count,
};

string[] kick_reason_string = { "Griefer", "Hacker", "Teamkiller", "Chat Spam", "Non-Participation" };

u8 g_kick_reason_id = kick_reason_griefer; // default

//votekick and vote nextmap

const string votekick_id = "vote: kick";
const string votekick_id_client = "vote: kick client";

//set up the ids
void onInit(CRules@ this)
{
	this.addCommandID(votekick_id);
	this.addCommandID(votekick_id_client);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	const string username = player.getUsername();
	this.set_s32("last vote counter player " + username, 0);
	this.SyncToPlayer("last vote counter player " + username, player);
}

void onTick(CRules@ this)
{
	// server-side counter for every player since we don't trust the client
	if (!isServer()) return;

	// update every 10 seconds only? probably not necessary but whatever
	if (getGameTime() % (10 * getTicksASecond()) != 0) return;

	for (int i = 0; i < getPlayerCount(); ++i)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		const string username = player.getUsername();
		if (this.get_s32("last vote counter player " + username) < 60 * getTicksASecond()*required_minutes)
		{
			this.add_s32("last vote counter player " + username, (10 * getTicksASecond()));
			this.SyncToPlayer("last vote counter player " + username, player);
		}
	}
}

//VOTE KICK --------------------------------------------------------------------
//votekick functors

class VoteKickFunctor : VoteFunctor
{
	VoteKickFunctor() {} //dont use this
	VoteKickFunctor(CPlayer@ _kickplayer)
	{
		@kickplayer = _kickplayer;
	}

	CPlayer@ kickplayer;

	void Pass(bool outcome)
	{
		if (kickplayer !is null && outcome)
		{
			client_AddToChat(getTranslatedString("Votekick passed! {USER} will be kicked out.").replace("{USER}", kickplayer.getUsername()), vote_message_colour());
			print("Set player to undead by vote kick : "+kickplayer.getUsername());

			if (isServer())
			{
				//do soft ban
				SoftBan(kickplayer.getUsername(), "vote kicked", VoteKickTime*60);
				SetUndead(getRules(), kickplayer);

				//getSecurity().ban(kickplayer, VoteKickTime, "Voted off"); //30 minutes ban
			}
		}
	}
};

class VoteKickCheckFunctor : VoteCheckFunctor
{
	VoteKickCheckFunctor() {}//dont use this
	VoteKickCheckFunctor(CPlayer@ _kickplayer, u8 _reasonid)
	{
		@kickplayer = _kickplayer;
		reasonid = _reasonid;
	}

	CPlayer@ kickplayer;
	u8 reasonid;

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		if (!getSecurity().checkAccess_Feature(player, "mark_player")) return false;
		
		if (player.getTeamNum() == 3) return false; //softbanned players can't vote.

		return true;
	}
};

class VoteKickLeaveFunctor : VotePlayerLeaveFunctor
{
	VoteKickLeaveFunctor() {} //dont use this
	VoteKickLeaveFunctor(CPlayer@ _kickplayer)
	{
		@kickplayer = _kickplayer;
	}

	CPlayer@ kickplayer;

	//avoid dangling reference to player
	void PlayerLeft(VoteObject@ vote, CPlayer@ player)
	{
		if (player is kickplayer)
		{
			client_AddToChat(getTranslatedString("{USER} left early, acting as if they were kicked.").replace("{USER}", player.getUsername()), vote_message_colour());
			if (isServer())
			{
				getSecurity().ban(player, VoteKickTime, "Ran from vote");
			}

			CancelVote(vote);
		}
	}
};

//setting up a votekick object
VoteObject@ Create_Votekick(CPlayer@ player, CPlayer@ byplayer, u8 reasonid)
{
	VoteObject vote;

	@vote.onvotepassed = VoteKickFunctor(player);
	@vote.canvote = VoteKickCheckFunctor(player, reasonid);
	@vote.playerleave = VoteKickLeaveFunctor(player);

	vote.title = "Kick {USER}?";
	vote.reason = kick_reason_string[reasonid];
	vote.byuser = byplayer.getUsername();
	vote.user_to_kick = player.getUsername();
	vote.forcePassFeature = "ban";
	vote.cancel_on_restart = false;

	CalculateVoteThresholds(vote);

	return vote;
}

//create menus for kick and nextmap

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	//get our player first - if there isn't one, move on
	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	if (Rules_AlreadyHasVote(this))
	{
		Menu::addContextItem(menu, getTranslatedString("(Vote already in progress)"), "DefaultVotes.as", "void CloseMenu()");
		Menu::addSeparator(menu);
		return;
	}

	//and advance context menu when clicked
	CContextMenu@ votemenu = Menu::addContextMenu(menu, getTranslatedString("Start a Vote"));
	Menu::addSeparator(menu);

	//vote options menu

	CContextMenu@ kickmenu = Menu::addContextMenu(votemenu, getTranslatedString("Kick"));
	Menu::addSeparator(votemenu); //before the back button

	bool can_skip_wait = getSecurity().checkAccess_Feature(me, "skip_votewait");
	bool duplicatePlayer = isDuplicatePlayer(me);

	//kick menu
	if (getSecurity().checkAccess_Feature(me, "mark_player"))
	{
		if (duplicatePlayer)
		{
			Menu::addInfoBox(kickmenu, getTranslatedString("Can't Start Vote"),
				getTranslatedString("Voting to kick a player\nis not allowed when playing\nwith a duplicate instance of KAG.\n\nTry rejoining the server\nif this was unintentional."));
		}
		else if (this.get_s32("last vote counter player " + me.getUsername()) < 60 * getTicksASecond()*required_minutes // synced from server
				&& !can_skip_wait)
		{
			Menu::addInfoBox(kickmenu, getTranslatedString("Can't Start Vote"),
				getTranslatedString("Voting requires a {REQUIRED_MIN} min wait\nafter each started vote to\nprevent spamming/abuse.\n").replace("{REQUIRED_MIN}", "" + required_minutes));
		}
		else
		{
			string votekick_info = getTranslatedString(
				"Vote to kick a player on your team\nout of the game.\n\n" +
				"- use responsibly\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select a reason from the\n     list (default is griefing).\n" +
				"- select a name from the list.\n" +
				"- everyone votes.\n"
			);
			Menu::addInfoBox(kickmenu, getTranslatedString("Vote Kick"), votekick_info);

			Menu::addSeparator(kickmenu);

			//reasons
			for (uint i = 0 ; i < kick_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				Menu::addContextItemWithParams(kickmenu, getTranslatedString(kick_reason_string[i]), "DefaultVotes.as", "Callback_KickReason", params);
			}

			Menu::addSeparator(kickmenu);

			//write all players on our team
			bool added = false;
			for (int i = 0; i < getPlayerCount(); ++i)
			{
				CPlayer@ player = getPlayer(i);
				if (player is null) continue;

				const int player_team = player.getTeamNum();
				if (player_team != me.getTeamNum() && !getSecurity().checkAccess_Feature(me, "mark_any_team")) continue;

				if (getSecurity().checkAccess_Feature(player, "kick_immunity")) continue;

				string descriptor = player.getCharacterName();

				if (player.getUsername() != player.getCharacterName())
					descriptor += " (" + player.getUsername() + ")";

				if (this.get_string("last username voted " + me.getUsername()) == player.getUsername()) // synced from server
				{
					string title = getTranslatedString("Cannot kick {USER}").replace("{USER}", descriptor);
					string info = getTranslatedString("You started a vote for\nthis person last time.\n\nSomeone else must start the vote.");
					//no-abuse box
					Menu::addInfoBox(kickmenu, title, info);
				}
				else
				{
					string kick = getTranslatedString("Kick {USER}").replace("{USER}", descriptor);
					string kicking = getTranslatedString("Kicking {USER}").replace("{USER}", descriptor);
					string info = getTranslatedString("Make sure you're voting to kick\nthe person you meant.\n");

					CContextMenu@ usermenu = Menu::addContextMenu(kickmenu, kick);
					Menu::addInfoBox(usermenu, kicking, info);
					Menu::addSeparator(usermenu);

					CBitStream params;
					params.write_u16(player.getNetworkID());

					Menu::addContextItemWithParams(usermenu, getTranslatedString("Yes, I'm sure"), "DefaultVotes.as", "Callback_Kick", params);
					added = true;

					Menu::addSeparator(usermenu);
				}
			}

			if (!added)
			{
				Menu::addContextItem(kickmenu, getTranslatedString("(No-one available)"), "DefaultVotes.as", "void CloseMenu()");
			}
		}
	}
	else
	{
		Menu::addInfoBox(kickmenu, getTranslatedString("Can't vote"),
			getTranslatedString("You are not allowed to votekick\nplayers on this server\n"));
	}
	Menu::addSeparator(kickmenu);
}

void CloseMenu()
{
	Menu::CloseAllMenus();
}

void Callback_KickReason(CBitStream@ params)
{
	u8 id;
	if (!params.saferead_u8(id)) return;

	if (id < kick_reason_count)
	{
		g_kick_reason_id = id;
	}
}

void Callback_Kick(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	u16 id;
	if (!params.saferead_u16(id)) return;

	CPlayer@ other_player = getPlayerByNetworkId(id);
	if (other_player is null) return;

	if (getSecurity().checkAccess_Feature(other_player, "kick_immunity"))
		return;

	CBitStream params2;
	params2.write_u16(other_player.getNetworkID());
	params2.write_u8(g_kick_reason_id);

	getRules().SendCommand(getRules().getCommandID(votekick_id), params2);
}

bool server_canPlayerStartVote(CRules@ this, CPlayer@ player, CPlayer@ other_player)
{
	// other player has kick immunity?
	if (getSecurity().checkAccess_Feature(other_player, "kick_immunity"))
	{
		return false;
	}

	// already tried to votekick other player before this?
	if (this.get_string("last username voted " + player.getUsername()) == other_player.getUsername())
	{
		return false;
	}

	if (!getSecurity().checkAccess_Feature(player, "skip_votewait"))
	{
		// didnt wait required_minutes yet?
		if (this.get_s32("last vote counter player " + player.getUsername()) < 60 * getTicksASecond()*required_minutes)
		{
			return false;
		}
	}

	return true;
}

//actually setting up the votes
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (Rules_AlreadyHasVote(this)) return;

	if (cmd == this.getCommandID(votekick_id) && isServer())
	{
		u16 playerid;
		if (!params.saferead_u16(playerid)) return;

		u8 reasonid;
		if (!params.saferead_u8(reasonid)) return;

		if (reasonid >= kick_reason_count) return;

		CPlayer@ byplayer = getNet().getActiveCommandPlayer();
		if (byplayer is null) return;

		CPlayer@ player = getPlayerByNetworkId(playerid);
		if (player is null) return;

		if (!server_canPlayerStartVote(this, byplayer, player)) return;

		this.set_s32("last vote counter player " + byplayer.getUsername(), 0);
		this.SyncToPlayer("last vote counter player " + byplayer.getUsername(), byplayer);

		this.set_string("last username voted " + byplayer.getUsername(), player.getUsername());
		this.SyncToPlayer("last username voted " + byplayer.getUsername(), byplayer);

		Rules_SetVote(this, Create_Votekick(player, byplayer, reasonid));

		CBitStream bt;
		bt.write_u16(playerid);
		bt.write_u8(reasonid);
		bt.write_u16(byplayer.getNetworkID());

		this.SendCommand(this.getCommandID(votekick_id_client), bt);
	}
	else if (cmd == this.getCommandID(votekick_id_client) && isClient())
	{
		u16 playerid;
		if (!params.saferead_u16(playerid)) return;

		u8 reasonid;
		if (!params.saferead_u8(reasonid)) return;

		if (reasonid >= kick_reason_count) return;

		u16 byplayerid;
		if (!params.saferead_u16(byplayerid)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);
		if (byplayer is null) return;

		CPlayer@ player = getPlayerByNetworkId(playerid);
		if (player is null) return;

		Rules_SetVote(this, Create_Votekick(player, byplayer, reasonid));
	}
}
