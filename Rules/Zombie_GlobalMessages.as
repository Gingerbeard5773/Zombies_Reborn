// Zombie Global Messages

// Show a client side global message
// Allows for better string and rendering manipulation

#define CLIENT_ONLY;

#include "Zombie_Translation.as";

string global_message = "";

const string[] messages =
{
	Translate::Day,
	Translate::GameOver,
	Translate::GameWin,
	Translate::Trader,
	Translate::Sedgwick,
	Translate::Migrant1,
	Translate::Migrant2
};

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	this.set_u8("global_message_index", 0);
	this.set_u8("global_message_timer", 0);
	global_message = "";
}

void onTick(CRules@ this)
{
	if (getGameTime() % 30 != 0) return;

	u8 message_time = this.get_u8("global_message_timer");
	if (message_time > 0)
	{
		global_message = messages[this.get_u8("global_message_index")].replace("{DAYS}", ""+this.get_u16("day_number"));

		message_time--;
		if (message_time == 0)
		{
			global_message = "";
		}
		
		this.set_u8("global_message_timer", message_time);
	}
}

void onRender(CRules@ this)
{
	if (global_message.isEmpty()) return;
	
	Vec2f drawpos(getScreenWidth()*0.5f, getScreenHeight()*0.22);
	GUI::SetFont("menu");
	GUI::DrawShadowedTextCentered(global_message, drawpos, color_white);
}
