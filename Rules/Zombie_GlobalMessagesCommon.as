// Zombie Global Messages Common

funcdef void onReceiveGlobalMessageHandle(CRules@, string, u8, SColor);

//Sends a global message by client.
void client_SendGlobalMessage(CRules@ this, const string&in message, const u8&in message_seconds, SColor message_color = color_white)
{
	onReceiveGlobalMessageHandle@ onReceiveGlobalMessage;
	if (this.get("onReceiveGlobalMessage Handle", @onReceiveGlobalMessage))
	{
		onReceiveGlobalMessage(this, message, message_seconds, message_color);
	}
}

//Sends a global message by server.
void server_SendGlobalMessage(CRules@ this, const string&in message, const u8&in message_seconds, const u32&in message_color = color_white.color, CPlayer@ player = null)
{
	CBitStream stream;
	stream.write_u8(message_seconds);
	stream.write_u32(message_color);
	stream.write_string(message);
	stream.write_u8(0);
	server_SendGlobalCommand(this, "client_send_global_message", stream, player);
}

//Same as above but with inputs. each input replaces one instance of {INPUT} of the message string in order.
void server_SendGlobalMessage(CRules@ this, const string&in message, const u8&in message_seconds, const string[]@ inputs, const u32&in message_color = color_white.color, CPlayer@ player = null)
{
	CBitStream stream;
	stream.write_u8(message_seconds);
	stream.write_u32(message_color);
	stream.write_string(message);

	stream.write_u8(inputs.length);
	for (u8 i = 0; i < inputs.length; i++)
	{
		stream.write_string(inputs[i]);
	}

	server_SendGlobalCommand(this, "client_send_global_message", stream, player);
}

void server_SendGlobalCommand(CRules@ this, const string&in cmd, CBitStream@ stream, CPlayer@ player)
{
	if (player is null)
	{
		this.SendCommand(this.getCommandID(cmd), stream);
	}
	else
	{
		this.SendCommand(this.getCommandID(cmd), stream, player);
	}
}

//Sends a global sound by server.
void server_SendGlobalSound(CRules@ this, const string&in sound, CPlayer@ player = null)
{
	CBitStream stream;
	stream.write_string(sound);
	server_SendGlobalCommand(this, "client_send_global_sound", stream, player);
}
