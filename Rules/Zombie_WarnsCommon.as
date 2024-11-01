// SonantDread @ October 11th 2024
#include "Zombie_GlobalMessagesCommon.as";

u8 maxWarns = 3; // max warns before ban
u16 warnDuration = 30; // days
u16 banTime = 30; // days

const string fileName = "Zombie_Warns.cfg";

void WarnPlayer(CPlayer@ admin, string playerName, u32 duration, string reason)
{
    string player = getPlayerUsername(playerName);
    string adminUsername = admin.getUsername();
    ConfigFile@ cfg = getWarnsConfig();

    // First remove any expired warns to get accurate count
    removeExpiredWarns(player);

    string[] reasons;
    string[] expiries;
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
    cfg.add_u8(player + "_warns_count", expiries.length);
    cfg.addArray_string(player + "_warns_reasons", reasons);
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
        server_SendGlobalMessage(r, "Successfully warned: " + player + "\n(" + expiries.length + "/" + maxWarns + " warns)", 2, SColor(255, 0, 255, 0).color, admin);
    }
}

void banIfTooManyWarns(string player)
{
    u8 warns = getWarnCount(player);

    // too many warns? ban them
    if (warns >= maxWarns)
    {
        u32 banDuration = (banTime == -1) ? -1 : banTime * 1440; // convert from days to minutes
        getSecurity().ban(player, banDuration, "Banned for too many warns");
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

    string[] reasons = getWarnReasons(player);
    u32[] expiries = getWarnExpiries(player);

    if (reasons.length == 0 || expiries.length == 0)
    {
        // no warnings for player
        return 0;
    }

    string[] updatedReasons;
    string[] updatedExpiries;
    u8 activeWarnings = 0;

    // check if expired
    for (u8 i = 0; i < expiries.length; i++)
    {
        if (expiries[i] == 0 || expiries[i] > currentTime)
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
    string message = "You have been warned by admin: " + admin;
    if (reason != "")
    {
        message += "\nReason: " + reason;
    }
    message += "\nYou are on warn number: " + getWarnCount(player) + "/" + maxWarns;

    return message;
}

ConfigFile@ getWarnsConfig()
{
    ConfigFile@ cfg = ConfigFile();
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

string[] getWarnReasons(string playerName)
{
    ConfigFile@ cfg = getWarnsConfig();
    string[] reasons;

    if (cfg.exists(playerName + "_warns_reasons"))
    {
        cfg.readIntoArray_string(reasons, playerName + "_warns_reasons");
    }

    return reasons;
}

u32[] getWarnExpiries(string playerName)
{
    ConfigFile@ cfg = getWarnsConfig();
    string[] expiriesStrings;
    u32[] expiries;

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
