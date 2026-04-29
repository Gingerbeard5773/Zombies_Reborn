#define SERVER_ONLY

#include "WraithCommon.as"

void onTick(CBlob@ this)
{
	const s32 auto_explode = this.get_s32("auto_enrage_time");
	if (this.isKeyPressed(key_action1) || auto_explode <= this.getTickSinceCreated())
	{
		server_SetEnraged(this);
	}
}
