// SonantDread @ October 11th 2024
#define SERVER_ONLY
#include "Zombie_WarnsCommon.as";

// load vars from config file
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

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    string user = player.getUsername();
    removeExpiredWarns(user);
    banIfTooManyWarns(user);
}
