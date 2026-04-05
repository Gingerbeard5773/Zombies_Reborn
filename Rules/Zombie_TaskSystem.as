// Zombie Fortress task system
// Gingerbeard @ July 14, 2025

#include "BrainTask.as"
#include "Zombie_Translation.as"
#include "Zombie_AchievementsCommon.as"

const f32 menu_height = 50.0f;
const f32 task_buttonsize = 50.0f;
const f32 remove_task_buttonsize = 20.0f;
const f32 between_buttons = 14.0f;
const u8 max_tasks_count = 6;

u16 hovered_netid = 0;
u16 selected_netid = 0;
u16 selected_task_netid = 0;

BrainTask@ custom_mode = null;

string drawtext;
Vec2f drawtextpos;

const string[] task_confirmations =
{
	Translate::Confirm1, Translate::Confirm2, Translate::Confirm3, Translate::Confirm4, Translate::Confirm5, Translate::Confirm6,
	Translate::Confirm7, Translate::Confirm8, Translate::Confirm9, Translate::Confirm10, Translate::Confirm11, Translate::Confirm12
};

void onInit(CRules@ this)
{
	SetupTasksArray();

	AddIconToken("$TASKS_HEADER$", "TasksHeader.png", Vec2f(60, 24), 0);

	this.addCommandID("server_synchronize_tasks");
	this.addCommandID("client_synchronize_tasks");
}

void onReload(CRules@ this)
{
	SetupTasksArray();
}

void onTick(CRules@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null) return;

	if (getGameTime() % 120 == 0)
	{
		SetupGuide(this);
	}

	CControls@ controls = getControls();
	if (controls is null) return;

	HandleMigrantButton(this, controls, localBlob);
	
	HandleTaskMenuInteractions(this, controls, localBlob);
}

void HandleMigrantButton(CRules@ this, CControls@ controls, CBlob@ localBlob)
{
	if (controls.isKeyJustReleased(KEY_KEY_R) && hovered_netid > 0)
	{
		CBlob@ hovered = getBlobByNetworkID(hovered_netid);
		if (hovered !is null)
		{
			Sound::Play("buttonclick.ogg");
			selected_netid = hovered_netid;
			client_Synchronize(this, hovered, true);
		}

		@custom_mode = null;
		hovered_netid = 0;
		return;
	}

	CBlob@ blob = getMigrantFromCursor(controls, localBlob);
	if (!controls.isKeyPressed(KEY_KEY_R) || getHUD().hasMenus() || blob is null)
	{
		hovered_netid = 0;
		return;
	}

	if (hovered_netid != blob.getNetworkID())
	{
		hovered_netid = blob.getNetworkID();
	}
}

