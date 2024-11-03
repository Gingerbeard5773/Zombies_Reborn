// Zombie Fortress Translations

// Gingerbeard @ September 21 2024
//translated strings for zombies reborn

//todo:
//trader buy/sell strings
//item names

shared const string Translate(const string&in en, const string&in ru = "")
{
	string text_out = "";
	if (g_locale == "en") text_out = en; //english
	if (g_locale == "ru") text_out = ru; //russian 

	if (text_out.isEmpty()) text_out = en; //default to english if we dont have a translation

	return text_out;
}

namespace Translate
{
	const string

	//gamehelp
	ZF   = Translate("ZOMBIE FORTRESS",                                                     "ЗОМБИ КРЕПОСТЬ"),
	Tips = Translate("TIPS",                                                                "Советы"),
	Tip0 = Translate("Build a great castle and endure the masses of zombies!",              "Постройте вместе громадный замок,\n\nчтобы после сражаться с ордами нежити!"),
	Tip1 = Translate("When night arrives, the undead will appear at these gateways.",       "С наступленим ночи, мертвецы явятся из ворот."),
	Tip2 = Translate("A dead body will transform into a zombie after some time.",           "Тело умершего через некоторое время воскреснет,\n\nобратившись в зомби."),
	Tip3 = Translate("Use water to temporarily stop a burning wraith.",                     "Используйте воду, чтобы потушить горящего призрака."),
	Tip4 = Translate("Head shots deal additional damage.",                                  "Выстрел в голову наносит больше урона"),
	Tip5 = Translate("A trader will visit at mid-day if it can land safely.",               "Вас навестит торговец в полдень, если этот визит\n\nбудет достаточно безопасным для него."),
	Tip6 = Translate("Respawns are instant if there is no zombies during day light.",       "Ваше возрождение произойдет мгновенно,\n\nесли днём не будет зомби"),
	Tip7 = Translate("Migrants will come every other day if the undead population is low.", "Мигранты будут приходить к вам каждый день,\n\nесли численность всей нежити будет минимальной"),
	
	//scoreboard
	ZF2       = Translate("Zombie Fortress",                                  "Зомби Крепость"),
	Manual    = Translate("Press {KEY} to toggle the help manual on/off.",    "Нажмите {KEY} чтобы включить/выключить справочное руководство."),
	DayNum    = Translate("Day: {DAYS}",                                      "День: {DAYS}"),
	Zombies   = Translate("Zombies: {AMOUNT}",                                "Нежити: {AMOUNT}"),
	Survivors = Translate("Survivors",                                        "Выжившие"),
	
	//respawning
	Respawn0 = Translate("Waiting for dawn...",              "В ожидании рассвета..."),
	Respawn1 = Translate("Waiting to spawn as an undead...", "В ожидании восстания из мертвых..."),
	Respawn2 = Translate("Respawned as {INPUT}",             "Возродиться как {INPUT}"),
	Respawn3 = Translate("Spawn in the sky",                 "Появление в небе"),
	
	//global messages
	Day      = Translate("Day {INPUT}",                                                 "День {INPUT}"),
	Record   = Translate("Day {INPUT}\n\nNew record!",                                  "День {INPUT}\n\nНовый рекорд!"),
	GameOver = Translate("Game over! All players perished! You survived {INPUT} days.", "Конец игры! Все игроки погибли! Вы выжили на протяжении {INPUT} дней."),
	GameWin  = Translate("Day {INPUT} Reached! You win!",                               "День {INPUT} Достигнут! Вы победили!"),
	Trader   = Translate("A flying merchant has arrived!",                              "Прибыл летающий-торговец!"),
	Sedgwick = Translate("Sedgwick the necromancer has appeared!",                      "Некромант Седжвик только что явился!"),
	Migrant1 = Translate("A refugee has arrived!",                                      "Прибыл Беженец!"),
	Migrant2 = Translate("Refugees have arrived!",                                      "Беженцы прибывают!"),

