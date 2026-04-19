// Zombie Fortress Translations

// Gingerbeard @ September 21 2024
// translated strings for zombies reborn

shared const string Init(const string&in en, const string&in ru = "")
{
	string text_out = "";
	if (g_locale == "en") text_out = en; //english
	if (g_locale == "ru") text_out = ru; //russian 

	if (text_out.isEmpty()) text_out = en; //default to english if we dont have a translation

	return text_out;
}

const string Translate(const string&in key_name)
{
	dictionary@ d;
	if (!getRules().get("translations", @d))
	{
		SetupTranslations();
		getRules().get("translations", @d);
	}

	string result;
	if (!d.get(key_name, result))
	{
		const string message = "["+key_name+"] No translation found!";
		error(message);
		return message; 
	}

	return result;
}

void SetupTranslations()
{
	print("Initializing Translations");

	dictionary d;
	getRules().set("translations", @d);

	//respawning
	d.set("Respawn0",               Init("Waiting for dawn...",              "В ожидании рассвета..."));
	d.set("Respawn1",               Init("Waiting to spawn as an undead...", "В ожидании восстания из мертвых..."));
	d.set("Respawn2",               Init("Respawned as {INPUT}",             "Возродиться как {INPUT}"));
	d.set("Respawn3",               Init("Spawn in the sky",                 "Появление в небе"));

	//global messages
	d.set("Day",                    Init("Day {INPUT}",                                                 "День {INPUT}"));
	d.set("Record",                 Init("Day {INPUT}\n\nNew record!",                                  "День {INPUT}\n\nНовый рекорд!"));
	d.set("GameOver",               Init("Game over! All players perished! You survived {INPUT} days.", "Конец игры! Все игроки погибли! Вы смогли прожить {INPUT} дней."));
	d.set("Trader",                 Init("A flying merchant has arrived!",                              "Прибыл летающий-торговец!"));
	d.set("Sedgwick",               Init("Sedgwick the necromancer has appeared!",                      "Некромант Седжвик только что явился!"));
	d.set("Migrant1",               Init("A refugee has arrived!",                                      "Прибыл беженец!"));
	d.set("Migrant2",               Init("Refugees have arrived!",                                      "Беженцы прибывают!"));
	d.set("Bobert",                 Init("Bobert has appeared!",                                        ""));
	d.set("Enchanter",              Init("Tim the enchanter has appeared!",                             ""));
	d.set("GoldTilesUnlocked",      Init("All technology researched- Gold tiles unlocked!",             ""));
	d.set("ScrollTimeStart",        Init("Time is speeding up",                                         ""));
	d.set("ScrollTimeFinish",       Init("Time has returned to its normal pace",                        ""));

	//scrolls
	d.set("ScrollClone",            Init("Scroll of Duplication\nUse this to duplicate an object you are pointing to.",                          "Свиток дублирования\nПри использовании, он клонирует объект, на который вы указываете курсором."));
	d.set("ScrollCrate",            Init("Scroll of Compaction\nUse this to crate an object you are pointing at.",                               "Свиток уплотнения\nПри использовании, запечатывает в ящик объект на который вы указываете курсором."));
	d.set("ScrollFish",             Init("Scroll of Fish\nUse this to summon a shark.",                                                          "Свиток Рыбы\nПри использовании, вы призываете морское существо - акулу."));
	d.set("ScrollFlora",            Init("Scroll of Flora\nUse this to create plants nearby.",                                                   "Свиток Флоры\nПри использовании, рядом с вами вырвутся из под земли плодородные растения."));
	d.set("ScrollFowl",             Init("Scroll of Fowl\nUse this to summon a flock of chickens.",                                              "Свиток Птицы\nПри использовании, вы призываете стадо кур."));
	d.set("ScrollRevive",           Init("Scroll of Resurrection\nUse this near a dead body to ressurect them.\nCan auto-resurrect the holder.", "Свиток Воскрешения\nИспользуйте этот свиток рядом с мертвым телом, чтобы воскресить его.\nАвтоматически воскрешает владельца (будучи в инвентаре)."));
	d.set("ScrollRoyalty",          Init("Scroll of Royalty\nUse this to summon a geti.",                                                        "Свиток королевской власти\nПри использовании, вы призовёте Гети."));
	d.set("ScrollSea",              Init("Scroll of Sea\nUse this to generate a source of water.",                                               "Свиток моря\nПри использовании, создает под вами источник воды."));
	d.set("ScrollTeleport",         Init("Scroll of Conveyance\nUse this to teleport to the area you are pointing to.",                          "Свиток телепортации\nПри использовании, телепортирует вас туда, куда вы указали курсором."));
	d.set("ScrollStone",            Init("Scroll of Quarry\nUse this to convert nearby dirt into stone and iron.",                               "Свиток Карьера\nПри использовании, превращает обычную почву рядом с вами в жилы камня."));
	d.set("ScrollWisent",           Init("Scroll of Wisent\nUse this to summon a bison.",                                                        "Свиток Зубра\nПри использовании, вы призываете сухопутное существо - бизона."));
	d.set("ScrollHealth",           Init("Scroll of Health\nUse this to heal yourself and others around you.",                                   "Свиток Здоровья\nПри использовании, придает жизненную силу, исцеляя вас и всех окружающих."));
	d.set("ScrollRepair",           Init("Scroll of Repair\nUse this to repair everything around you.",                                          "Свиток ремонта\nПри использовании, ремонтирует строения и блоки, а также все что окружает вас."));

	d.set("ScrollCreation",         Init("Scroll of Creation\nUse this to magically construct a structure from thin air.",                       "Свиток Творения\nПри использовании, волшебным образом сооружает строение из воздуха."));
	d.set("ScrollEarth",            Init("Scroll of Earth\nUse this to fill in dirt background with dirt.",                                      "Свиток Земли\nПри использовании, заполняет раскопанные блоки почвы."));
	d.set("ScrollChaos",            Init("Scroll of Chaos\nUse this to ???.",                                                                    "Свиток Хаоса\nТворит неизведанные вещи при использовании."));

	d.set("ScrollMidas",            Init("Scroll of Midas",                                                                                      "Свиток Мидаса"));
	d.set("ScrollDesiccation",      Init("Scroll of Desiccation\nUse this to dry up all the water in the world.",                                ""));
	d.set("ScrollResurgence",       Init("Scroll of Resurgence\nUse this to resurrect everyone who has died.",                                   ""));
	d.set("ScrollTime",             Init("Scroll of Time\nUse this to fast forward time by one day.",                                            ""));
	d.set("ScrollObliteration",     Init("Scroll of Obliteration\nUse this to destroy every enemy in the world.",                                ""));
	d.set("ScrollIron",             Init("Scroll of Iron\nUse this to convert nearby stone blocks into iron blocks.",                            ""));
	d.set("ScrollGilding",          Init("Scroll of Gilding\nUse this to gild nearby iron blocks with gold.",                                    ""));

	//builder
	d.set("IronBlock",              Init("Iron Block\nResistant to explosions",                  "Железный блок\nВзрывоустойчивый Блок"));
	d.set("IronBlockBack",          Init("Back Iron Wall\nDurable Support",                      "Железная стена\nПрочная опора"));
	d.set("IronDoor",               Init("Iron Door\nPlace next to walls",                       "Железная дверь\nСтавьте возле стены"));
	d.set("IronPlatform",           Init("Iron Platform\nOne way platform\nBlocks water",        "Железная платформа\nОдносторонняя платформа\nБлокирует воду"));
	d.set("IronSpikes",             Init("Iron Spikes\nDurable spikes",                          "Железные шипы\nПрочные шипы"));
	d.set("Dirt",                   Init("Dirt\nPlace on existing dirt",                         "Земля\nПоместить на существующий фон земли"));
	d.set("Windmill",               Init("Wind Mill\nA grain mill for producing flour",          "Мельница\nЗерновая мельница для производства муки"));
	d.set("Kitchen",                Init("Kitchen\nCreate various foods for healing",            "Кухня\nГотовьте различную еду для восстановления здоровья"));
	d.set("Forge",                  Init("Forge\nSmelt raw ore into ingots",                     "Плавильня\nПереплавляет сырую руду в слитки"));
	d.set("Nursery",                Init("Nursery\nA plant nursery for agricultural purposes",   "Рассадник\nРассадник для сельскохозяйственных культур"));
	d.set("Armory",                 Init("Armory\nBuild weapons and change your class",          "Оружейная\nСлужит для создания оружия из слитков, позволяет сменить класс"));
	d.set("Library",                Init("Library\nA place of study to obtain new technologies", "Библиотека\nМесто хранения знаний и открытий, здесь можно освоить новые технологии"));
	d.set("Sign",                   Init("Sign\n!write [text]",                                  ""));

	//workers
	d.set("Worker",                 Init("Worker",                                                            "Работник"));
	d.set("AssignWorker",           Init("Assign Worker",                                                     "Назначить работника"));
	d.set("UnassignWorker",         Init("Unassign Worker",                                                   "Уволить работника"));
	d.set("WorkerRequired",         Init("Requires a worker",                                                 "Требуется работник"));
	d.set("RestWorker",             Init("Rest Worker",                                                       "Отдыхающий работник"));
	d.set("RecruitWorker",          Init("Recruit a worker for your needs.\nUse key [R] to command workers.", "Наймите работника для своих нужд.\nИспользуйте клавишу [R] для управления работниками."));
	d.set("Order",                  Init("Order",                                                             "Командование"));

	d.set("Confirm0",               Init("I shall do that.",      ""));
	d.set("Confirm1",               Init("As you wish.",          ""));
	d.set("Confirm2",               Init("Im on the job.",        ""));
	d.set("Confirm3",               Init("I will do my best.",    ""));
	d.set("Confirm4",               Init("Understood.",           ""));
	d.set("Confirm5",               Init("I'm on it.",            ""));
	d.set("Confirm6",               Init("I’ll take care of it.", ""));
	d.set("Confirm7",               Init("Right away.",           ""));
	d.set("Confirm8",               Init("It shall be done!",     ""));
	d.set("Confirm9",               Init("At once!",              ""));
	d.set("Confirm10",              Init("As ordered.",           ""));
	d.set("Confirm11",              Init("I’ll see to it.",       ""));
	d.set("Confirm12",              Init("Under your command.",   ""));

	d.set("TaskPath",               Init("Go to",               "Переместиться в"));
	d.set("TaskDorm",               Init("Go to dormitory",     "Перейдите в общежитие"));
	d.set("TaskFactory",            Init("Handle factory",      ""));
	d.set("TaskLibrary",            Init("Research at library", ""));
	d.set("TaskTurret",             Init("Handle turret",       "Управление турелью"));
	d.set("TaskBoat",               Init("Row boat",            "Гребите на лодке"));
	d.set("TaskFollow",             Init("Follow",              "Следовать"));
	d.set("TaskTree",               Init("Chop trees",          "Рубить деревья"));
	d.set("TaskGrain",              Init("Harvest grain",       "Сбор зерна"));
	d.set("TaskGather",             Init("Gather",              "Собирать"));
	d.set("TaskDeposit",            Init("Deposit inventory",   "Депозитный запас"));
	d.set("TaskFuel",               Init("Fuel building",       "Залейте топливо"));
	d.set("TaskSafety",             Init("Go to safety",        "Отправляйтесь в безопасное место"));
	d.set("TaskPatrol",             Init("Patrol",              "Патруль"));
	d.set("TaskGuard",              Init("Guard",               "Сторожить"));
	d.set("TaskRefill",             Init("Refill ammunition",   "Пополнить боеприпасы"));

	//guide
	d.set("Help",                   Init("Help",                                                                                               ""));
	d.set("Guide",                  Init("the Guide",                                                                                          ""));
	d.set("Guide1",                 Init("A dead body will transform into an undead after some time. Be careful!",                             ""));
	d.set("Guide2",                 Init("Wraiths aren't compatible with water. Use it to your advantage.",                                    ""));
	d.set("Guide3",                 Init("Aim for the head with arrows, it will hurt them more.",                                              ""));
	d.set("Guide4",                 Init("The trader will only come if he can land safely.",                                                   ""));
	d.set("Guide5",                 Init("Respawns are instant if there is no undead during day light.",                                       ""));
	d.set("Guide6",                 Init("Refugees can come every other day if the undead population is low. Use key [R] to command workers.", ""));
	d.set("Guide7",                 Init("Beware, the undead can use transport tunnels if they reach them.",                                   ""));
	d.set("Guide8",                 Init("Sell excess materials to the trader for a coin boost.",                                              ""));
	d.set("Guide9",                 Init("As the days progress, more dangerous undead may appear.",                                            ""));
	d.set("Guide10",                Init("As a fuel source, coal is four times more potent than wood!",                                        ""));
	d.set("Guide11",                Init("Hurt workers can use the dormitory or eat food to heal up.",                                         ""));
	d.set("Guide12",                Init("Supposedly, the skelepedes don't show up as much if you live underground.",                          ""));
	d.set("Guide13",                Init("I've seen it happen! The undead will merge with eachother if they are high in number.",              ""));
	d.set("Guide14",                Init("Parent vehicles with ammunition can reload their connected turrets.",                                ""));
	d.set("Guide15",                Init("If your vehicle gets damaged, put it on the vehicle shop to repair it.",                             ""));
	d.set("Guide16",                Init("Water bombs can be used to temporarily stun the undead.",                                            ""));
	d.set("Guide17",                Init("A few rare scrolls may pop up in trade occasionally, keep your eyes peeled.",                        ""));
	d.set("Guide18",                Init("Eat food to heal up. You may need to build a grain mill and kitchen to make bread.",                 ""));
	d.set("Guide19",                Init("I can tell more about rare items, if you’re carrying any.",                                          ""));

	d.set("GuideVogue1",            Init("Have you built a library yet? Upgrades are important.",                                      ""));
	d.set("GuideVogue2",            Init("Put some scholars in the library, they will speed up technological research.",               ""));
	d.set("GuideVogue3",            Init("The necromancer! You can tell what spell hes conjuring from the color of his orbs!",         ""));
	d.set("GuideVogue4",            Init("Theres a guy named Bobert that might show up soon.",                                         ""));
	d.set("GuideVogue5",            Init("Bobert is here! He may be undead and a little crazy but hes got the good stuff.",            ""));
	d.set("GuideVogue6",            Init("If you get too close to that portal it will activate and all hell will break loose.",        ""));
	d.set("GuideVogue7",            Init("If you damage the portal and fail to destroy it, things will only get worse, do your best!", ""));
	d.set("GuideVogue8",            Init("Tim the enchanter is here, if you pay him he will enchant your items! What a cool wizard!",  ""));

	d.set("GuideItem1",             Init("Ah yes, the mythical scroll of duplication. It's capable of cloning something perfectly, with all its contents!",  ""));
	d.set("GuideItem2",             Init("The sea scroll has been hated by many villagers in the past for flooding their towns..",                           ""));
	d.set("GuideItem3",             Init("The crate scroll that you have is very powerful. It is even capable of sealing devils within boxes, as they say.", ""));
	d.set("GuideItem4",             Init("Hmm, the scroll of revival. A strong spell that can bring many bodies back if used properly.",                     ""));
	d.set("GuideItem5",             Init("The scroll of health is best used when around all your friends, as it will bless everyone nearby!",                ""));
	d.set("GuideItem6",             Init("That is quite the scroll you are carrying. I suggest using it only when in serious peril.",                        ""));
	d.set("GuideItem7",             Init("The scroll of conveyence. Quite handy for getting out of dangerous situations.",                                   ""));
	d.set("GuideItem8",             Init("The scroll of repair is best reserved for your most expensive walls and traps.",                                   ""));
	d.set("GuideItem9",             Init("That midas scroll is of great value. Use it around a large patch of stone for maximum benefit.",                   ""));
	d.set("GuideItem10",            Init("The scroll of quarry converts dirt to stone, and stone to iron.",                                                  ""));
	d.set("GuideItem11",            Init("Is that the famed Holy Hand Grenade of Antioch? Be careful with that now, we don't want to have an accident.",     ""));
	d.set("GuideItem12",            Init("Ah the shotgun, foreign technology brought in by Tim. Yours seems to hold two shots.",                             ""));
	d.set("GuideItem13",            Init("That Bazooka you have there is quite a spectacle of technology. It uses big bombs as ammo!",                       ""));
	d.set("GuideItem14",            Init("Is that a flamethower you got? It siphons molotovs for a continuous stream of flame.",                             ""));

	//generic
	d.set("PullItems",              Init("Take items from other storages", "Извлечь предметы\nБерет предметы из других хранилищ."));
	d.set("AddFuel",                Init("Add fuel (Wood or Coal)",        "Добавить топливо (дерево или уголь)\nДобавляет дерево или уголь в качестве топлива."));
	d.set("Recipes",                Init("Recipes",                        "Рецепты\nСписок всех доступных рецептов."));
	d.set("SetRecipe",              Init("Set Recipe",                     "Выбрать рецепт\nИспользует выбранный рецепт."));
	d.set("CurrentRecipe",          Init("Current Recipe",                 "Текущий рецепт\nНынешний выбранный рецепт."));
	d.set("Equip",                  Init("Equip {ITEM}",                   "Экипировать {ITEM}"));
	d.set("Unequip",                Init("Unequip {ITEM}",                 "Снять {ITEM}"));
	d.set("Consume",                Init("Consume {ITEM}",                 ""));

	//building
	d.set("Factory",                Init("A generic factory for various items. Requires a free worker to produce items.", "Общая фабрика для различных вещей. Требуется свободный рабочий для изготовления предметов."));
	d.set("Dormitory",              Init("A dorm for recruiting and healing workers. Functions as a respawn point.",      "Общежитие для набора и лечения рабочих. Это также, место для возрождения и новоприбывших."));

	//factory
	d.set("Bigbomb",                Init("Big Bomb", "Большая бомба"));

	//vehicleshop
	d.set("Bomber",                 Init("A balloon capable of flying. Allows attachments. Press [Space] to drop bombs.",                       "Воздушный шар, способный летать. Позволяет устанавливать навесное оборудование. Нажмите [Пробел] для сброса бомб."));
	d.set("Armoredbomber",          Init("Armored Bomber\nA balloon with protective plating. Allows attachments. Press [Space] to drop bombs.", "Бронированный бомбардировщик\nВоздушный шар с защитным покрытием. Позволяет устанавливать навесное оборудование. Нажмите [Пробел] для сброса бомб."));
	d.set("Mountedbow",             Init("A portable arrow-firing death machine. Can be attached to some vehicles.",                            "Стреляющий стрелами портативный механизм смерти. Может быть установлена на некоторые машины."));
	d.set("Tank",                   Init("Tank\nA seige tank. Allows attachments.",                                                             "Танк\nОсадный танк. Позволяет устанавливать навесное оборудование."));
	d.set("LightBallista",          Init("Light Ballista\nA portable ballista. Can be attached to some vehicles.",                              "Легкая баллиста\nПередвижная баллиста. Может устанавливаться на некоторые машины."));
	d.set("Cannon",                 Init("Cannon\nA cannon that is capable of obliterating any foe. Can be attached to some vehicles.",         "Пушка\nПушка, способная уничтожить любого противника. Может устанавливаться на некоторые машины."));
	d.set("Zeppelin",               Init("Zeppelin\nA sky fortress with many accomodations on board. Functions as a respawn point.",            "Цеппелин\nНебесная крепость с множеством жилых помещений на борту. Служит точкой возрождения."));
	d.set("Cannonballs",            Init("Cannonballs\nCannonballs for the cannon.", "Пушечные ядра\nПушечные ядра для пушки."));

	//archershop
	d.set("MolotovArrows",          Init("Molotov arrows\nFor incinerating the enemy.", "Стрелы Молотова\nДля испепеления врага."));
	d.set("FireworkArrows",         Init("Firework rockets\nExplodes where you aim.",   "Фейерверки\nВзрывается там, куда вы целитесь."));

	//kitchen
	d.set("Flour",                  Init("Flour",                                       "Мука"));
	d.set("Bread",                  Init("Bread\nDelicious crunchy whole-wheat bread.", "Хлеб\nВкусный хрустящий хлеб из цельнозерновой муки."));
	d.set("Cake",                   Init("Cake\nFluffy cake made from egg and wheat.",  "Пирог\nПышный пирог из яиц и пшеницы."));
	d.set("Cookedfish",             Init("Cooked Fish\nA cooked fish on a stick.",      "Жареная рыба\nПриготовленная рыба на палочке."));
	d.set("Cookedchicken",          Init("Cooked Chicken\nJuicy chicken roast!",        "Приготовленная курица/nСочная жареная курица!"));
	d.set("Cookedsteak",            Init("Cooked Steak\nA meat chop with sauce.",       "Жареный стейк\nОтбивная с соусом."));
	d.set("Burger",                 Init("Burger\nSeared meat in a bun!",               "Бургер\nОбжареное мясо в булочке!"));
	d.set("Beer",                   Init("Beer\nA delicious mug of beer!",              "Пиво\nВкусная кружка пива!"));

	//forge
	d.set("IronOre",                Init("Iron Ore",                                                        "Железная руда"));
	d.set("Coal",                   Init("Coal\nCan be used for fuel or be used to refine steel.",          "Уголь\nМожно использовать в качестве топлива или для очистки стали."));
	d.set("IronIngot",              Init("Iron Ingot\nCan be used to create weapons and equipment",         "Железный слиток\nМожно использовать для создания оружия и снаряжения."));
	d.set("SteelIngot",             Init("Steel Ingot\nCan be used to create strong weapons and equipment", "Стальной слиток\nМожно использовать для создания прочного оружия и снаряжения."));

	//armory
	d.set("Scythe",                 Init("Scythe\nA tool for cutting crops fast.\nAllows for grain auto-pickup.",                 "Коса\nИнструмент для быстрого срезания урожая.\nПозволяет поднямать зерна автоматически."));
	d.set("Spear",                  Init("Spear\nA long polearm for stabbing from a distance.",                                   "Копье\nДлинное древковое оружие для нанесения ударов на расстоянии."));
	d.set("Crossbow",               Init("Crossbow\nFires any arrow type.\nHold right mouse button to reload.",                   "Арбалет\nСтреляет любыми стрелами\nЗажмите ПКМ, чтобы перезарядить."));
	d.set("Musket",                 Init("Musket\nFires musket balls.\nHold right mouse button to reload.",                       "Мушкет\nСтреляет патронами для Мушкета.\nЗажмите ПКМ, чтобы перезарядить."));
	d.set("MusketBalls",            Init("Musket Balls\nAmmunition for the Musket.",                                              "Мушкетные пули\nПатроны для мушкета"));
	d.set("Chainsaw",               Init("Chainsaw\nCuts through wood fast.",                                                     "Бензопила\nРежет дерево быстрее."));
	d.set("Molotov",                Init("Molotov\nA flask of fire which can be thrown at the enemy. Press [Space] to activate.", "Молотов\nФляга с горючей жидкостью которую можно бросить во врага. Нажмите [Space] для активации."));
	d.set("ScubaGear",              Init("Scuba Gear\nAllows breathing under water.",                                             "Акваланг\nПозволяет дышать под водой."));
	d.set("HeadLamp",               Init("Head Lamp\nWearable lantern for easy illumination!",                                    "Наголовный фонарь\nПереносной фонарь для легкого освещения!"));
	d.set("SteelDrill",             Init("Steel Drill\nA strong drill that can mine for an extended length of time.",             "Стальной бур\nМощный бур, способный вести добычу в течение длительного времени."));
	d.set("SteelHelmet",            Init("Steel Helmet\nA durable helmet to protect your head.",                                  "Стальной шлем\nПрочный шлем для защиты вашей головы."));
	d.set("SteelArmor",             Init("Steel Chestplate\nA durable chestplate to protect your body.",                          "Стальной нагрудник\nПрочная нагрудная пластина для защиты вашего тела."));
	d.set("Backpack",               Init("Backpack\nA backpack to carry your belongings.",                                        "Рюкзак\nРюкзак для переноски ваших вещей."));
	d.set("Parachutepack",          Init("Parachute Pack\nAllows you to fall slowly. Press [Shift] to activate.",                 "Парашютный ранец\nПозволяет вам медленно падать. Нажмите [Shift] для активации."));
	d.set("Partisan",               Init("Partisan\nAn extremely long unwieldy polearm for far-reach poking.",                    "Партизан\nЧрезвычайно длинное и громоздкое древковое оружие для дальних ударов."));

	//clock
	d.set("SetHours",               Init("Set hours to activate", ""));
	d.set("ToggleHour",             Init("Toggle hour [{INPUT}]", ""));

	//trader
	d.set("Buy",                    Init("Buy {ITEM} ({QUANTITY})",                                  "Купить {ITEM} ({QUANTITY})"));
	d.set("Buy2",                   Init("Buy {QUANTITY} {ITEM} for {COINS} $COIN$",                 "Купить {QUANTITY} {ITEM} за {COINS} $COIN$"));
	d.set("Sell",                   Init("Sell {ITEM} ({QUANTITY})",                                 "Продать {ITEM} ({QUANTITY})"));
	d.set("Sell2",                  Init("Sell {QUANTITY} {ITEM} for {COINS} $COIN$",                "Продать {QUANTITY} {ITEM} за {COINS} $COIN$"));
	d.set("InStock",                Init("{QUANTITY} In stock",                                      "{QUANTITY} в наличии"));
	d.set("OutOfStock",             Init("Out of stock",                                             "Нет в наличии"));
	d.set("TraderLeave0",           Init("My time here is closing.",                                 "Моё время на исходе."));
	d.set("TraderLeave1",           Init("I am leaving soon.",                                       "Я скоро покину вас."));
	d.set("TraderLeave2",           Init("I’ll be departing shortly.",                               "Я быстро покину это место." ));

	// scrolls description
	d.set("TradeScrollCarnage",     Init("Sedgwick really doesn't want me to have this.",            "Седжвик действительно не хочет, чтобы это было у меня."));
	d.set("TradeScrollMidas",       Init("Makes the rocks shiny.",                                   "Придает камням блеск."));
	d.set("TradeScrollSea",         Init("A powerful spell known to flood entire villages.",         "Мощное заклинание, способное затопить целые деревни."));
	d.set("TradeScrollTeleport",    Init("This one can take you anywhere.",                          "Этот доставит вас куда угодно."));
	d.set("TradeScrollStone",       Init("If you need rocks.",                                       "Если вам нужны камни."));
	d.set("TradeScrollRevive",      Init("Bring back a friend of yours, or maybe even yourself.",    "Воскрешает вашего друга или, может быть, даже вас самих."));
	d.set("TradeScrollCrate",       Init("It can put anything in a box, somehow.",                   "Каким-то образом он может поместить в коробку всё, что угодно."));
	d.set("TradeScrollDupe",        Init("Long lost magic that appears to make a copy of anything!", "Давно утраченная магия, которая, кажется, создает копию чего угодно!"));
	d.set("TradeScrollDrought",     Init("Vaporizes bodies of water.",                               "Испаряет водоёмы."));
	d.set("TradeScrollFlora",       Init("Creates various plants from thin air.",                    "Создает различные растения из воздуха."));
	d.set("TradeScrollRoyalty",     Init("I forgot what this one did.",                              "Я забыл, что оно делает."));
	d.set("TradeScrollWisent",      Init("Summons a bison. Good for meat!",                          "Вызывает бизона. Отлично подходит для забива на мясо!"));
	d.set("TradeScrollFowl",        Init("If you need some eggs.",                                   "Если вам нужно немного яиц."));
	d.set("TradeScrollFish",        Init("Summons a bloodthirsty shark.",                            "Вызывает кровожадную акулу."));
	d.set("TradeScrollHealth",      Init("This one can heal even the worst injuries.",               "Это заклинание может залечить даже самые тяжелые травмы."));
	d.set("TradeScrollRepair",      Init("This one will fix up whatever is nearby!",                 "Это заклинание починит всё, что находится поблизости!"));

	//bobert
	d.set("HolyGrenade",            Init("Holy Hand Grenade\nDo mot askj me where I got this.,..",   "Святая ручная граната\nНе спрашывайти меня, откуда я это взял..."));
	d.set("Bazooka",                Init("Bazooka\nBoom! Boom! Boom! uses big bombsa.",              "Базука\nБум! Бум! Бум! Использует большие бомбы."));
	d.set("Shotgun",                Init("Shotgun\ni tested itm on some randome guy!! works good!!", "Дробовик\nя проверял его на каком-то случайном парне!! работает хорошо!!"));
	d.set("Flamethrower",           Init("Flamethrower\nHOT HOT! uses molotovsa.",                   ""));
	d.set("Bobert0",                Init("I'll be takinge my leave soonm,,..",                       "Я скора уййду..."));
	d.set("Bobert1",                Init("Goodbye.",                                                 "Прощай."));
	d.set("Bobert2",                Init("Be carefule withe that!!.",                                "Буть с этим остарожен."));
	d.set("Bobert3",                Init("Lotsa of valuables! for sale!",                            "Множества ценых вищей на продажу!"));
	d.set("Bobert4",                Init("Hi!!! Buy my stuff! :D",                                   "Привет! Купи мои вещи!"));

	//enchanter
	d.set("Enchanter0",             Init("Bring forth the items I seek and you shall be rewarded.", ""));
	d.set("Enchanter1",             Init("Excellent. Bring forth an item you wish to be given power.", ""));
	d.set("Enchanter2",             Init("I cannot bestow this item with magic.", ""));
	d.set("Enchanter3",             Init("This object has no arcane potential.", ""));
	d.set("Enchanter4",             Init("This is an unenchantable item.", ""));
	d.set("Enchanter5",             Init("I return whence I came. Goodbye.", ""));
	d.set("Enchanter6",             Init("You have paid, but I must leave now. I shall enchant randomly.", ""));
	d.set("Enchanter7",             Init("I have used enough of my magic, I am leaving. Farewell.", ""));
	d.set("Enchanter8",             Init("For my services, you must deliver the items I ask for.", ""));
	d.set("Enchanter9",             Init("Provide me with what I require.", ""));
	d.set("Enchanter10",            Init("Very well. Place before me what you seek to strengthen.", ""));
	d.set("Enchanter11",            Init("To have the gall to attempt such a thing, shame on thee...", ""));

	d.set("EnchantGUI0",            Init("Give Payment", ""));
	d.set("EnchantGUI1",            Init("Assess Item", ""));
	d.set("EnchantGUI2",            Init("Tim requires these items as remittance", ""));
	d.set("EnchantGUI3",            Init("Do you wish to enchant this item?", ""));
	d.set("EnchantGUI4",            Init("Enchants into $BLUE$ {ITEM}", ""));
	d.set("EnchantGUI5",            Init("{INPUT} Enchants left", ""));

	d.set("Wings",                  Init("Dragoon Wings\nMythical wings forged from magic.", ""));
	d.set("GoldenHelmet",           Init("Golden Helmet\nAn enchanted helmet etched with rune magic.", ""));
	d.set("GoldenArmor",            Init("Golden Armor\nAn enchanted breastplate etched with rune magic.", ""));
	d.set("GoldenChicken",          Init("Golden Chicken\nA legendary chicken from myths which lays golden eggs.", ""));

	//library
	d.set("Researching",            Init("Researching - {PERCENT}",      "Исследование - {PERCENT}"));
	d.set("Paused",                 Init("Paused - {PERCENT}",           "Остановлено - {PERCENT}"));
	d.set("Resume",                 Init("Click to resume",              "Нажмите, чтобы продолжить"));
	d.set("Completed",              Init("Completed",                    "Завершенно"));
	d.set("RequiresTech",           Init("Requires previous technology", "Требуется предыдущая\nтехнология"));
	d.set("TechComplete",           Init("{TECH} technology complete",   "Технология {TECH} исследована"));
	d.set("ResearchTime",           Init("Research time: {TIME} days",   "Время исследования: {TIME} дней"));

	//technology
	d.set("Coinage",                Init("Coinage\nCoins auto-yield 10%.",                                    "Чеканка монет I\nДоход монет составляет 10%."));
	d.set("CoinageII",              Init("Coinage II\nCoins auto-yield 20%.",                                 "Чеканка монет II\nДоход монет составляет 20%."));
	d.set("CoinageIII",             Init("Coinage III\nCoins auto-yield 30%.",                                "Чеканка монет III\nДоход монет составляет 30%."));
	d.set("HardyWheat",             Init("Hardy Wheat\nWheat can grow on stone and ores.",                    "Выносливая пшеница\nПшеница может расти на камнях и рудах."));
	d.set("HardyTrees",             Init("Hardy Trees\nTrees can grow on stone and ores.",                    "Выносливая деревья\nДеревья могут расти на камне и рудах."));
	d.set("PlentifulWheat",         Init("Plentiful Wheat\nWheat can yield an extra grain.",                  "Обилие пшеницы\nПшеница может дать дополнительное зерно при добыче."));
	d.set("Metallurgy",             Init("Metallurgy\n Forging time reduced by 15%.",                         "Металлургия I\nВремя плавления сокращено на 15%."));
	d.set("MetallurgyII",           Init("Metallurgy II\nForging time reduced by 25%.",                       "Металлургия II\nВремя плавления сокращено на 25%."));
	d.set("MetallurgyIII",          Init("Metallurgy III\nForging time reduced by 35%.",                      "Металлургия III\nВремя плавления сокращено на 35%."));
	d.set("MetallurgyIV",           Init("Metallurgy IV\nForging time reduced by 50%.",                       "Металлургия IV\nВремя плавления сокращено на 50%."));
	d.set("Refinement",             Init("Refinement \nForging has a 10% chance to yield an extra ingot.",    "Искусство обработки I\nКузница при работе может произвести дополнительный слиток с шансом в 10%."));
	d.set("RefinementII",           Init("Refinement II\nForging has a 20% chance to yield an extra ingot.",  "Искусство обработки II\nКузница при работе может произвести дополнительный слиток с шансом в 20%."));
	d.set("RefinementIII",          Init("Refinement III\nForging has a 30% chance to yield an extra ingot.", "Искусство обработки III\nКузница при работе может произвести дополнительный слиток с шансом в 30%."));
	d.set("RefinementIV",           Init("Refinement IV\nForging has a 40% chance to yield an extra ingot.",  "Искусство обработки IV\nКузница при работе может произвести дополнительный слиток с шансом в 40%."));
	d.set("Extraction",             Init("Extraction \nQuarrys have a chance to yield iron ore.",             "Добыча ископаемых I\nКарьер во время работы может добыть железную руду."));
	d.set("ExtractionII",           Init("Extraction II\nQuarrys have a chance to yield gold ore.",           "Добыча ископаемых II\nКарьер во время работы может добыть золотую руду."));
	d.set("Milling",                Init("Milling\nWind mills produce 15% more flour.",                       "Переработка зерна I\nВетряные мельницы производят на 15% больше муки."));
	d.set("MillingII",              Init("Milling II\nWind mills produce 15% more flour.",                    "Переработка зерна II\nВетряные мельницы производят на 15% больше муки."));
	d.set("MillingIII",             Init("Milling III\nWind mills produce 20% more flour.",                   "Переработка зерна III\nВетряные мельницы производят на 20% больше муки."));
	d.set("Swords",                 Init("Sharpening Stone\nSwords deal +30% damage.",                        "Точильный камень\nПравильно заточенные мечи наносят на +30% урона больше."));
	d.set("SwordsII",               Init("Damascus Steel\nSwords deal +30% damage.",                          "Дамасская cталь\nМатериал дает лезвию дополнительную остроту, прибавляя +30% к урону."));
	d.set("LightArmor",             Init("Lightweight Armor\nArmor encumbrance -50%.",                        "Легковесная броня\nПластичность и легкость брони увеличивает вашу скорость +50%."));
	d.set("CombatPickaxes",         Init("Combat Pickaxes\nPickaxes deal 2x damage.",                         "Боевые кирки\nКирки наносят в х2 больше урона."));
	d.set("LightPickaxes",          Init("Light Pickaxes\nPickaxe mining speed increased.",                   "Лёгкие кирки\nСкорость добычи с помощью кирки увеличена."));
	d.set("PrecisionDrills",        Init("Precision Drilling\nDrills yield 100%.",                            "Мастерство бурения\nБур добывает 100% материала."));
	d.set("Architecture",           Init("Architecture\nBlock placement is faster.",                          "Скорость строительства\nРазмещение блоков происходит быстрее."));
	d.set("Supplies",               Init("Supplies\n+5 stone, +10 wood per resupply.",                        "Снабжение I\n+5 камней, +10 досок к снабжению."));
	d.set("SuppliesII",             Init("Supplies II\n+5 stone, +10 wood per resupply.",                     "Снабжение II\n+5 камней, +10 досок к снабжению."));
	d.set("SuppliesIII",            Init("Supplies III\n+10 stone, +10 wood per resupply.",                   "Снабжение III\n+10 камней, +10 досок к снабжению."));
	d.set("Repeaters",              Init("Repeaters\nCrossbows are automatic.",                               "Повторители\nАвтоматизирует арбалеты"));
	d.set("LightBows",              Init("Light Bows\nArchers fire faster.",                                  "Лёгкие луки\nЛучники стреляют быстрее."));
	d.set("DeepQuiver",             Init("Deep Quiver\nArchers have infinite arrows.",                        "Глубокие колчаны\nУ лучников нескончаемое количество стрел"));
	d.set("MachineBows",            Init("Machine Bows\nMounted Bows fire faster.",                           "Механизированные луки\nСтационарные арбалеты стреляют быстрее."));
	d.set("FastBurnPowder",         Init("Fast-Burning Powder\nMuskets' +25% damage.",                        "Быстросгорающий порох\nУрон от мушкетов возрастает до +25%."));
	d.set("HeavyLead",              Init("Heavy Lead\nMuskets' +45% damage.",                                 "Тяжелый свинец\nУрон от мушкетов увеличивается на 45%."));
	d.set("RifledBarrels",          Init("Rifled Barrels\nMuskets' penetration increased.",                   "Нарезные стволы\nПробиваемость ружей увеличена."));
	d.set("Bandoliers",             Init("Bandoliers\nMuskets' reload twice as fast.",                        "Патронташи\nМушкеты перезаряжаются в два раза быстрее."));
	d.set("GreekFire",              Init("Greek Fire\nIncendiary weapons deal +50% damage.",                  "Греческий огонь\nВоспламеняющее оружие наносит +50% урона."));
	d.set("Shrapnel",               Init("Shrapnel\nExplosives +25% damage.",                                 "Шрапнель I\nВзрывы наносят +25% урона."));
	d.set("ShrapnelII",             Init("Shrapnel II\nExplosives +25% damage.",                              "Шрапнель II\nВзрывы наносят +25% урона."));
	d.set("HighExplosives",         Init("High Explosives\nExplosives' radius increased.",                    "Усиленная взрывчатка\nРадиус действия взрывчатки увеличился."));
	d.set("HolyWater",              Init("Holy Water\nWater bomb radius and stun time 2x.",                   "Святая вода\nРадиус действия водяной бомбы и время оглушения увеличиваются в 2 раза."));
	d.set("BlastShields",           Init("Blast Shields\nShields negate all explosion damage.",               "Взрывоустойчивые щиты\nЩиты устойчивы к сильным взрывам."));
	d.set("FlightTuning",           Init("Flight Tuning\nAerial vehicles fly 25% faster.",                    "Регулировка полёта\nЛетательные машины летают на 25% быстрее."));
	d.set("IronChassis",            Init("Iron Chassis\nVehicles are 25% more durable.",                      "Железное шасси\nТранспортные средства на 25% прочнее."));
	d.set("SteelChassis",           Init("Steel Chassis\nVehicles are 35% more durable.",                     "Стальное шасси\nТранспортные средства на 35% прочнее."));
	d.set("TorsionWinch",           Init("Torsion Winch\nSeige vehicles fire projectiles 35% farther.",       "Закрученная лебедка\nОсадные орудия стреляют снарядами на 35% дальше."));
	d.set("SeigeCrank",             Init("Seige Crank\nSeige vehicles fire 25% faster",                       "Рукоять для осадного орудия\nОсадные орудия стреляют на 25% быстрее."));
	d.set("Regeneration",           Init("Regeneration\nSurvivors heal two hearts every day.",                "Регенерация I\nВыжившие исцеляют два сердца каждый день."));
	d.set("RegenerationII",         Init("Regeneration II\nSurvivors heal four hearts every day.",            "Регенерация II\nВыжившие исцеляют четыре сердца каждый день"));
	d.set("RegenerationIII",        Init("Regeneration III\nSurvivors heal six hearts every day.",            "Регенерация III\nВыжившие исцеляют шесть сердца каждый день."));
	d.set("ThermalArmor",           Init("Thermal Armor\nWearing a full set of armor nullifies fire damage.", "Огнеупорная броня\nНошение полного комплекта брони сводит на нет урон от огня."));
	d.set("SwiftBearings",          Init("Swift Bearings\nGround vehicles move 30% faster.",                  "Подшипники\nНаземный транспорт движется на 30% быстрее."));
	d.set("Chainmail",              Init("Chainmail\nKnights take 25% less damage.",                          "Кольчуга\nРыцари получают на 25% меньше урона."));
	d.set("LightSwords",            Init("Light Swords\nUsing a sword is faster.",                            "Легкие мечи\nВзмах меча становится быстрее."));
	d.set("Production",             Init("Production\nFactories +25% production speed.",                      "Производство I\nЗаводы получают +25% к скорости производства."));
	d.set("ProductionII",           Init("Production II\nFactories +25% production speed.",                   "Производство II\nЗаводы получают +25% к скорости производства."));

	//scoreboard
	d.set("ZF",                     Init("Zombie Fortress",               "Zombie Fortress"));
	d.set("DayNum",                 Init("Day: {DAYS}",                   "День: {DAYS}"));
	d.set("Zombies",                Init("Zombies: {AMOUNT}",             "Нежити: {AMOUNT}"));
	d.set("Survivors",              Init("Survivors",                     "Выжившие"));
	d.set("TotalKills",             Init("Total Kills: {INPUT}",          "Всего убийств: {INPUT}"));
	d.set("AllTimeRecord",          Init("All-time record: {INPUT} Days", "Нынешний рекорд: {INPUT} дней"));
	d.set("Scoreboard",             Init("Scoreboard",                    ""));

	//statistics
	d.set("Statistics",             Init("Statistics",                 ""));
	d.set("Statistic",              Init("Statistic",                  ""));
	d.set("CurrentGame",            Init("Current Game",               ""));
	d.set("AllTime",                Init("All Time",                   ""));
	d.set("StatUndeadKilled",       Init("Undead Killed",              ""));
	d.set("StatDeaths",             Init("Deaths",                     ""));
	d.set("StatPlayTime",           Init("Play Time",                  ""));
	d.set("StatWoodBlocks",         Init("Wood Blocks Placed",         ""));
	d.set("StatStoneBlocks",        Init("Stone Blocks Placed",        ""));
	d.set("StatIronBlocks",         Init("Iron Blocks Placed",         ""));
	d.set("StatDirtBlocks",         Init("Dirt Blocks Placed",         ""));
	d.set("StatBlocks",             Init("Blocks Placed",              ""));
	d.set("StatSpikes",             Init("Spikes Placed",              ""));
	d.set("StatDoors",              Init("Doors Placed",               ""));
	d.set("StatLadders",            Init("Ladders Placed",             ""));
	d.set("StatPlatforms",          Init("Platforms Placed",           ""));
	d.set("StatTrapBlocks",         Init("Trap Blocks Placed",         ""));
	d.set("StatComponents",         Init("Components Placed",          ""));
	d.set("StatBuildings",          Init("Buildings Placed",           ""));
	d.set("StatFactories",          Init("Factories Setup",            ""));
	d.set("StatFood",               Init("Food Eaten",                 ""));
	d.set("StatScrolls",            Init("Scrolls Used",               ""));
	d.set("StatTechs",              Init("Technologies Researched",    ""));
	d.set("StatEnchants",           Init("Items Enchanted",            ""));
	d.set("StatBombs",              Init("Bombs Used",                 ""));
	d.set("StatWaterBombs",         Init("Water Bombs Used",           ""));
	d.set("StatKegs",               Init("Kegs Used",                  ""));
	d.set("StatMolotovs",           Init("Molotovs Used",              ""));
	d.set("StatArrows",             Init("Arrows Shot",                ""));
	d.set("StatFireArrows",         Init("Fire Arrows Shot",           ""));
	d.set("StatWaterArrows",        Init("Water Arrows Shot",          ""));
	d.set("StatBombArrows",         Init("Bomb Arrows Shot",           ""));
	d.set("StatMolotovArrows",      Init("Molotov Arrows Shot",        ""));
	d.set("StatFireworks",          Init("Fireworks Launched",         ""));
	d.set("StatGuns",               Init("Guns Fired",                 ""));
	d.set("StatBolts",              Init("Bolts Shot",                 ""));
	d.set("StatCannons",            Init("Cannons Fired",              ""));

	//achievements   -   if you are here to cheat and see what the hidden achievements are, kys
	d.set("Achievements",           Init("Achievements",                                                                           ""));
	d.set("AchievementCompleted",   Init("Achievement Completed:",                                                                 ""));
	d.set("Surviving",              Init("Surviving\nSurvive to night 10",                                                         ""));
	d.set("Thriving",               Init("Thriving\nSurvive to night 25",                                                          ""));
	d.set("GettingDangerous",       Init("Getting Dangerous\nSurvive to night 50",                                                 ""));
	d.set("Extreme",                Init("Extreme Circumstances\nSurvive to night 75",                                             ""));
	d.set("Impossible",             Init("The Impossible\nSurvive to night 100",                                                   ""));
	d.set("Butcher",                Init("Butcher\nKill 1000 undead in a game",                                                    ""));
	d.set("Slaughter",              Init("Slaughter\nKill 5000 undead in a game",                                                  ""));
	d.set("Bloodbath",              Init("Bloodbath\nKill 10,000 undead in a game",                                                ""));
	d.set("Stonemason",             Init("Stonemason\nBuild 1500 blocks in a game",                                                ""));
	d.set("Architect",              Init("Architect\nBuild 3000 blocks in a game",                                                 ""));
	d.set("ZombieFortress",         Init("Zombie Fortress\nBuild 6000 blocks in a game",                                           ""));
	d.set("Mechanist",              Init("Mechanist\nBuild 300 components in a game",                                              ""));
	d.set("WorldRecord",            Init("World Record\nPass the server day record",                                               ""));
	d.set("NotTodayBuddy",          Init("Not Today Buddy\nDouse an ignited wraith in water",                                      ""));
	d.set("SpontaneousCombustion",  Init("Spontaneous Combustion\nInstantly explode a wraith with a fire arrow",                   ""));
	d.set("TheBoss",                Init("The Boss\nGive a worker a job",                                                          ""));
	d.set("Bookworm",               Init("Bookworm\nResearch an upgrade at the library",                                           ""));
	d.set("Librarian",              Init("Librarian\nResearch all upgrades at the library in one game",                            ""));
	d.set("GreatAwakening",         Init("The Great Awakening\nDuplicate the library",                                             ""));
	d.set("WorthATry",              Init("Worth A Try\n'Duplicate' another scroll of duplication",                                 ""));
	d.set("NarrowEscape",           Init("Narrow Escape\nTeleport out of a skelepede's jaws",                                      ""));
	d.set("PureCarnage",            Init("Pure Carnage\nVaporize 150 undead with one Scroll of Carnage",                           ""));
	d.set("SecondChance",           Init("Second Chance\nUse the scroll of resurrection on yourself",                              ""));
	d.set("Savior",                 Init("Savior\nRevive at least three players with only one scroll of resurrection",             ""));
	d.set("ReturningFromHell",      Init("Returning From Hell\nSurvive getting pulled to the void",                                ""));
	d.set("NiceTry",                Init("Nice Try\nAttempt to crate the library",                                                 ""));
	d.set("Sealed",                 Init("Sealed\nPut Sedgwick into a crate",                                                      ""));
	d.set("Kidnapper",              Init("Kidnapper\nPut the trader into a crate",                                                 ""));
	d.set("ThePrincess",            Init("The Princess\nSummon Geti",                                                              ""));
	d.set("Vandalism",              Init("Vandalism\nScare away the trader",                                                       ""));
	d.set("Industrializing",        Init("Industrializing\nSetup a factory",                                                       ""));
	d.set("Sweatshop",              Init("Sweatshop\nSetup 10 factories in a game",                                                ""));
	d.set("Piercing",               Init("Skewer\nPierce 20 undead with one ballista bolt",                                        ""));
	d.set("UhOh",                   Init("Uh Oh\nActivate a portal",                                                               ""));
	d.set("FromBadToWorse",         Init("From Bad To Worse\nHave multiple portals exist at the same time",                        ""));
	d.set("SkyDiving",              Init("Sky Diving\nGet dropped from the sky",                                                   ""));
	d.set("Snatched",               Init("Snatched\nGet grabbed by the skelepede",                                                 ""));
	d.set("HideAndSeek",            Init("Hide And Seek\nBe found hiding in a crate by a skelepede",                               ""));
	d.set("CrowdCrush",             Init("Overrun\nGet mauled by the horde",                                                       ""));
	d.set("Bucketeer",              Init("Bucketeer\nWear the bucket",                                                             ""));
	d.set("IronMan",                Init("Iron Man\nWear a full set of armor",                                                     ""));
	d.set("Pyromaniac",             Init("Pyromaniac\nScorch the world",                                                           ""));
	d.set("RipAndTear",             Init("Rip And Tear\nKill an undead with a chainsaw",                                           ""));
	d.set("ThouMayest",             Init("Thou mayest blow Thine enemies to tiny bits, in Thy mercy\nUse the holy hand grenade",   ""));
	d.set("CrowdControl",           Init("Crowd Control\nUse the shotgun",                                                         ""));
	d.set("PayloadDelivered",       Init("Payload Delivered\nFire the bazooka",                                                    ""));
	d.set("FlyingFortress",         Init("Flying Fortress\nPilot a fully weaponized armored bomber",                               ""));
	d.set("Bombardier",             Init("Bombardier\nDrop big bombs from a bomber",                                               ""));
	d.set("Plow",                   Init("Plow\nRun over a swarm of zombies with a tank",                                          ""));
	d.set("Hero",                   Init("Hero\nSave another player snatched by a skelepede",                                      ""));
	d.set("SoleSurvivor",           Init("Sole Survivor\nSurvive a night as the last player alive",                                ""));
	d.set("Juggernaut",             Init("The Juggernaut\nAttain a ridiculous amount of health",                                   ""));

	//unimplemented achievements
	d.set("Civilization",           Init("Civilization\nHarbor 15 workers all at once",                                            ""));
	d.set("PokeyPokey",             Init("Pokey Pokey\nPlace 500 spikes in one game",                                              ""));
	d.set("DragoonWarrior",         Init("Dragoon Warrior\nWear the legendary dragoon set",                                        ""));
	d.set("Imbued",                 Init("Imbued\nSuccessfully enchant an item with Tim",                                          ""));
	d.set("TheSacrifice",           Init("The Sacrifice\nYou were taken by Tim!",                                                  ""));

	//bestiary
	d.set("Bestiary",               Init("Bestiary",                                                                                                       ""));
	d.set("BestiaryNewEntry",       Init("{INPUT} added to the Bestiary",                                                                                  ""));
	d.set("BestiarySkeleton",       Init("Skeleton\nThe bare bones skeleton of a rotted corpse. They are fast and can climb structures easily.",           ""));
	d.set("BestiaryZombie",         Init("Zombie\nThe standard undead born from unfortunate disfigured souls.",                                            ""));
	d.set("BestiaryZombieKnight",   Init("Zombie Knight\nA zombie with with a hard hitting sword. ",                                                       ""));
	d.set("BestiaryGreg",           Init("Greg\nA gargoyle that sadistically enjoys dropping humans to their death.",                                      ""));
	d.set("BestiaryWraith",         Init("Wraith\nA morphed skeleton filled with a dangerous gas prone to exploding.",                                     ""));
	d.set("BestiaryDarkWraith",     Init("Dark Wraith\nA dangerous variant of the wraith with a stronger blast. They are capable of exploding in water.",  ""));
	d.set("BestiarySkelepede",      Init("Skelepede\nThis creature snatches humans and drags them to the depths to feast on them.",                        ""));
	d.set("BestiaryHorror",         Init("Horror\nA morphed variant of the zombie knight with a very deadly swing.",                                       ""));
	d.set("BestiarySpectre",        Init("Spectre\nAn apparition capable of phasing through walls to follow its prey.",                                    ""));
	d.set("BestiaryJerry",          Init("Jerry\nA rare horned variant of the dark wraith with a particularly volatile body.",                             ""));
	d.set("BestiarySedgwick",       Init("Sedgwick\nA necromancer whom attempts to break your defenses with various spells.",                              ""));
	d.set("BestiaryTrader",         Init("Trader\nThe merchant whom travels by sky to every settlement to trade. They offer scrolls of varying quality.",  ""));
	d.set("BestiaryBobert",         Init("Bobert\nA friendly undead wandering trader who shows up occasionally with rare foreign goods.",                  ""));
	d.set("BestiaryEnchanter",      Init("Tim\nA wizard who specializes in enchanting, he is capable of improving your items for a price.",                ""));
}

string name(const string&in translated)
{
	const string[]@ tokens = translated.split("\n");
	if (tokens.length == 0) return "FAILED NAME - CONSULT TRANSLATIONS";
	return tokens[0];
}

string desc(const string&in translated)
{
	const int token = translated.findFirst("\n");
	if (token == -1) return "FAILED DESCRIPTION - CONSULT TRANSLATIONS";
	return translated.substr(token + 1);
}
