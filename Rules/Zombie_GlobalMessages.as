// Zombie Global Messages

// Show a client side global message
// Allows for better string and rendering manipulation

#define CLIENT_ONLY;

#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_Translation.as";

string global_message = "";
u8 global_message_time = 0;
SColor global_message_color = color_white;

const string Statistics = Translate::Stat0+"\n\n"+Translate::Stat1+"\n\n"+Translate::Stat2+"\n\n"+Translate::Stat3+"\n\n"+Translate::Stat4;

const string[] server_messages =
{
	Translate::Day,
	Translate::GameOver+"\n\n"+Statistics,
	Translate::GameWin+"\n\n"+Statistics,
	Translate::Trader,
	Translate::Sedgwick,
	Translate::Migrant1,
	Translate::Migrant2,
	Translate::Record
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
		global_message_time = params.read_u8();
		global_message_color = params.read_u32();
		
		const bool isIndex = params.read_bool();
		if (isIndex)
		{
			const u8 index = params.read_u8();
			if (index > server_messages.length)
			{
				error("server message from index does not exist! :: "+getCurrentScriptName()); return; 
			}
			
			global_message = server_messages[index];

			const u8 inputs_length = params.read_u8();
			for (u8 i = 0; i < inputs_length; i++)
			{
				const string input = params.read_string();
				const int index = global_message.findFirst("{INPUT}");
				if (index == -1) break;

				global_message = global_message.substr(0, index) + input + global_message.substr(index + 7);
			}
		}
		else
		{
			global_message = params.read_string();
		}
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