	//stats
	Stat0 = Translate("Total zombies killed: {INPUT}",   "Количество убитых зомби: {INPUT}"),
	Stat1 = Translate("Most blocks placed: {INPUT}",     "Размещенных блоков более: {INPUT}"),
	Stat2 = Translate("Most kills: {INPUT}",             "Убито более: {INPUT}"),
	Stat3 = Translate("Most deaths: {INPUT}",            "Погибших более: {INPUT}"),
	Stat4 = Translate("All-time record: {INPUT} Days",   "Нынешний рекорд: {INPUT} Дней"),

	//scrolls
	ScrollClone    = Translate("Use this to duplicate an object you are pointing to.",                         "Использовав единоразово, он клонирует объект, на который вы указываете курсором."),
	ScrollCrate    = Translate("Use this to crate an object you are pointing at.",                             "Использовав единоразово, запечатывает в ящик объект на который вы указываете курсором."),
	ScrollFish     = Translate("Use this to summon a shark.",                                                  "Использовав единоразово, вы призываете морское существо - акулу."),
	ScrollFlora    = Translate("Use this to create plants nearby.",                                            "Использовав единоразово, рядом с вами вырвутся из под земли плодородные растения."),
	ScrollFowl     = Translate("Use this to summon a flock of chickens.",                                      "Использовав единоразово, вы призываете стадо кур."),
	ScrollRevive   = Translate("Use this near a dead body to ressurect them.\nCan auto-resurrect the holder.", "Используйте этот свиток рядом с мертвым телом, чтобы воскресить его.\nАвтоматически воскрешает владельца."),
	ScrollRoyalty  = Translate("Use this to summon a geti.",                                                   "Использовав единоразово, вы призавете Гети."),
	ScrollSea      = Translate("Use this to generate a source of water.",                                      "Использовав единоразово, создает под вами источник воды."),
	ScrollTeleport = Translate("Use this to teleport to the area you are pointing to.",                        "Использовав единоразово, телепортирует вас туда, куда вы указали курсором."),
	ScrollStone    = Translate("Use this to convert nearby stone into thick stone.",                           "Использовав единоразово, превращает обычную почву рядом с вами в жилы камня."),
	ScrollWisent   = Translate("Use this to summon a bison.",                                                  "Использовав единоразово, вы призываете сухопутное существо - бизона."),
	ScrollHealth   = Translate("Use this to heal yourself and others around you.",                             "Использовав единоразово, придает жизненную силу, исцеляя вас и всех окружающих."),
	ScrollRepair   = Translate("Use this to repair everything around you.",                                    "Использовав единоразово, ремонтирует строения и блоки, а также все что окружает вас."),
	ScrollCreation = Translate("Use this to magically construct a structure from thin air.",                   "Использовав единоразово, волшебным образом сооружает строение из воздуха."),
	ScrollEarth    = Translate("Use this to fill in dirt background with dirt.",                               "Использовав единоразово, заполняет раскопанные блоки почвы."),
	ScrollChaos    = Translate("Use this to ???.",                                                             "Использовав единоразово, свиток не является определенным и может оказаться непредсказуемым."),

