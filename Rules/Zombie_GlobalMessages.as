// Zombie Global Messages

// Show a client side global message
// Allows for better string and rendering manipulation

#define CLIENT_ONLY;

#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_Translation.as";

string global_message = "";
u8 global_message_time = 0;
SColor global_message_color = color_white;

const string[] server_messages =
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
	addOnRecieveGlobalMessage(this, @onRecieveGlobalMessage);
}

void onRestart(CRules@ this)
{
	global_message = "";
	global_message_time = 0;
	global_message_color = color_white;
}

void onTick(CRules@ this)
{
	if (getGameTime() % 30 != 0) return;

	if (global_message_time > 0)
	{
		global_message_time--;
	}
	else
	{
		global_message = "";
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_send_global_message"))
	{
		const u8 index = params.read_u8();
		const u8 message_seconds = params.read_u8();
		const u32 message_color = params.read_u32();
		if (index > server_messages.length)
		{
			error("server message from index does not exist! :: "+getCurrentScriptName()); return; 
		}
		global_message = server_messages[index].replace("{DAYS}", ""+this.get_u16("day_number"));
		global_message_time = message_seconds;
		global_message_color = message_color;
	}
}

void onRecieveGlobalMessage(CRules@ this, string message, u8 message_seconds, SColor message_color)
{
	global_message = message;
	global_message_time = message_seconds;
	global_message_color = message_color;
}

void onRender(CRules@ this)
{
	if (global_message.isEmpty()) return;
	
	Vec2f drawpos(getScreenWidth()*0.5f, getScreenHeight()*0.22);
	GUI::SetFont("menu");
	GUI::DrawShadowedTextCentered(global_message, drawpos, global_message_color);
}
