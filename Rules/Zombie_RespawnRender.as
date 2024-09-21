//Render time till player respawn

void onRender(CRules@ this)
{
	if (g_videorecording || this.isGameOver()) return;
	
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null) return;

	const u32 gameTime = getGameTime();
	const u32 time = this.get_u32(player.getUsername()+" respawn time") + 30;
	const s32 time_left = (time - gameTime) / getTicksASecond();
	
	string text = time_left > 100 ? "Waiting for dawn..." : getTranslatedString("Respawning in: {SEC}").replace("{SEC}", "" + time_left);
	SColor col = SColor(0xFFE0BA16);
	
	if (player.getTeamNum() == 200) //undead player
	{
		text = "Waiting to spawn as a wraith...";
		col = SColor(0xFFDB5743);
	}
	
	GUI::SetFont("menu");
	GUI::DrawTextCentered(text, Vec2f(getScreenWidth()/2, 200 + Maths::Cos(gameTime/10.0f)*8), col);
}