void HandleTaskMenuInteractions(CRules@ this, CControls@ controls, CBlob@ localBlob)
{
	if (selected_netid <= 0) return;

	CBlob@ blob = getBlobByNetworkID(selected_netid);
	if (blob is null || blob.hasTag("dead") ||
		//localBlob.isKeyPressed(key_inventory) ||
		localBlob.isKeyJustPressed(key_left) || localBlob.isKeyJustPressed(key_right) || localBlob.isKeyJustPressed(key_up) ||
		localBlob.isKeyJustPressed(key_down) || localBlob.isKeyJustPressed(key_action2) || localBlob.isKeyJustPressed(key_action3))
	{
		@custom_mode = null;
		selected_netid = 0;
		selected_task_netid = 0;
		
		if (blob !is null)
		{
			this.set_netid("inventory access", 0);
		}
		return;
	}

	this.set_netid("inventory access", blob.getNetworkID());

	TaskManager@ manager = getTaskManager(blob);
	if (manager is null) return;

	Vec2f mouse = controls.getMouseScreenPos();
	Driver@ driver = getDriver();
	Vec2f center = driver.getScreenCenterPos();

	// Goto task confirmation
	if (custom_mode !is null)
	{
		if (localBlob.isKeyJustPressed(key_action1))
		{
			BrainTask@ task = custom_mode.Copy(blob);
			manager.AddTask(@task);
			task.destination = driver.getWorldPosFromScreenPos(mouse);
			@custom_mode = null;
			onNewTask(blob);
			client_Synchronize(this, blob);
		}
		return;
	}

	bool mouseHover;
	Vec2f tl, br;
	Vec2f menu_tl, menu_br;
	getMenuBoundaries(manager.tasks.length, center, menu_tl, menu_br);

	Vec2f origin = menu_tl + menu_height;
	
	// Choose current task and remove task buttons
	for (int i = 0; i < manager.tasks.length; i++)
	{
		getTaskButton(origin, tl, br);

		mouseHover = (mouse.x > tl.x && mouse.x < br.x && mouse.y > tl.y && mouse.y < br.y);
		if (manager.index != i && mouseHover && localBlob.isKeyJustPressed(key_action1))
		{
			manager.index = i;
			Sound::Play("buttonclick.ogg");
			client_Synchronize(this, blob);
			return;
		}

		Vec2f remove_button_pos = origin + Vec2f(0, -task_buttonsize*0.75f);
		getRemoveTaskButton(remove_button_pos, tl, br);
		
		mouseHover = (mouse.x > tl.x && mouse.x < br.x && mouse.y > tl.y && mouse.y < br.y);
		if (mouseHover && localBlob.isKeyJustPressed(key_action1))
		{
			manager.RemoveTask(i);
			Sound::Play("buttonclick.ogg");
			client_Synchronize(this, blob);
			return;
		}

		origin.x += task_buttonsize + between_buttons;
	}

	if (manager.tasks.length < max_tasks_count)
	{
		// Go to button
		BrainTask@[]@ self_tasks = getSelfTasks(blob);
		const f32 start_x = center.x - ((self_tasks.length - 1) * (task_buttonsize + between_buttons) / 2);
		origin = Vec2f(start_x, menu_br.y + between_buttons*2);
		for (int i = 0; i < self_tasks.length; i++)
		{
			getTaskButton(origin, tl, br);
			mouseHover = (mouse.x > tl.x && mouse.x < br.x && mouse.y > tl.y && mouse.y < br.y);
			if (mouseHover && localBlob.isKeyJustPressed(key_action1))
			{
				@custom_mode = self_tasks[i].Copy(blob);
				controls.setMousePosition(center);
				Sound::Play("buttonclick.ogg");
				selected_task_netid = 0;
				return;
			}
			origin.x += task_buttonsize + between_buttons;
		}

		// Interact with selected task blob's available tasks
		if (selected_task_netid > 0)
		{
			CBlob@ task_blob = getBlobByNetworkID(selected_task_netid);
			if (task_blob !is null)
			{
				BrainTask@[]@ tasks = getApplicableTasks(task_blob, blob);
				origin = task_blob.getScreenPos();
				origin.x -= task_buttonsize * 0.5f * (tasks.length - 1);

				for (int i = 0; i < tasks.length; i++)
				{
					getTaskButton(origin, tl, br);
					
					mouseHover = (mouse.x > tl.x && mouse.x < br.x && mouse.y > tl.y && mouse.y < br.y);
					if (mouseHover && localBlob.isKeyJustPressed(key_action1))
					{
						BrainTask@ task = tasks[i].Copy(blob, task_blob);
						manager.AddTask(@task);
						Sound::Play("buttonclick.ogg");
						selected_task_netid = 0;
						onNewTask(blob);
						client_Synchronize(this, blob);
						return;
					}

					origin.x += task_buttonsize + between_buttons;
				}
			}
			
			if (localBlob.isKeyJustPressed(key_action1) || task_blob is null)
			{
				selected_task_netid = 0;
			}
		}

		// Select a blob with possible tasks
		CBlob@ hovered = getTaskBlobFromCursor(controls, blob);
		if (hovered !is null && !hovered.isInInventory() && localBlob.isKeyJustPressed(key_action1))
		{
			Sound::Play("Switch.ogg");
			selected_task_netid = hovered.getNetworkID();
			return;
		}
	}
}

void getTaskButton(Vec2f center, Vec2f &out tl, Vec2f &out br)
{
	const f32 halfbuttonsize = task_buttonsize*0.5f;
	tl = center - Vec2f(halfbuttonsize, halfbuttonsize);
	br = tl + Vec2f(task_buttonsize, task_buttonsize);
}