	//builder
	IronBlock      = Translate("Iron Block\nResistant to explosions.",                  "Железный Блок\nВзрывоустойчивый Блок."),
	IronBlockBack  = Translate("Back Iron Wall\nDurable Support.",                      "Железная Стена\nПрочная опора."),
	IronDoor       = Translate("Iron Door\nPlace next to walls.",                       "Железная Дверь\nСтавьте в проем стены, или прилегая к блоку."),
	IronPlatform   = Translate("Iron Platform\nOne way platform",                       "Железная Платформа\nОдносторонняя платформа."),
	IronSpikes     = Translate("Iron Spikes\nDurable spikes",                           "Железные шипы\nПрочные шипы."),
	Windmill       = Translate("Wind Mill\nA grain mill for producing flour.",          "Мельница\nЗерновая мельница для производства муки."),
	Kitchen        = Translate("Kitchen\nCreate various foods for healing.",            "Кухня\nГотовьте различную еду для восстановления здоровья и сил."),
	Forge          = Translate("Forge\nSmelt raw ore into ingots.",                     "Плавильня\nПереплавляют сырую руду в слитки."),
	Nursery        = Translate("Nursery\nA plant nursery for agricultural purposes.",   "Рассадник\nРассадник для сельскохозяйственных культур."),
	Armory         = Translate("Armory\nBuild weapons and change your class.",          "Оружейная\nИспользуя слитки выковывайте оружие, так же вы можете поменять свой класс."),
	Library        = Translate("Library\nA place of study to obtain new technologies.", "Библиотека\nМесто хранения знаний и открытий, здесь можно освоить новые технологии."),
	
	//workers
	AssignWorker   = Translate("Assign Worker",                    "Назначить Рабочего"),
	UnassignWorker = Translate("Unassign Worker",                  "Уволить Рабочего"),
	WorkerRequired = Translate("Requires a worker",                "Требуется Рабочий"),
	RestWorker     = Translate("Rest Worker",                      "Отдыхающий Рабочий"),
	RecruitWorker  = Translate("Recruit a worker for your needs.", "Наймите работника для своих нужд."),
	
	//generic
	PullItems      = Translate("Take items from other storages", "Извлекать предметы\nБерет предметы из других хранилищ."),
	AddFuel        = Translate("Add fuel (Wood or Coal)",        "Добавить топлива\nДобавляет дерево или уголь в качестве топлива."),
	Recipes        = Translate("Recipes",                        "Рецепты\nСписок всех доступных рецептов."),
	SetRecipe      = Translate("Set Recipe",                     "Выбрать рецепт\nИспользует выбранный рецепт."),
	CurrentRecipe  = Translate("Current Recipe",                 "Нынешний рецепт\nНынешний выбранный рецепт."),
	Equip          = Translate("Equip {ITEM}",                   "Оснастить {ITEM}"),
	Unequip        = Translate("Unequip {ITEM}",                 "Снять {ITEM}"),

	//building
	Factory        = Translate("A generic factory for various items. Requires a free worker to produce items.", "Общая фабрика для различных вещей. Требуется свободный рабочий для изготовления предметов."),
	Dormitory      = Translate("A dorm for recruiting and healing workers. Functions as a respawn point.",      "Общежитие для набора и лечения рабочих. Это также, место для возрождения и новоприбывших."),

	//vehicleshop
	Bomber         = Translate("A balloon capable of flying. Allows attachments. Press [Space] to drop bombs.",       "Воздушный шар, способный летать. Позволяет устанавливать навесное оборудование. Нажмите [Пробел], чтобы сбросить бомбы."),
	Armoredbomber  = Translate("A balloon with protective plating. Allows attachments. Press [Space] to drop bombs.", "Воздушный шар с защитным покрытием. Позволяет устанавливать навесное оборудование. Нажмите [Пробел], чтобы сбросить бомбы."),
	Mountedbow     = Translate("A portable arrow-firing death machine. Can be attached to some vehicles.",            "Переносная стреляющая стрелами механизм смерти. Может быть установлена на некоторые транспортные средства."),
	Tank           = Translate("A seige tank. Allows attachments.",                                                   "Осадный танк. Позволяет устанавливать навесное оборудование."),
	LightBallista  = Translate("A portable ballista. Can be attached to some vehicles.",                              "Передвижная баллиста. Может устанавливаться на некоторые транспортные средства."),
	Cannon         = Translate("A cannon that is capable of obliterating any foe. Can be attached to some vehicles.", "Пушка, способная уничтожить любого противника. Может устанавливаться на некоторые транспортные средства."),
	Zeppelin       = Translate("A sky fortress with many accomodations on board. Functions as a respawn point.",      "Небесная крепость с множеством жилых помещений на борту. Служит точкой возрождения."),

