//Render time till player respawn

#include "Zombie_Translation.as";

void onRender(CRules@ this)
{
	if (g_videorecording || this.isGameOver()) return;
	
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null) return;

	const u32 gameTime = getGameTime();
	const u32 time = this.get_u32("respawn time") + 30;
	const s32 time_left = (time - gameTime) / getTicksASecond();
	
	const string text = time_left > 100 ? ZombieDesc::respawn : getTranslatedString("Respawning in: {SEC}").replace("{SEC}", "" + time_left);
	
	GUI::SetFont("menu");
	GUI::DrawTextCentered(text, Vec2f(getScreenWidth()/2, 200 + Maths::Cos(gameTime/10.0f)*8), SColor(0xFFE0BA16));
}