void getRemoveTaskButton(Vec2f center, Vec2f &out tl, Vec2f &out br)
{
	const f32 halfbuttonsize = remove_task_buttonsize*0.5f;
	tl = center - Vec2f(halfbuttonsize, halfbuttonsize);
	br = tl + Vec2f(remove_task_buttonsize, remove_task_buttonsize);
}

void getMenuBoundaries(const int count, Vec2f center, Vec2f &out tl, Vec2f &out br)
{
	const f32 menu_width = Maths::Max(count + 1, 2) * (task_buttonsize * 0.5f) + (between_buttons * 0.5f * Maths::Max(count - 1, 0));
	const f32 height = getScreenHeight() * 0.3f;
	tl = Vec2f(center.x - menu_width, center.y - menu_height + height);
	br = Vec2f(center.x + menu_width, center.y + menu_height + height);
}

void onRender(CRules@ this)
{
	CControls@ controls = getControls();
	if (controls is null) return;

	Driver@ driver = getDriver();

	RenderInteractableMigrant(controls, driver);

	RenderTaskMenu(controls, driver);
}

void RenderInteractableMigrant(CControls@ controls, Driver@ driver)
{
	if (controls.isKeyPressed(KEY_KEY_R))
	{
		CBlob@[] blobs;
		getBlobsByTag("migrant", @blobs);
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b.isInInventory() || !b.isOnScreen() || b.hasTag("dead")) continue;

			RenderIndicator(b, driver, 1);
		}
	}

	if (hovered_netid <= 0) return;

	CBlob@ blob = getBlobByNetworkID(hovered_netid);
	if (blob is null) return;

	GUI::SetFont("menu");
	GUI::DrawTextCentered(Translate::Order, blob.getInterpolatedScreenPos(), color_white);

	blob.RenderForHUD(RenderStyle::outline_front);
	RenderSelectedMigrant(blob, driver);
}

void RenderSelectedMigrant(CBlob@ blob, Driver@ driver)
{
	const f32 scale = getCamera().targetDistance * driver.getResolutionScaleFactor();
	GUI::DrawIcon("PartySelection.png", 0, Vec2f(32, 32), blob.getInterpolatedScreenPos() - Vec2f(32, 32) * scale, scale);
}

void RenderIndicator(CBlob@ blob, Driver@ driver, const u8&in frame)
{
	const f32 scale = getCamera().targetDistance * driver.getResolutionScaleFactor();
	Vec2f pos = blob.getInterpolatedScreenPos() - Vec2f(16.5f, 26 + blob.getHeight()) * scale;
	pos.y += Maths::FastSin(getGameTime() / 4.5f) * 3.0f;
	GUI::DrawIcon("GUI/PartyIndicator.png", frame, Vec2f(16, 16), pos, scale);
}

