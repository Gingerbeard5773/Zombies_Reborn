//Render time till player respawn

#include "Zombie_Translation.as";

void onRender(CRules@ this)
{
	if (g_videorecording || this.isGameOver()) return;
	
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	if (player.getTeamNum() == this.getSpectatorTeamNum()) return;

	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null) return;

	const u32 gameTime = getGameTime();
	const u32 time = this.get_u32("client respawn time") + 30;
	const s32 time_left = (time - gameTime) / getTicksASecond();
	
	string text = time_left > 100 ? Translate::Respawn0 : getTranslatedString("Respawning in: {SEC}").replace("{SEC}", "" + time_left);
	SColor col = SColor(0xFFE0BA16);
	
	if (player.getTeamNum() == 3) //undead player
	{
		text = Translate::Respawn1;
		col = SColor(0xFFDB5743);
	}
	
	GUI::SetFont("menu");
	Vec2f drawpos(getScreenWidth()*0.5f, getScreenHeight()*0.22f + 50.0f);
	drawpos.y += Maths::Cos(gameTime/10.0f)*8.0f;
	GUI::DrawTextCentered(text, drawpos, col);
}