	//archershop
	MolotovArrows  = Translate("Molotov arrows to incinerate the enemy.",   "Стрелы Молотова, испепеляющие врага."),
	FireworkArrows = Translate("Firework rockets. Explodes where you aim.", "Фейерверки. Взрывается там, куда вы целитесь."),

	//kitchen
	Bread          = Translate("Bread\nDelicious crunchy whole-wheat bread.", "Хлеб\nВкусный хрустящий хлеб из цельнозерновой муки."),
	Cake           = Translate("Cake\nFluffy cake made from egg and wheat.",  "Пирог\nПышный пирог из яиц и пшеницы."),
	Cookedfish     = Translate("Cooked Fish\nA cooked fish on a stick.",      "Приготовленная Рыба\nПриготовленная рыба на палочке."),
	Cookedsteak    = Translate("Cooked Steak\nA meat chop with sauce.",       "Пригоитовленый Стейк\nОтбивная с соусом."),
	Burger         = Translate("Burger\nSeared meat in a bun!",               "Бургер\nОбжареное мясо в булочке!"),

	//forge
	IronIngot      = Translate("Iron Ingot\nCan be used to create weapons and equipment",         "Железный слиток\nМожно использовать для создания оружия и снаряжения."),
	CharCoal       = Translate("Coal\nCan be used for fuel or be used to refine steel.",          "Уголь\nМожно использовать в качестве топлива или для очистки стали."),
	SteelIngot     = Translate("Steel Ingot\nCan be used to create strong weapons and equipment", "Стальной слиток\nМожно использовать для создания прочного оружия и снаряжения."),

	//armory
	Scythe         = Translate("Scythe\nA tool for cutting crops fast.\nAllows for grain auto-pickup.",                 "Коса\nИнструмент для быстрого срезания урожая.\nПозволяет поднямать зерна автоматически."),
	Crossbow       = Translate("Crossbow\nFires any arrow type.\nHold right mouse button to reload.",                   "Арбалет\nСтреляет Любыми стрелами\nЗажмите ПКМ, чтобы перезарядить."),
	Musket         = Translate("Musket\nFires musket balls.\nHold right mouse button to reload.",                       "Мушкет\nСтреляет патронами для Мушкета.\nЗажмите ПКМ, чтобы перезарядить."),
	MusketBalls    = Translate("Musket Balls\nAmmunition for the Musket.",                                              "Пули Мушкета\nПатроны для Мушкета"),
	Chainsaw       = Translate("Chainsaw\nCuts through wood fast.",                                                     "Бензопила\nРежет дерево быстрее."),
	Molotov        = Translate("Molotov\nA flask of fire which can be thrown at the enemy. Press [Space] to activate.", "Молотов\nФляга с горючей жидкостью которую можно бросить во врага. Нажмите [Space] для активации."),
	ScubaGear      = Translate("Scuba Gear\nAllows breathing under water.",                                             "Акваланг\nПозволяет дышать под водой."),
	HeadLamp       = Translate("Head Lamp\nWearable lantern for easy illumination!",                                    "Головной фонарь\nПереносной фонарь для легкого освещения!"),
	SteelDrill     = Translate("Steel Drill\nA strong drill that can mine for an extended length of time.",             "Стальной бур\nМощный бур, способный вести добычу в течение длительного времени."),
	SteelHelmet    = Translate("Steel Helmet\nA durable helmet to protect your head.",                                  "Стальной шлем\nПрочный шлем для защиты вашей головы."),
	SteelArmor     = Translate("Steel Chestplate\nA durable chestplate to protect your body.",                          "Стальной нагрудник\nПрочная нагрудная пластина для защиты вашего тела."),
	Backpack       = Translate("Backpack\nA backpack to carry your belongings.",                                        "Рюкзак\nРюкзак для переноски ваших вещей."),
	Parachutepack  = Translate("Parachute Pack\nAllows you to fall slowly. Press [Shift] to activate.",                 "Парашютный ранец\nПозволяет вам медленно падать. Нажмите [Shift] для активации."),