void RenderTaskMenu(CControls@ controls, Driver@ driver)
{
	if (selected_netid <= 0) return;

	CBlob@ blob = getBlobByNetworkID(selected_netid);
	if (blob is null) return;

	TaskManager@ manager = getTaskManager(blob);
	if (manager is null) return;

	Vec2f mouse = controls.getMouseScreenPos();
	Vec2f center = driver.getScreenCenterPos();

	RenderSelectedMigrant(blob, driver);

	if (custom_mode !is null)
	{
		GUI::DrawSplineArrow2D(blob.getScreenPos(), mouse, SColor(255, 255, 143, 0));
		GUI::SetFont("menu");
		GUI::DrawTextCentered(Translate::TaskPath, mouse + Vec2f(50, 0), color_white);
		return;
	}

	Vec2f tl, br;
	Vec2f menu_tl, menu_br;
	getMenuBoundaries(manager.tasks.length, center, menu_tl, menu_br);

	GUI::DrawRectangle(menu_tl, menu_br);

	Vec2f iconDim;
	GUI::GetIconDimensions("$TASKS_HEADER$", iconDim);
	GUI::DrawIconByName("$TASKS_HEADER$", Vec2f(center.x - iconDim.x, menu_tl.y - menu_height*0.5f - iconDim.y));

	DrawMigrantStats(blob, menu_tl, menu_br);

	Vec2f origin = menu_tl + menu_height;

	// Draw 'empty task unit' if we have no tasks
	if (manager.tasks.length == 0)
	{
		getTaskButton(origin, tl, br);
		GUI::DrawButtonPressed(tl, br);
	}

	// Draw selected tasks from our manager
	for (int i = 0; i < manager.tasks.length; i++)
	{
		getTaskButton(origin, tl, br);
		
		if (manager.tasks.length > 1 && i < manager.tasks.length - 1)
		{
			Vec2f pos = tl + Vec2f(task_buttonsize, task_buttonsize) * 0.5f;
			GUI::DrawArrow2D(pos, pos + Vec2f(between_buttons + task_buttonsize * 0.5f, 0), SColor(0xffb0dd35));
		}
		
		BrainTask@ task = manager.tasks[i];
		const bool selected = i == manager.index;
		if (selected) task.Render();
		
		DrawTaskButton(blob, blob, mouse, tl, br, task, selected);

		DrawTaskRemoveButton(mouse, origin);

		origin.x += task_buttonsize + between_buttons;
	}

	if (manager.tasks.length < max_tasks_count)
	{
		// Go to button
		BrainTask@[]@ self_tasks = getSelfTasks(blob);
		const f32 start_x = center.x - ((self_tasks.length - 1) * (task_buttonsize + between_buttons) / 2);
		origin = Vec2f(start_x, menu_br.y + between_buttons*2);
		for (int i = 0; i < self_tasks.length; i++)
		{
			getTaskButton(origin, tl, br);
			DrawTaskButton(blob, blob, mouse, tl, br, self_tasks[i]);
			origin.x += task_buttonsize + between_buttons;
		}

		// Show available blobs with possible tasks
		CBlob@ hovered = getTaskBlobFromCursor(controls, blob);
		CBlob@[] blobs;
		//getMap().getBlobsInRadius(controls.getMouseWorldPos(), 150.0f, @blobs);
		getBlobs(@blobs);
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b.isInInventory() || !b.isOnScreen()) continue;

			if (!isTaskBlob(b, blob)) continue;

			RenderIndicator(b, driver, 2);

			if (hovered !is null && b is hovered)
			{
				b.RenderForHUD(RenderStyle::outline_front);
			}
		}

		// Show available tasks for selected task blob
		if (selected_task_netid > 0)
		{
			CBlob@ task_blob = getBlobByNetworkID(selected_task_netid);
			if (task_blob !is null)
			{
				BrainTask@[]@ tasks = getApplicableTasks(task_blob, blob);
				origin = task_blob.getScreenPos();
				origin.x -= task_buttonsize * 0.5f * (tasks.length - 1);

				for (int i = 0; i < tasks.length; i++)
				{
					getTaskButton(origin, tl, br);
					
					DrawTaskButton(task_blob, blob, mouse, tl, br, tasks[i]);

					origin.x += task_buttonsize + between_buttons;
				}
			}
		}
	}
	
	if (!drawtext.isEmpty())
	{
		GUI::SetFont("menu");

		Vec2f dim;
		GUI::GetTextDimensions(drawtext, dim);
		dim.x = Maths::Min(dim.x, 200.0f);
		dim += Vec2f(4, 4); //margin
		const f32 halfbuttonsize = task_buttonsize*0.5f;
		Vec2f buttonpos = drawtextpos + Vec2f(halfbuttonsize, halfbuttonsize);
		const int top = buttonpos.y + dim.y + 16 + halfbuttonsize;
		Vec2f upperleft(buttonpos.x - dim.x / 2, top - dim.y);
		Vec2f lowerright(buttonpos.x + dim.x / 2, top - Maths::Min(int(2 * dim.y), 250));

		GUI::DrawText(drawtext, upperleft, lowerright, color_black, false, false, true);
		drawtext = "";
	}
}

void DrawTaskButton(CBlob@ task_blob, CBlob@ blob, Vec2f mouse, Vec2f tl, Vec2f br, BrainTask@ task, const bool&in selected = false)
{
	if (selected)
	{
		GUI::DrawFramedPane(tl - Vec2f(4, 4), br + Vec2f(4, 4));
		GUI::DrawButtonHover(tl, br);
	}

	const bool mouseHover = (mouse.x > tl.x && mouse.x < br.x && mouse.y > tl.y && mouse.y < br.y);
	if (mouseHover)
	{
		GUI::DrawButtonHover(tl, br);
		drawtext = task.description;
		drawtextpos = tl;
	}
	else if (!selected)
	{
		GUI::DrawButton(tl, br);
	}

	const bool noBlob = task.blob is null;
	if (noBlob) @task.blob = blob;
	task.DrawIcon(tl + Vec2f(3.0f, 3.0f), task_blob);
	if (noBlob) @task.blob = null;
}

