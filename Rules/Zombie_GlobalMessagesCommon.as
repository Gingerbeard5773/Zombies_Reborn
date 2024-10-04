// Zombie Global Messages Common

funcdef void onRecieveGlobalMessageHandle(CRules@, string, u8, SColor);

void addOnRecieveGlobalMessage(CRules@ this, onRecieveGlobalMessageHandle@ handle) { this.set("onRecieveGlobalMessage Handle", @handle); }

void server_SendGlobalMessage(CRules@ this, const u8&in message_index, const u8&in message_seconds, const u32&in message_color = color_white.color)
{
	CBitStream stream;
	stream.write_u8(message_index);
	stream.write_u8(message_seconds);
	stream.write_u32(message_color);
	this.SendCommand(this.getCommandID("client_send_global_message"), stream);
}

void client_SendGlobalMessage(CRules@ this, const string&in message, const u8&in message_seconds, SColor message_color = color_white)
{
	onRecieveGlobalMessageHandle@ onRecieveGlobalMessage;
	if (this.get("onRecieveGlobalMessage Handle", @onRecieveGlobalMessage))
	{
		onRecieveGlobalMessage(this, message, message_seconds, message_color);
	}
}