	//trader
	TradeScrollCarnage  = Translate("Sedgwick really doesn't want me to have this.",            "Седжвик действительно не хочет чтобы это было у меня."),
	TradeScrollMidas    = Translate("Makes the rocks shiny.",                                   "Придает камням блеск."),
	TradeScrollSea      = Translate("A powerful spell known to flood entire villages.",         "Мощное заклинание, способное затопить целые деревни."),
	TradeScrollTeleport = Translate("This one can take you anywhere.",                          "Этот доставит вас куда угодно."),
	TradeScrollStone    = Translate("If you need rocks.",                                       "Если вам нужны камни."),
	TradeScrollRevive   = Translate("Bring back a friend of yours, or maybe even yourself.",    "Воскрешает вашего друга или, может быть, даже вас самих."),
	TradeScrollCrate    = Translate("It can put anything in a box, somehow.",                   "Каким-то образом он может поместить в коробку все, что угодно."),
	TradeScrollDupe     = Translate("Long lost magic that appears to make a copy of anything!", "Давно утраченная магия, которая, кажется, создает копию чего угодно!"),
	TradeScrollDrought  = Translate("Vaporizes bodies of water.",                               "Испаряет водоемы."),
	TradeScrollFlora    = Translate("Creates various plants from thin air.",                    "Создает различные растения из воздуха."),
	TradeScrollRoyalty  = Translate("I forgot what this one did.",                              "Я забыл, что он делает."),
	TradeScrollWisent   = Translate("Summons a bison. Good for meat!",                          "Вызывает бизона. Отлично подходит для забива на мясо!"),
	TradeScrollFowl     = Translate("If you need some eggs.",                                   "Если вам нужно немного яиц."),
	TradeScrollFish     = Translate("Summons a bloodthirsty shark.",                            "Вызывает кровожадную акулу."),
	TradeScrollHealth   = Translate("This one can heal even the worst injuries.",               "Это может залечить даже самые тяжелые травмы."),
	TradeScrollRepair   = Translate("This one will fix up whatever is nearby!",                 "Этот починит все, что находится поблизости!"),

	//library
	Researching     = Translate("Researching - {PERCENT}",      "Исследование - {PERCENT}"),
	Paused          = Translate("Paused - {PERCENT}",           "Остановлено - {PERCENT}"),
	Resume          = Translate("Click to resume",              "Нажмите, чтобы продолжить"),
	Completed       = Translate("Completed",                    "Завершенно"),
	RequiresTech    = Translate("Requires previous technology", "Требуется предыдущая\nтехнология"),
	TechComplete    = Translate("{TECH} technology complete",   "{TECH} технология завершена"),
	ResearchTime    = Translate("Research time: {TIME} days",   "Время исследования: {TIME} Дней"),