void DrawTaskRemoveButton(Vec2f mouse, Vec2f origin)
{
	Vec2f tl, br;
	Vec2f remove_button_pos = origin + Vec2f(0, -task_buttonsize*0.75f);
	getRemoveTaskButton(remove_button_pos, tl, br);

	const bool mouseHover = (mouse.x > tl.x && mouse.x < br.x && mouse.y > tl.y && mouse.y < br.y);
	if (mouseHover) 
	{
		GUI::DrawButtonHover(tl, br);
	}
	else
	{
		GUI::DrawButton(tl, br);
	}

	GUI::DrawIcon("MenuItems", 29, Vec2f(32,32), Vec2f(remove_button_pos.x-10, remove_button_pos.y-10), 0.3f);
}

void DrawMigrantStats(CBlob@ blob, Vec2f menu_tl, Vec2f menu_br)
{
	Vec2f info_tl = menu_tl - Vec2f(task_buttonsize*2, 0);
	Vec2f info_br = Vec2f(menu_tl.x - task_buttonsize, menu_br.y - task_buttonsize);
	GUI::DrawFramedPane(info_tl, info_br);

	// Health bar
	const f32 initialHealth = blob.getInitialHealth();
	if (initialHealth > 0.0f)
	{
		const f32 perc = Maths::Min(blob.getHealth(), initialHealth) / initialHealth;
		if (perc >= 0.0f)
		{
			Vec2f dim(40, 12);
			Vec2f health(info_tl.x + task_buttonsize*0.5f, info_br.y + 1);
			GUI::DrawRectangle(Vec2f(health.x - dim.x - 2, health.y - 2), Vec2f(health.x + dim.x + 2, health.y + dim.y + 2));
			GUI::DrawRectangle(Vec2f(health.x - dim.x + 2, health.y + 2), Vec2f(health.x - dim.x + perc * 2.0f * dim.x - 2, health.y + dim.y - 2), SColor(0xffac1512));
		}
	}

	// Head
	CSpriteLayer@ head = blob.getSprite().getSpriteLayer("head");
	if (head !is null)
	{
		GUI::DrawIcon(head.getFilename(), head.getFrame(), Vec2f(16, 16), info_tl - Vec2f(5.0f, 15.0f), 2.0f, blob.getTeamNum());
	}

	GUI::SetFont("hud");
	GUI::DrawTextCentered(blob.getInventoryName(), Vec2f(info_tl.x + task_buttonsize*0.5f, info_br.y + 20.0f), color_white);

	if (getRules().get_netid("guide netid") == blob.getNetworkID())
	{
		GUI::DrawTextCentered(Translate::Guide, Vec2f(info_tl.x + task_buttonsize*0.5f, info_br.y + 40.0f), color_white);
	}
}

CBlob@ getMigrantFromCursor(CControls@ controls, CBlob@ localBlob)
{
	CBlob@[] blobs;
	Vec2f mouse = controls.getMouseWorldPos();
	getMap().getBlobsInRadius(mouse, 8.0f, @blobs);

	CBlob@ closest = null;
	f32 closest_distance = 99999.0f;
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!blob.hasTag("migrant") || blob.hasTag("dead")) continue;
		
		if ((localBlob.getPosition() - blob.getPosition()).Length() > 64) continue;

		const f32 distance = (mouse - blob.getPosition()).LengthSquared();
		if (distance < closest_distance)
		{
			closest_distance = distance;
			@closest = blob;
		}
	}
	
	return closest;
}

