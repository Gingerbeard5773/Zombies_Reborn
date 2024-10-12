// SonantDread @ October 11th 2024
#define SERVER_ONLY
#include "Zombie_WarnsCommon.as";

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    string user = player.getUsername();
    removeExpiredWarns(user);
    banIfTooManyWarns(user);
}
