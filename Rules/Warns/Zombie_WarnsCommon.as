// SonantDread @ October 11th 2024
#define SERVER_ONLY
#include "Zombie_GlobalMessagesCommon.as";

u8 maxWarns = 3; // max warns before ban
u16 warnDuration = 30; // days
u16 banTime = 30; // days

const string fileName = "Zombie_Warns.cfg";

void onInit(CRules@ this)
{
    ConfigFile cfg = ConfigFile();
    if (cfg.loadFile(fileName))
    {
        maxWarns = cfg.exists("max_warns") ? cfg.read_u8("max_warns") : 3;
        warnDuration = cfg.exists("warn_duration") ? cfg.read_u16("warn_duration") : 30;
        banTime = cfg.exists("ban_time") ? cfg.read_u16("ban_time") : 30;
    }
}

void WarnPlayer(CPlayer@ admin, string playerName, u32 duration, string reason)
{
    string player = getPlayerUsername(playerName);
    string adminUsername = admin.getUsername();
    ConfigFile@ cfg = getWarnsConfig();

    // ignore if player is admin or the person who is warning
    CPlayer@ playerObject = getPlayerByUsername(player);
    if (adminUsername == player || (playerObject !is null && !playerObject.isMod())) return;

    array<string> reasons;
    array<string> expiries;
    if (cfg.exists(player + "_warns_reasons"))
    {
        cfg.readIntoArray_string(reasons, player + "_warns_reasons");
    }

    if (cfg.exists(player + "_warns_expiries"))
    {
        cfg.readIntoArray_string(expiries, player + "_warns_expiries");
    }

    // add new warning
    reasons.push_back(reason);
    expiries.push_back(duration == 0 ? "0" : "" + (Time() + duration * 86400));

    // save updated warnings
    cfg.add_u8(player + "_warns_count", reasons.length);
    cfg.addArray_string(player + "_warns_reasons", reasons);
    // hack, u32 was crashing my game
    cfg.addArray_string(player + "_warns_expiries", expiries);
    cfg.saveFile(fileName);

    banIfTooManyWarns(player);

    CRules@ r = getRules();
    // display text for the banned player
    CPlayer@ warnedPlayer = getPlayerByUsername(playerName);
    if (warnedPlayer !is null)
    {
        server_SendGlobalMessage(r, getWarnMessage(adminUsername, player, reason), 5, SColor(255, 255, 0, 0).color, warnedPlayer);
    }
    
    // display to the admin the warn was successful
    if (admin !is null)
    {
        server_SendGlobalMessage(r, "Sucessfully warned: " + player, 2, SColor(255, 0, 255, 0).color, admin);
    }
    // TODO: check if command works with less than 3 params
}

void banIfTooManyWarns(string player)
{
    u8 warns = getWarnCount(player);

    // too many warns? ban them
    if (warns >= maxWarns)
    {
        u32 banDuration = (banTime == -1) ? -1 : banTime * 1440; // convert from days to minutes
        getSecurity().ban(player, banDuration, "Banned for too many warns.");
        kickExtraClients(player);
    }
}

void kickExtraClients(string player)
{
    for(int i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        if (p is null) continue;

        // if client names before '~' are equal to player
        if(getPlayerUsername(p.getUsername()) == player)
        {
            KickPlayer(p);
        }
    }
}

u8 removeExpiredWarns(string player)
{
    ConfigFile@ cfg = getWarnsConfig();
    u32 currentTime = Time();

    array<string> reasons = getWarnReasons(player);
    array<u32> expiries = getWarnExpiries(player);

    if (reasons.length == 0 || expiries.length == 0)
    {
        // no warnings for player
        return 0;
    }

    array<string> updatedReasons;
    array<string> updatedExpiries;
    u8 activeWarnings = 0;

    // check if expired
    for (u8 i = 0; i < expiries.length; i++)
    {
        if (expiries[i] > currentTime)
        {
            updatedReasons.push_back(reasons[i]);
            updatedExpiries.push_back("" + expiries[i]);
            activeWarnings++;
        }
    }

    // update the config file if any warnings were removed
    if (activeWarnings < expiries.length)
    {
        cfg.add_u8(player + "_warns_count", activeWarnings);
        cfg.addArray_string(player + "_warns_reasons", updatedReasons);
        cfg.addArray_string(player + "_warns_expiries", updatedExpiries);
        cfg.saveFile(fileName);
    }

    return activeWarnings;
}

string getWarnMessage(string admin, string player, string reason)
{
    return "You have been warned by admin: " + admin + "\nReason: " + reason + "\nYou are on warn number: " + getWarnCount(player);
}

ConfigFile@ getWarnsConfig()
{
    ConfigFile cfg = ConfigFile();
    if (!cfg.loadFile("../Cache/" + fileName))
    {
        warn("Creating warns config: ../Cache/" + fileName);
        cfg.saveFile(fileName);
    }

    return cfg;
}

u16 getWarnCount(string playerName)
{
    ConfigFile@ cfg = getWarnsConfig();
    if (cfg.exists(playerName + "_warns_count"))
    {
        return cfg.read_u8(playerName + "_warns_count");
    }

    return 0;
}

array<string> getWarnReasons(string playerName)
{
    ConfigFile@ cfg = getWarnsConfig();
    array<string> reasons;

    if (cfg.exists(playerName + "_warns_reasons"))
    {
        cfg.readIntoArray_string(reasons, playerName + "_warns_reasons");
    }

    return reasons;
}

array<u32> getWarnExpiries(string playerName)
{
    ConfigFile@ cfg = getWarnsConfig();
    array<string> expiriesStrings;
    array<u32> expiries;

    if (cfg.exists(playerName + "_warns_expiries"))
    {
        cfg.readIntoArray_string(expiriesStrings, playerName + "_warns_expiries");
        for (uint i = 0; i < expiriesStrings.length; i++)
        {
            expiries.push_back(parseInt(expiriesStrings[i]));
        }
    }

    return expiries;
}

string getPlayerUsername(string player)
{
	string[]@ tokens = player.split("~");
	if (tokens.length <= 0) return "";
	return tokens[0];
}