CBlob@ getTaskBlobFromCursor(CControls@ controls, CBlob@ migrant)
{
	CBlob@[] blobs;
	Vec2f mouse = controls.getMouseWorldPos();
	getMap().getBlobsAtPosition(mouse, @blobs);

	CBlob@ closest = null;
	f32 closest_distance = 99999.0f;
	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		const f32 distance = (mouse - blob.getPosition()).LengthSquared();
		if (distance >= closest_distance) continue;

		if (isTaskBlob(blob, migrant))
		{
			closest_distance = distance;
			@closest = blob;
		}
	}

	return closest;
}

BrainTask@[]@ getApplicableTasks(CBlob@ blob, CBlob@ migrant)
{
	BrainTask@[] tasks;
	
	CShape@ shape = blob.getShape();
	if (shape is null || !shape.isActive()) return tasks;
	
	for (int i = 0; i < all_tasks.length; i++)
	{
		BrainTask@ task = all_tasks[i];
		if (!task.self && task.isTaskBlob(blob, migrant))
		{
			tasks.push_back(task);
		}
	}

	return tasks;
}

bool isTaskBlob(CBlob@ blob, CBlob@ migrant)
{
	CShape@ shape = blob.getShape();
	if (shape is null || !shape.isActive()) return false;

	for (int i = 0; i < all_tasks.length; i++)
	{
		BrainTask@ task = all_tasks[i];
		if (!task.self && task.isTaskBlob(blob, migrant))
		{
			return true;
		}
	}

	return false;
}

BrainTask@[]@ getSelfTasks(CBlob@ blob)
{
	BrainTask@[] tasks;

	for (int i = 0; i < all_tasks.length; i++)
	{
		BrainTask@ task = all_tasks[i];
		if (task.self && task.isTaskBlob(blob, blob))
		{
			tasks.push_back(task);
		}
	}

	return tasks;
}

void onNewTask(CBlob@ blob)
{
	Achievement::client_Unlock(Achievement::TheBoss);

	//if (!blob.isChatBubbleVisible())
	if (blob.get_u32("next_available_chat") < getGameTime())
	{
		blob.set_u32("next_available_chat", getGameTime() + 30 * 7);
		blob.Chat(task_confirmations[XORRandom(task_confirmations.length)]);
	}
}

void client_Synchronize(CRules@ this, CBlob@ blob, const bool&in recieve = false)
{
	if (isServer()) return;

	CBitStream stream;
	stream.write_netid(blob.getNetworkID());
	stream.write_bool(recieve);
	if (!recieve)
	{
		TaskManager@ manager = getTaskManager(blob);
		if (manager is null) return;

		manager.Serialize(stream);
	}
	this.SendCommand(this.getCommandID("server_synchronize_tasks"), stream);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("server_synchronize_tasks") && isServer())
	{
		CPlayer@ player = getNet().getActiveCommandPlayer();
		if (player is null) return;

		u16 netid;
		if (!params.saferead_netid(netid)) return;

		bool recieve;
		if (!params.saferead_bool(recieve)) return;

		CBlob@ blob = getBlobByNetworkID(netid);
		if (blob is null) return;

		TaskManager@ manager = getTaskManager(blob);
		if (manager is null) return;

		CBitStream stream;
		stream.write_netid(netid);
		if (recieve)
		{
			manager.Serialize(stream);
			this.SendCommand(this.getCommandID("client_synchronize_tasks"), stream, player);
		}
		else
		{
			if (!manager.Unserialize(params)) return;
	
			manager.Serialize(stream);
			this.SendCommand(this.getCommandID("client_synchronize_tasks"), stream);
		}
	}
	else if (cmd == this.getCommandID("client_synchronize_tasks") && isClient())
	{
		u16 netid;
		if (!params.saferead_netid(netid)) return;

		CBlob@ blob = getBlobByNetworkID(netid);
		if (blob is null) return;

		TaskManager@ manager = getTaskManager(blob);
		if (manager is null) return;

		manager.Unserialize(params);
	}
}

/// GUIDE

void SetupGuide(CRules@ this)
{
	CBlob@[] migrants;
	if (!getBlobsByTag("migrant", @migrants)) return;

	// The guide is the oldest alive migrant
	for (int i = 0; i < migrants.length; i++)
	{
		CBlob@ migrant = migrants[i];
		if (migrant.hasTag("dead")) continue;

		this.set_netid("guide netid", migrant.getNetworkID());
		return;
	}
}
