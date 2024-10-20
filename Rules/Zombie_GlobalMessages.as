// Zombie Global Messages

// Show a client side global message
// Allows for better string and rendering manipulation

#define CLIENT_ONLY;

#include "Zombie_GlobalMessagesCommon.as";
#include "Zombie_Translation.as";

GlobalMessage@[] global_messages;

shared class GlobalMessage
{
	string message;
	u8 time;
	SColor color;
	
	GlobalMessage(const string&in message, const u8&in time, const SColor&in color = color_white)
	{
		this.message = message;
		this.time = time;
		this.color = color;
	}
}

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
	Translate::Record,
	Translate::Respawn2,
};

void onInit(CRules@ this)
{
	onRecieveGlobalMessageHandle@ handle = @onRecieveGlobalMessage;
	this.set("onRecieveGlobalMessage Handle", @handle);
}

void onRestart(CRules@ this)
{
	global_messages.clear();
}

void onTick(CRules@ this)
{
	if (global_messages.length <= 0) return;

	if (getGameTime() % 30 != 0) return;

	for (u8 i = 0; i < global_messages.length; i++)
	{
		GlobalMessage@ global_message = global_messages[i];
		if (global_message.time > 0)
		{
			global_message.time--;
		}
		else
		{
			global_messages.erase(i);
			i--;
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_send_global_message"))
	{
		u8 time = params.read_u8();
		SColor color = params.read_u32();
		string message;
		
		const bool isIndex = params.read_bool();
		if (isIndex)
		{
			const u8 index = params.read_u8();
			if (index > server_messages.length)
			{
				error("server message from index does not exist! :: "+getCurrentScriptName()); return; 
			}
			
			message = server_messages[index];

			const u8 inputs_length = params.read_u8();
			for (u8 i = 0; i < inputs_length; i++)
			{
				const string input = params.read_string();
				const int index = message.findFirst("{INPUT}");
				if (index == -1) break;

				message = message.substr(0, index) + input + message.substr(index + 7);
			}
		}
		else
		{
			message = params.read_string();
		}

		GlobalMessage new_message(message, time, color);
		global_messages.push_back(@new_message);
	}
}

void onRecieveGlobalMessage(CRules@ this, string message, u8 time, SColor color)
{
	GlobalMessage new_message(message, time, color);
	global_messages.push_back(@new_message);
}

void onRender(CRules@ this)
{
	if (global_messages.length <= 0) return;
	
	Vec2f drawpos(getScreenWidth()*0.5f, getScreenHeight()*0.22f);
	GUI::SetFont("menu");
	
	for (u8 i = 0; i < global_messages.length; i++)
	{
		GlobalMessage@ global_message = global_messages[i];
		GUI::DrawShadowedTextCentered(global_message.message, drawpos, global_message.color);
		
		if (global_messages.length > 1)
		{
			Vec2f message_dim;
			GUI::GetTextDimensions(global_message.message, message_dim);
			drawpos.y += message_dim.y + 10.0f;
		}
	}
}
