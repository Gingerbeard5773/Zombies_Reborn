shared class Respawn
{
	string username;
	u32 timeStarted;

	Respawn(const string&in username, const u32&in timeStarted)
	{
		this.username = username;
		this.timeStarted = timeStarted;
	}
};
