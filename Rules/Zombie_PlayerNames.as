#define CLIENT_ONLY

Vec2f heart_size = Vec2f(12, 12); // heart icon frame size
const f32 spacing = 24.0f; //horizontal spacing between hearts
const f32 stack_spacing = 9.0f; //vertical spacing when stacking hearts
const u8 max_stacks = 3; //maximum amount of stacks before we stop rendering any extra hearts

const f32 max_radius = 64.0f; // screenspace distance
u16[] blob_ids;

void onTick(CRules@ this)
{
	if (g_videorecording) return;
	
	blob_ids.clear();
	Vec2f mouse_pos = getControls().getMouseWorldPos();

	CBlob@ localblob = getLocalPlayerBlob();
	const u8 team = localblob !is null ? localblob.getTeamNum() : this.getSpectatorTeamNum();

	for (int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		CBlob@ blob = player.getBlob();
		if (blob is null || blob is localblob || blob.hasTag("undead")) continue;
		
		if (team == this.getSpectatorTeamNum() || // always add if we are spectator
			team == blob.getTeamNum() && u_shownames || // if teammate and always show teammate names enabled
			(mouse_pos - blob.getPosition()).Length() <= max_radius) // if hovering over
			blob_ids.push_back(blob.getNetworkID());
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording) return;

	for (int i = 0; i < blob_ids.length; i++)
	{
		CBlob@ blob = getBlobByNetworkID(blob_ids[i]);
		if (blob is null) continue;

		CPlayer@ player = blob.getPlayer();
		if (player is null) continue;

		Vec2f draw_pos = blob.getInterpolatedPosition() + Vec2f(0.0f, blob.getRadius());
		draw_pos = getDriver().getScreenPosFromWorldPos(draw_pos);

		int HPs = 0;
		const f32 initialHealth = blob.getInitialHealth();
		const f32 currentHealth = blob.getHealth();
		const f32 extraHealth = Maths::Min(currentHealth - initialHealth, initialHealth * max_stacks);
		
		const f32 total_hearts_width = (initialHealth / 0.5f) * spacing;
		Vec2f heart_offset(total_hearts_width / 2.0f, 0);

		if (extraHealth < initialHealth)
		{
			for (f32 step = 0.0f; step < initialHealth; step += 0.5f)
			{
				const f32 health = currentHealth - step;
				if (health > 0)
				{
					Vec2f heart_pos = draw_pos + Vec2f(spacing * HPs, 0) - heart_offset;
					
					u8 frame = 1;
					if (health <= 0.125f)      frame = 4;
					else if (health <= 0.25f)  frame = 3;
					else if (health <= 0.375f) frame = 2;

					GUI::DrawIcon("GUI/HeartNBubble.png", frame, heart_size, heart_pos);
				}

				HPs++;
			}
		}
		
		if (extraHealth > 0)
		{
			HPs = 0;
			u16 extraLayer = 0;
			for (f32 step = 0.0f; step < extraHealth; step += 0.5f)
			{
				const f32 health = extraHealth - step;
				if (health > 0)
				{
					const u8 frameoffset = 5;
					Vec2f heart_pos = draw_pos + Vec2f(spacing * HPs, -f32(9) * extraLayer) - heart_offset;

					u8 frame = 1;
					if (health <= 0.125f)      frame = 4;
					else if (health <= 0.25f)  frame = 3;
					else if (health <= 0.375f) frame = 2;

					GUI::DrawIcon("GUI/HeartNBubble.png", frame + frameoffset, heart_size, heart_pos);
				}

				HPs++;

				if (HPs >= initialHealth * 2.0f)
				{
					HPs = 0;
					extraLayer++;
				}
			}
		}

		draw_pos.y += 32.0f;

		// now draw nickname
		const string name = player.getCharacterName();
		const string clan_tag = player.getClantag();
		const bool has_clan = clan_tag.size() > 0;

		Vec2f text_dim;
		GUI::SetFont("menu");
		GUI::GetTextDimensions(has_clan ? (clan_tag + " " + name) : name, text_dim);
		Vec2f text_dim_half = Vec2f(text_dim.x/2.0f, text_dim.y/2.0f);

		Vec2f clan_dim;
		if (has_clan)
			GUI::GetTextDimensions(clan_tag + " ", clan_dim);

		SColor text_color = SColor(255, 200, 200, 200);
		CTeam@ team = this.getTeam(blob.getTeamNum());
		if (team !is null)
			text_color = team.color;
		
		SColor clan_color = SColor(255, 128, 128, 128);

		SColor rect_color = SColor(80, 0, 0, 0);

		GUI::DrawRectangle(draw_pos - text_dim_half, draw_pos + text_dim_half + Vec2f(5.0f, 3.0f), rect_color);
		if (has_clan)
			GUI::DrawText(clan_tag, draw_pos - text_dim_half, clan_color);
		GUI::DrawText(name, draw_pos - text_dim_half + (has_clan ? Vec2f(clan_dim.x, 0) : Vec2f_zero), text_color);
	}
}
