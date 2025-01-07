const string[] tips = {
    "Join our Discord [Link in TAB]",
    "Lagging? Use the staging instructions in TAB",
    "The mod has translations into Russian and English",
    "Found a griefer, cheater or spammer? Write to the administration in our Discord"
};

void onTick(CRules@ this)
{
    if(getGameTime() % 9000 == 0)
    {
        client_AddToChat("Tip:" + tips[XORRandom(tips.length)], SColor(255, 145, 145, 225));
    }
}