	//technology
	Coinage         = Translate("Coinage\nCoins auto-yield 10%.",                                    "Чеканка монет I\nДоход монет составляет 10%."),
	CoinageII       = Translate("Coinage II\nCoins auto-yield 20%.",                                 "Чеканка монет II\nДоход монет составляет 20%."),
	CoinageIII      = Translate("Coinage III\nCoins auto-yield 30%.",                                "Чеканка монет III\nДоход монет составляет 30%."),
	HardyWheat      = Translate("Hardy Wheat\nWheat can grow on stone and ores.",                    "Здоровая Пшеница\nПшеница может расти на камнях и рудах."),
	HardyTrees      = Translate("Hardy Trees\nTrees can grow on stone and ores.",                    "Здоровые Деревья\nДеревья могут расти на камне и рудах."),
	PlentifulWheat  = Translate("Plentiful Wheat\nWheat can yield an extra grain.",                  "Обилие пшеницы\nПшеница может дать дополнительное зерно."),
	Metallurgy      = Translate("Metallurgy\n Forging time reduced by 15%.",                         "Металлургия I\nВремя плавления сокращено на 15%."),
	MetallurgyII    = Translate("Metallurgy II\nForging time reduced by 25%.",                       "Металлургия II\nВремя плавления сокращено на 25%."),
	MetallurgyIII   = Translate("Metallurgy III\nForging time reduced by 35%.",                      "Металлургия III\nВремя плавления сокращено на 35%."),
	MetallurgyIV    = Translate("Metallurgy IV\nForging time reduced by 50%.",                       "Металлургия IV\nВремя плавления сокращено на 50%."),
	Refinement      = Translate("Refinement \nForging has a 10% chance to yield an extra ingot.",    "Кузнечество I\nВероятность получения дополнительного слитка при ковке составляет 10%."),
	RefinementII    = Translate("Refinement II\nForging has a 20% chance to yield an extra ingot.",  "Кузнечество II\nВероятность получения дополнительного слитка при ковке составляет 20%."),
	RefinementIII   = Translate("Refinement III\nForging has a 30% chance to yield an extra ingot.", "Кузнечество III\nВероятность получения дополнительного слитка при ковке составляет 30%."),
	RefinementIV    = Translate("Refinement IV\nForging has a 40% chance to yield an extra ingot.",  "Кузнечество IV\nВероятность получения дополнительного слитка при ковке составляет 40%."),
	Extraction      = Translate("Extraction \nQuarrys have a chance to yield iron ore.",             "Добыча Ископаемых I\nИз Карьера есть шанс добыть железную руду."),
	ExtractionII    = Translate("Extraction II\nQuarrys have a chance to yield gold ore.",           "Добыча Ископаемых II\nИз Карьера есть шанс получить золотую руду."),
	Milling         = Translate("Milling\nWind mills produce 10% more flour.",                       "Переработка Зерна I\nВетряные мельницы производят на 10% больше муки."),
	MillingII       = Translate("Milling II\nWind mills produce 20% more flour.",                    "Переработка Зерна II\nВетряные мельницы производят на 20% больше муки."),
	MillingIII      = Translate("Milling III\nWind mills produce 35% more flour.",                   "Переработка Зерна III\nВетряные мельницы производят на 35% больше муки."),
	Swords          = Translate("Sharpening Stone\nSwords deal +25% damage.",                        "Точильный Камень\nПравильно заточенные мечи наносят на +25% урона больше."),
	SwordsII        = Translate("Damascus Steel\nSwords deal +25% damage.",                          "Дамасская Сталь\nМатериал дает лезвию дополнительную остроту прибовляя +25% к урону."),
	LightArmor      = Translate("Lightweight Armor\nArmor encumbrance -50%.",                        "Сегментированная Броня\nПластичность и легкость брони увеличивает вашу скорость +50%."),
	CombatPickaxes  = Translate("Combat Pickaxes\nPickaxes deal 2x damage.",                         "Боевые Кирки\nКирки наносят дополнительный урон +1,5."),
	LightPickaxes   = Translate("Light Pickaxes\nPickaxe mining speed increased.",                   "Легкие Кирки\nСкорость добычи с помощью кирки увеличена."),
	PrecisionDrills = Translate("Precision Drilling\nDrills yield 100%.",                            "Мастерство Бурения\nПроизводительность бура достигает своего 100% пика."),
	Architecture    = Translate("Architecture\nBlock placement is faster.",                          "Каменщик\nРазмещение блоков происходит быстрее."),
	Supplies        = Translate("Supplies\n+5 stone, +10 wood per resupply.",                        "Снабжение I\n+5 камней, +10 досок к снабжению."),
	SuppliesII      = Translate("Supplies II\n+5 stone, +10 wood per resupply.",                     "Снабжение II\n+5 камней, +10 досок к снабжению."),
	SuppliesIII     = Translate("Supplies III\n+10 stone, +10 wood per resupply.",                   "Снабжение III\n+10 камней, +10 досок к снабжению."),
	Repeaters       = Translate("Repeaters\nCrossbows are automatic.",                               "Повторители\nАвтоматизирует Арбалеты"),
	LightBows       = Translate("Light Bows\nArchers fire faster.",                                  "Легкие Луки\nЛучники стреляют быстрее."),
	DeepQuiver      = Translate("Deep Quiver\nArchers have infinite arrows.",                        "Глубокие Колчаны\nУ лучников нескончаемое количество стрел"),
	MachineBows     = Translate("Machine Bows\nMounted Bows fire faster.",                           "Механизированные Луки\nУстановки стреляют быстрее."),
	FastBurnPowder  = Translate("Fast-Burning Powder\nMuskets' +25% damage.",                        "Быстросгорающий Порох\nУрон от мушкетов возрастает до +25%."),
	HeavyLead       = Translate("Heavy Lead\nMuskets' +45% damage.",                                 "Тяжелый Свинец\nУрон от мушкетов увеличивается на 45%."),
	RifledBarrels   = Translate("Rifled Barrels\nMuskets' penetration increased.",                   "Нарезные Стволы\nПробиваемость ружей увеличилась."),
	Bandoliers      = Translate("Bandoliers\nMuskets' reload twice as fast.",                        "Патронташи\nМушкеты перезаряжаются в два раза быстрее."),
	GreekFire       = Translate("Greek Fire\nIncendiary weapons deal +50% damage.",                  "Греческий огонь\nВоспламеняющее оружие наносит +50% урона."),
	Shrapnel        = Translate("Shrapnel\nExplosives +25% damage.",                                 "Шрапнель I\nВзрывы наносят +25% урона."),
	ShrapnelII      = Translate("Shrapnel II\nExplosives +25% damage.",                              "Шрапнель II\nВзрывы наносят +25% урона."),
	HighExplosives  = Translate("High Explosives\nExplosives' radius increased.",                    "Взрывчатое Вещество\nРадиус действия взрывчатки увеличился."),
	HolyWater       = Translate("Holy Water\nWater bomb radius and stun time 2x.",                   "Святая Вода\nРадиус действия водяной бомбы и время оглушения увеличиваются в 2 раза."),
	BlastShields    = Translate("Blast Shields\nShields are resistant to strong explosions.",        "Взрывоустойчивые Щиты\nЩиты устойчивы к сильным взрывам."),
	FlightTuning    = Translate("Flight Tuning\nAerial vehicles fly 25% faster.",                    "Регулировка Полёта\nЛетательные аппараты летают на 25% быстрее."),
	IronChassis     = Translate("Iron Chassis\nLand vehicles are 25% more durable.",                 "Железное Шасси\nНаземные транспортные средства на 25% крепче."),
	SteelChassis    = Translate("Steel Chassis\nLand vehicles are 35% more durable.",                "Стальное Шасси\nНаземные транспортные средства на 35% крепче."),
	TorsionWinch    = Translate("Torsion Winch\nSeige vehicles fire projectiles 35% farther.",       "Закрученная Лебедка\nШтурмовые машины стреляют снарядами на 35% дальше."),
	SeigeCrank      = Translate("Seige Crank\nSeige vehicles fire 25% faster",                       "Заводная Ручка\nОсадные машины стреляют на 25% быстрее."),
	Regeneration    = Translate("Regeneration\nSurvivors heal half a heart every day.",              "Восстановление I\nВыжившие исцеляют половину сердца каждый день."),
	RegenerationII  = Translate("Regeneration II\nSurvivors heal one heart every day.",              "Восстановление II\nВыжившие исцеляют по одному сердцу каждый день."),
	RegenerationIII = Translate("Regeneration III\nSurvivors heal two hearts every day.",            "Восстановление III\nВыжившие исцеляют два сердца каждый день.");
}
