//Author: QuantalJ
//Radio Station Code

int channel_select = 0;
int max_channel = 3;
const string[] song_names = {
    "a",
    "b",
    "c"
};

void onInit(CBlob@ this)
{
    this.addCommandID("turn off");
    this.addCommandID("turn on");
    this.addCommandID("next channel");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("next channel"))
	{
        this.getSprite().RewindEmitSound();
        this.getSprite().SetEmitSoundPaused(true);
        if(channel_select >= max_channel)
        {
            channel_select = 0;
        }
        this.getSprite().SetEmitSoundVolume(1.0f);
        this.getSprite().SetEmitSoundPlayPosition(1);
		this.getSprite().SetEmitSound("" + song_names[channel_select] + ".ogg");
        this.getSprite().SetEmitSoundPaused(false);
        channel_select++;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.hasTag("dead"))
		return;
	
	caller.CreateGenericButton("$" + this.getName() + "$", Vec2f_zero, this, this.getCommandID("next channel"), "Change Channel");
}
