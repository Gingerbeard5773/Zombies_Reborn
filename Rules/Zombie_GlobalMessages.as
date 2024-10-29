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
	onReceiveGlobalMessageHandle@ handle = @onReceiveGlobalMessage;
	this.set("onReceiveGlobalMessage Handle", @handle);
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
		u8 time;
		if (!params.saferead_u8(time)) return;

		u32 color;
		if (!params.saferead_u32(color)) return;
		
		bool isIndex;
		if (!params.saferead_bool(isIndex)) return;
		
		string message;

		if (isIndex)
		{
			u8 index;
			if (!params.saferead_u8(index)) return;

			if (index > server_messages.length)
			{
				error("server message from index does not exist! :: "+getCurrentScriptName()); return; 
			}
			
			message = server_messages[index];

			u8 inputs_length;
			if (!params.saferead_u8(inputs_length)) return;
			
			for (u8 i = 0; i < inputs_length; i++)
			{
				string input;
				if (!params.saferead_string(input)) return;

				const int index = message.findFirst("{INPUT}");
				if (index == -1) break;

				message = message.substr(0, index) + input + message.substr(index + 7);
			}
		}
		else
		{
			if (!params.saferead_string(message)) return;
		}

		GlobalMessage new_message(message, time, SColor(color));
		global_messages.push_back(@new_message);
	}
}

void onReceiveGlobalMessage(CRules@ this, string message, u8 time, SColor color)
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
