-------------------------------------------
--- AddOn: ReadySetDing					---
--- Author: Ketho (EU-Boulderfist)		---
--- Created: 2010.01.10					---
--- License: Public Domain				---
--- Version: v0.93	[2011.10.18]		---
-------------------------------------------
--- Curse			http://wow.curse.com/downloads/wow-addons/details/readysetding.aspx
--- WoWInterface	http://www.wowinterface.com/downloads/info16220-ReadySetDing.html

--- To Do:
-- guild member levels scroll window
-- "backend" module/library, grab info every level, like: Item Level, Player Stats, etc; experience calculating
-- "frontend" frame with info
-- Optimization: purge non-existing characters
-- clean up, move stuff into individual files

local VERSION = 0.93
local FILETYPE = "Release"

ReadySetDing = LibStub("AceAddon-3.0"):NewAddon("ReadySetDing", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
local RSD = ReadySetDing
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ReadySetDing", true)
local LDB = LibStub("LibDataBroker-1.1")

local _G = _G
-- Lua APIs
local print = print
local pairs, select, type = pairs, select, type
local tonumber, unpack = tonumber, unpack
local floor, mod, random = floor, mod, random
local date, time = date, time
local strtrim = strtrim
local format, gsub = format, gsub
local table_maxn = table.maxn

-- WoW APIs
local SCM, GS, PSF = SendChatMessage, GetStatistic, PlaySoundFile
local IsInGuild, GuildRoster, GetGuildRosterInfo = IsInGuild, GuildRoster, GetGuildRosterInfo
local GetNumFriends, GetFriendInfo = GetNumFriends, GetFriendInfo
local BNGetNumFriends, BNGetFriendInfo, BNGetToonInfo = BNGetNumFriends, BNGetFriendInfo, BNGetToonInfo

-- modified globalstrings
local ADVANCED = gsub(ADVANCED_LABEL, "|T.-|t", "") -- remove image
local LANGUAGES_LABEL = gsub(LANGUAGES_LABEL, "|T.-|t", "")
local TIME_PLAYED_TOTAL = gsub(TIME_PLAYED_TOTAL, "%%s", "|cff71D5FF%%s|r") -- add coloring
local TIME_PLAYED_LEVEL = gsub(TIME_PLAYED_LEVEL, "%%s", "|cff71D5FF%%s|r")

-- localized class names
local revLOCALIZED_CLASS_NAMES = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	revLOCALIZED_CLASS_NAMES[v] = k
end
for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	revLOCALIZED_CLASS_NAMES[v] = k
end

-- table reference shortcuts
local profile, realm, char
local stats

-- other
local playerDinged

local TPM_total, TPM_current = 0, 0		-- event vars
local TPM_total2, TPM_current2			-- backup event vars

local levelTime							-- accurate time on Levelup
local currentTime, totalTime = 0, 0		-- estimated Time

local filterPlayed						-- used for filtering ReadySetDing's /played requests
local isStopwatch						-- eligible for using the Blizzard Stopwatch

local timeLogin = time()
local lastPlayed = time()				-- timestamp of last /played request

local function AddedTime()
	return time() - lastPlayed
end

local timeAFK1, timeAFK2
local randomIcon1, randomIcon2
local soundPath, showedDiffs

local D_SECONDS = strlower(D_SECONDS)
local D_MINUTES = strlower(D_MINUTES)
local D_HOURS = strlower(D_HOURS)
local D_DAYS = strlower(D_DAYS)

-- don't want the capitalized GlobalStrings (except for German)
if GetLocale() == "deDE" then
	D_SECONDS = _G.D_SECONDS
	D_MINUTES = _G.D_MINUTES
	D_HOURS = _G.D_HOURS
	D_DAYS = _G.D_DAYS
end

local bttn = CreateFrame("Button")
local D_MINUTES2 = gsub(D_MINUTES, "%%d", "%%.1f") -- replace decimal integer with float
local HOUR = gsub(bttn:GetText(bttn:SetFormattedText(_G.D_HOURS, 1)), "1 ", "") -- singular hour
local MINUTES1 = gsub(bttn:GetText(bttn:SetFormattedText(D_MINUTES, 2)), "2 ", "") -- plural minutes
local MINUTES2 = gsub(bttn:GetText(bttn:SetFormattedText(_G.D_MINUTES, 2)), "2 ", "")

local cropped = ":64:64:4:60:4:60"
local RT = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"

-- long string is long
local legend, legend2, legend3
do
	local x1 = "\n|cff58ACFA[QUESTS]|r |cffFFFFFF= "..QUESTS_LABEL.."|r\n|cff58ACFA[ZONE]|r |cffFFFFFF= "..strupper(strsub(SPELL_TARGET_TYPE6_DESC, 1, 1))..strsub(SPELL_TARGET_TYPE6_DESC, 2).."|r\n|cffF6ADC6[LEVEL-]|r |cffFFFFFF= "..L["Previous Level"].."|r\n|cffF6ADC6[LEVEL]|r |cffFFFFFF= "..L["New Level"].."|r\n|cffF6ADC6[REM]|r |cffFFFFFF= "..L["Remaining Levels"].."|r"
	local x2 = "\n|cffF6ADC6[MAX]|r |cffFFFFFF= "..L["Max Level"].."|r\n|cff71D5FF[TIME]|r |cffFFFFFF= "..L["Level Time"].."|r\n|cff71D5FF[TOTAL]|r |cffFFFFFF= "..L["Total Time"].."|r\n|cff71D5FF[DIFF]|r |cffFFFFFF= "..L["Difference"].."|r\n|cff71D5FF[AFK]|r, |cff71D5FF[AFK+]|r |cffFFFFFF= "..L["AFK Time"].."|r"
	local x3 = "\n|cffB6CA00[XP]|r |cffFFFFFF= "..COMBAT_XP_GAIN.." "..SPEED.."|r\n|cffB6CA00[SPEED]|r |cffFFFFFF= "..L["Level Speed"].."|r\n|cffB6CA00[SPEED+]|r |cffFFFFFF= "..L["Average Level Speed"].."|r\n|cff0070DD[DATE]|r  |cffFFFFFF= MM/DD/YY hh:mm|r\n|cff0070DD[DATE2]|r |cffFFFFFF= YYYY.MM.DD hh:mm|r"
	local x4 = "\n|cffFF0000[KILLS]|r, |cffFF0000[KILLS+]|r |cffFFFFFF= "..KILLS.."|r\n|cffFF0000[DEATHS]|r, |cffFF0000[DEATHS+]|r |cffFFFFFF= "..DEATHS.."|r\n|cffADFF2F[NAME]|r, |cffADFF2F[CLASS]|r, |cffADFF2F[RACE]|r, |cffADFF2F[GUILD]|r, |cffADFF2F[FACTION]|r, |cffADFF2F[REALM]|r\n"..TARGETICONS..": |cffFFFFFF{rt5} |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:12|t|r"
	
	local y1 = "\n|cff71D5FF[NAME]|r |cffFFFFFF= "..NAME.."|r\n|cffF6ADC6[LEVEL-]|r |cffFFFFFF= "..L["Previous Level"].."|r\n|cffADFF2F[LEVEL] |cffFFFFFF= "..L["New Level"].."|r\n|cff71D5FF[CLASS]|r"
	local y2 = "|cffFFFFFF= "..CLASS.."|r\n|cffADFF2F[RANK]|r |cffFFFFFF= "..RANK.."|r\n|cffF6ADC6[ZONE]|r |cffFFFFFF= "..ZONE.."|r\n|cff71D5FF[TIME]|r |cffFFFFFF=|r |cffF6ADC6RealTime|r\n|cffB6CA00[SPEED]|r |cffFFFFFF= "..L["Level Speed"].."|r"

	legend = x1..x2..x3..x4
	legend2 = y1..y2
end

local soundExamples = {
	"Interface\\AddOns\\ReadySetDing\\Sounds\\mysound.mp3",
	"|cffF6ADC6Random|r",
	"Sound\\Interface\\LevelUp.ogg",
	"sound\\INTERFACE\\UI_GuildLevelUp.ogg",
	"Sound\\Interface\\iQuestComplete.ogg",
	"Sound\\Spells\\Resurrection.ogg",
	"Sound\\Doodad\\BellTollAlliance.ogg",
	"sound\\CREATURE\\MANDOKIR\\VO_ZG2_MANDOKIR_LEVELUP_EVENT_01.ogg",
	"sound\\CREATURE\\JINDO\\VO_ZG2_JINDO_MANDOKIR_LEVELS_UP_01.ogg",
	"Sound\\character\\BloodElf\\BloodElfFemaleCongratulations02.ogg",
	"Sound\\character\\Human\\HumanVocalFemale\\HumanFemaleCongratulations01.ogg",
	"Sound\\character\\NightElf\\NightElfVocalFemale\\NightElfFemaleCongratulations01.ogg",
	"Sound\\character\\Orc\\OrcVocalMale\\OrcMaleCheer01.ogg",
	"Sound\\creature\\Peon\\PeonPissed3.ogg",
	"Sound\\creature\\HoodWolf\\HoodWolfTransformPlayer01.ogg",
	"Sound\\creature\\Illidan\\BLACK_Illidan_04.ogg",
	"Sound\\creature\\LichKing\\IC_Lich King_FMAttack01.ogg",
	"Sound\\Music\\ZoneMusic\\DMF_L70ETC01.mp3",
}

local gratzMsg = {"gz", "gz!", "GZ", "grats", "gratz"}
local smilieMsg = {":)", ";)", "=)", "=]", "8)", ":p", ":P", ";D", "^^", "^_^", "(n_n)"}

local optionsFrame = {}

-- internal cooldowns array
local cd = {}

local player = {
	realm = GetRealmName(),
	faction = select(2, UnitFactionGroup("player")),
	class = UnitClass("player"),
	race = UnitRace("player"),
	level = UnitLevel("player"),
	name = UnitName("player"),
	XPMax = UnitXPMax("player"),
	maxLevel = 85,
}

local AchievementBlacklist = {
-- General
	[522] = true, -- [Somebody Likes Me]
	[545] = true, -- [Shave and a Haircut]
	[546] = true, -- [Safe Deposit]
	[557] = true, -- [Superior]
	[558] = true, -- [Greedy]
	[556] = true, -- [Epic]
	[621] = true, -- [Represent]
	[964] = true, -- [Going Down?]
	[1017] = true, -- [Can I Keep Him?]
	[2716] = true, -- [Dual Talent Specialization]
-- Profession
	[116] = true, -- [Professional Journeyman]
	[731] = true, -- [Professional Expert]
	[732] = true, -- [Professional Artisan]
	[733] = true, -- [Professional Master]
	[734] = true, -- [Professional Grand Master]
-- Fishing
	[153] = true, -- [The Old Gnome and the Sea]
	[1556] = true, -- [25 Fish]
	[1557] = true, -- [50 Fish]
	[1558] = true, -- [100 Fish]
-- Riding
	[891] = true, -- [Giddy Up!]
	[889] = true, -- [Fast and Furious]
-- PvP
	[223] = true, -- [The Sickly Gazelle]
	[227] = true, -- [Damage Control]
	[229] = true, -- [The Grim Reaper]
	[245] = true, -- [That Takes Class]
	[246] = true, -- [Know Thy Enemy] (A)
	[247] = true, -- [Make Love, Not Warcraft]
	[700] = true, -- [Freedom of the Horde]
	[701] = true, -- [Freedom of the Alliance]
	[1005] = true, -- [Know Thy Enemy] (H)
	[1157] = true, -- [Duel-icious]

	[238] = true, -- [An Honorable Kill]
	[513] = true, -- [100 Honorable Kills]
	[515] = true, -- [500 Honorable Kills]
	[516] = true, -- [1000 Honorable Kills]

	[154] = true, -- [Arathi Basin Victory]
	[166] = true, -- [Warsong Gulch Victory]
	[208] = true, -- [Eye of the Storm Victory]
	[218] = true, -- [Alterac Valley Victory]
	[1308] = true, -- [Strand of the Ancients Victory]
	[1717] = true, -- [Wintergrasp Victory]
	[3776] = true, -- [Isle of Conquest Victory]
	[5245] = true, -- [Battle for Gilneas Victory]
	[5412] = true, -- [Tol Barad Victory]
-- Quests
	[503] = true, -- [50 Quests Completed]
	[504] = true, -- [100 Quests Completed]
	[973] = true, -- [5 Daily Quests Complete]
	[974] = true, -- [50 Daily Quests Complete]
	[4956] = true, -- [5 Dungeon Quests Completed]
	[4957] = true, -- [20 Dungeon Quests Completed]

	[561] = true, -- [D.E.H.T.A's Little P.I.T.A.]
	[547] = true, -- [Veteran of the Wrathgate]
	[938] = true, -- [The Snows of Northrend]
	[939] = true, -- [Hills Like White Elekk]
	[940] = true, -- [The Green Hills of Stranglethorn]
	[1576] = true, -- [Of Blood and Anguish]
	[4959] = true, -- [Beware of the 'Unbeatable?' Pterodactyl]
	[4960] = true, -- [Round Three. Fight!]
	[4961] = true, -- [In a Thousand Years Even You Might be Worth Something]
	[5318] = true, -- [20,000 Leagues Under the Sea]
	[5451] = true, -- [Consumed by Nightmare]

	[4896] = true, -- [Arathi Highlands Quests]
	[4925] = true, -- [Ashenvale Quests] (A)
	[4976] = true, -- [Ashenvale Quests] (H)
	[4927] = true, -- [Azshara Quests] (H only)
	[4900] = true, -- [Badlands Quests]
	[4909] = true, -- [Blasted Lands Quests]
	[4926] = true, -- [Bloodmyst Isle Quests] (A only)
	[4901] = true, -- [Burning Steppes Quests]
	[4905] = true, -- [Cape of Stranglethorn Quests]
	[4928] = true, -- [Darkshore Quests]
	[4930] = true, -- [Desolace Quests]
	[4907] = true, -- [Duskwood Quests] (A only)
	[4929] = true, -- [Dustwallow Marsh Quests] (H only)
	[4892] = true, -- [Eastern Plaguelands Quests]
	[4931] = true, -- [Felwood Quests]
	[4932] = true, -- [Feralas Quests] (A)
	[4979] = true, -- [Feralas Quests] (H)
	[4908] = true, -- [Ghostlands Quests] (H only)
	[4895] = true, -- [Hillsbrad Foothills Quests] (H only)
	[4897] = true, -- [Hinterlands Quests]
	[4899] = true, -- [Loch Modan Quests] (A only)
	[4933] = true, -- [Northern Barrens Quests] (H only)
	[4906] = true, -- [Northern Stranglethorn Quests]
	[4902] = true, -- [Redridge Mountains Quests] (A only)
	[4910] = true, -- [Searing Gorge Quests]
	[4934] = true, -- [Silithus Quests]
	[4984] = true, -- [Silverpine Forest Quests] (H only)
	[4937] = true, -- [Southern Barrens Quests] (A)
	[4981] = true, -- [Southern Barrens Quests] (H)
	[4936] = true, -- [Stonetalon Mountains Quests] (A)
	[4980] = true, -- [Stonetalon Mountains Quests] (H)
	[4904] = true, -- [Swamp of Sorrows Quests]
	[4935] = true, -- [Tanaris Quests]
	[4938] = true, -- [Thousand Needles Quests]
	[4939] = true, -- [Un'Goro Crater Quests]
	[4903] = true, -- [Westfall Quests] (A only)
	[4898] = true, -- [Wetlands Quests] (A only)
	[4940] = true, -- [Winterspring Quests]
-- Dungeons
	[632] = true, -- [Blackfathom Deeps]
	[642] = true, -- [Blackrock Depths]
	[628] = true, -- [Deadmines]
	[634] = true, -- [Gnomeregan]
	[644] = true, -- [King of Dire Maul]
	[643] = true, -- [Lower Blackrock Spire]
	[640] = true, -- [Maraudon]
	[629] = true, -- [Ragefire Chasm]
	[636] = true, -- [Razorfen Downs]
	[635] = true, -- [Razorfen Kraul]
	[637] = true, -- [Scarlet Monastery]
	[645] = true, -- [Scholomance]
	[631] = true, -- [Shadowfang Keep]
	[633] = true, -- [Stormwind Stockade]
	[646] = true, -- [Stratholme]
	[641] = true, -- [Sunken Temple]
	[638] = true, -- [Uldaman]
	[1307] = true, -- [Upper Blackrock Spire]
	[630] = true, -- [Wailing Caverns]
	[639] = true, -- [Zul'Farrak]

	[666] = true, -- [Auchenai Crypts]
	[647] = true, -- [Hellfire Ramparts]
	[661] = true, -- [Magister's Terrace]
	[651] = true, -- [Mana-Tombs]
	[655] = true, -- [Opening of the Dark Portal]
	[653] = true, -- [Sethekk Halls]
	[654] = true, -- [Shadow Labyrinth]
	[660] = true, -- [The Arcatraz]
	[648] = true, -- [The Blood Furnace]
	[659] = true, -- [The Botanica]
	[652] = true, -- [The Escape From Durnholde]
	[658] = true, -- [The Mechanar]
	[657] = true, -- [The Shattered Halls]
	[649] = true, -- [The Slave Pens]
	[656] = true, -- [The Steamvault]
	[650] = true, -- [Underbog]

	[481] = true, -- [Ahn'kahet: The Old Kingdom]
	[480] = true, -- [Azjol-Nerub]
	[482] = true, -- [Drak'Tharon Keep]
	[484] = true, -- [Gundrak]
	[486] = true, -- [Halls of Lightning]
	[485] = true, -- [Halls of Stone]
	[479] = true, -- [The Culling of Stratholme]
	[4516] = true, -- [The Forge of Souls]
	[4518] = true, -- [The Halls of Reflection]
	[478] = true, -- [The Nexus]
	[487] = true, -- [The Oculus]
	[4517] = true, -- [The Pit of Saron]
	[483] = true, -- [The Violet Hold]
	[4296] = true, -- [Trial of the Champion] (A)
	[3778] = true, -- [Trial of the Champion] (H)
	[477] = true, -- [Utgarde Keep]
	[488] = true, -- [Utgarde Pinnacle]

	[4833] = true, -- [Blackrock Caverns]
	[4840] = true, -- [Grim Batol]
	[4841] = true, -- [Halls of Origination]
	[4848] = true, -- [Lost City of the Tol'vir]
	[4846] = true, -- [The Stonecore]
	[4847] = true, -- [The Vortex Pinnacle]
	[4839] = true, -- [Throne of the Tides]

-- Exploration
	[761] = true, -- [Explore Arathi Highlands]
	[845] = true, -- [Explore Ashenvale]
	[852] = true, -- [Explore Azshara]
	[860] = true, -- [Explore Azuremyst Isle]
	[765] = true, -- [Explore Badlands]
	[865] = true, -- [Explore Blade's Edge Mountains]
	[766] = true, -- [Explore Blasted Lands]
	[861] = true, -- [Explore Bloodmyst Isle]
	[1264] = true, -- [Explore Borean Tundra]
	[775] = true, -- [Explore Burning Steppes]
	[1457] = true, -- [Explore Crystalsong Forest]
	[844] = true, -- [Explore Darkshore]
	[777] = true, -- [Explore Deadwind Pass]
	[4864] = true, -- [Explore Deepholm]
	[848] = true, -- [Explore Desolace]
	[1265] = true, -- [Explore Dragonblight]
	[627] = true, -- [Explore Dun Morogh]
	[728] = true, -- [Explore Durotar]
	[778] = true, -- [Explore Duskwood]
	[850] = true, -- [Explore Dustwallow Marsh]
	[771] = true, -- [Explore Eastern Plaguelands]
	[726] = true, -- [Explore Elwynn Forest]
	[859] = true, -- [Explore Eversong Woods]
	[853] = true, -- [Explore Felwood]
	[849] = true, -- [Explore Feralas]
	[858] = true, -- [Explore Ghostlands]
	[1266] = true, -- [Explore Grizzly Hills]
	[862] = true, -- [Explore Hellfire Peninsula]
	[772] = true, -- [Explore Hillsbrad Foothills]
	[1263] = true, -- [Explore Howling Fjord]
	[4863] = true, -- [Explore Hyjal]
	[1270] = true, -- [Explore Icecrown]
	[868] = true, -- [Explore Isle of Quel'Danas]
	[779] = true, -- [Explore Loch Modan]
	[855] = true, -- [Explore Moonglade]
	[736] = true, -- [Explore Mulgore]
	[866] = true, -- [Explore Nagrand]
	[843] = true, -- [Explore Netherstorm]
	[750] = true, -- [Explore Northern Barrens]
	[781] = true, -- [Explore Northern Stranglethorn]
	[780] = true, -- [Explore Redridge Mountains]
	[774] = true, -- [Explore Searing Gorge]
	[864] = true, -- [Explore Shadowmoon Valley]
	[1268] = true, -- [Explore Sholazar Basin]
	[856] = true, -- [Explore Silithus]
	[769] = true, -- [Explore Silverpine Forest]
	[4996] = true, -- [Explore Southern Barrens]
	[847] = true, -- [Explore Stonetalon Mountains]
	[1269] = true, -- [Explore Storm Peaks]
	[782] = true, -- [Explore Swamp of Sorrows]
	[851] = true, -- [Explore Tanaris]
	[842] = true, -- [Explore Teldrassil]
	[867] = true, -- [Explore Terokkar Forest]
	[4995] = true, -- [Explore the Cape of Stranglethorn]
	[773] = true, -- [Explore The Hinterlands]
	[846] = true, -- [Explore Thousand Needles]
	[768] = true, -- [Explore Tirisfal Glades]
	[4866] = true, -- [Explore Twilight Highlands]
	[4865] = true, -- [Explore Uldum]
	[854] = true, -- [Explore Un'Goro Crater]
	[4825] = true, -- [Explore Vashj'ir]
	[770] = true, -- [Explore Western Plaguelands]
	[802] = true, -- [Explore Westfall]
	[841] = true, -- [Explore Wetlands]
	[857] = true, -- [Explore Winterspring]
	[863] = true, -- [Explore Zangarmarsh]
	[1267] = true, -- [Explore Zul'Drak]
}

	---------------
	--- Options ---
	---------------

local defaults = {
	profile = {
		enableAddOn = true,
		GuildMemberDings = true,
		partyAnnounce = true,
		dingMsg = {
			L["Ding! Level [LEVEL] in [TIME]"],
			L["Ding! Level [LEVEL] in [TIME]"],
			"Ding!",
			"Ding ^^",                
			"Ding [LEVEL]!",
			"[RT] Ding! [RT]",
		},
		outputFrame = 2,
		Language = 1,
		timeFormat = 2,
		filterPlayed = true,
		announceDelay = 0,
		guildMemberAchievementFilter = true,
		guildMemberLevelFilter = 10,
		guildMemberDingMsg = {
			"[NAME] dinged Level [LEVEL][TIME] in [ZONE]",
			"[NAME] dinged Level [LEVEL][TIME] in [ZONE]",
			"[NAME] dinged [LEVEL]",
			"[NAME] leveled up to [LEVEL]!",
			"[NAME] just reached "..LEVEL.." [LEVEL]!",
			"[NAME]: [LEVEL] [[ZONE]]",
		},
		screenshotDelay = 1,
		customSound = soundExamples[1],
		SomeSoundPath = 1,
		AutoGratzAFK = true,
		filterAchievements = true,
		autoGratzDelay = 0,
		autoGratzCooldown = 300,
		autoGratzMsg = {
			[1] = "gz",
			[4] = "gz!",
			[7] = "gz =)",
			[2] = "grats",
			[5] = "[RT] gz [RT]",
			[8] = "[GZ]",
			[3] = "[GZ] [SMILIE]",
			[6] = "[GZ] [NAME]",
			[9] = "[GZ] [NAME] [SMILIE]",
		},
	},
	char = {
		-- just needed a starting value
		-- and don't know how to do it the proper way :s
		stats = {
			timeAFK = 0,
			totalAFK = 0,
			kills = 0,
			deaths = 0,
		},
	},
}

local options = {
	type = "group",
	name = "",
	args = {
		Main = {
			type = "group",
			name = " |cffADFF2FReadySet|r|cffFFFFFFDing|r |cffB6CA00v"..VERSION.."|r |TInterface\\AddOns\\ReadySetDing\\Images\\ReadySet7:16:64:330:0|t",
			handler = RSD,
			args = {
				groupShow = {
					type = "group",
					name = "|cffFFFFFF"..SHOW.."|r Dings",
					order = 1,
					inline = true,
					args = {
						ShowParty = {
							type = "toggle",
							order = 1,
							descStyle = "",
							name = " |cffA8A8FF"..PARTY.."|r",
							get = function(i) return profile.partyDings end,
							set = function(i, v) profile.partyDings = v end,
							disabled = "OptionsDisabled",
						},
						showFriend = {
							type = "toggle",
							order = 2,
							descStyle = "",
							name = " "..FRIENDS,
							get = function(i) return profile.friendDings end,
							set = function(i, v) profile.friendDings = v end,
							disabled = "OptionsDisabled",
						},
						newline = {type = "description", order = 3, name = ""},
						showGuildMember = {
							type = "toggle",
							order = 4,
							descStyle = "",
							name = " |cff40FF40"..GUILD.."|r",
							get = function(i) return profile.GuildMemberDings end,
							set = function(i, v) profile.GuildMemberDings = v end,
							disabled = "OptionsDisabled",
						},
						showRealIDFriend = {
							type = "toggle",
							order = 5,
							descStyle = "",
							name = " |cff82C5FF"..BATTLENET_FRIEND.."|r "..FRIENDS,
							get = function(i) return profile.RealID_Dings end,
							set = function(i, v) profile.RealID_Dings = v end,
							disabled = "OptionsDisabled",
						},
					},
				},
				groupAnnounce = {
					type = "group",
					name = "|cffFFFFFF"..CHAT_ANNOUNCE.."|r Dings",
					order = 2,
					inline = true,
					args = {
						announceParty = {
							type = "toggle",
							order = 1,
							descStyle = "",
							name = "|TInterface\\Icons\\Ability_Warrior_RallyingCry:20:20:3:0:32:32:2:30:2:30|t   |cffA8A8FF"..CHAT_MSG_PARTY.."|r",
							get = function(i) return profile.partyAnnounce end,
							set = function(i, v) profile.partyAnnounce = v end,
							disabled = "OptionsDisabled",
						},
						announceZone = {
							type = "toggle",
							order = 2,
							descStyle = "",
							name = "|TInterface\\Icons\\INV_Misc_Map_01:20:20:2:0"..cropped.."|t   "..ZONE,
							get = function(i) return profile.zoneAnnounce end,
							set = function(i, v) profile.zoneAnnounce = v end,
							disabled = "OptionsDisabled",
						},
						newline1 = {type = "description", order = 3, name = ""},
						announceGuild = {
							type = "toggle",
							order = 4,
							descStyle = "",
							name = function() return RSD:GuildEmblem().."|cff40FF40"..CHAT_MSG_GUILD.."|r" end,
							get = function(i) return profile.guildAnnounce end,
							set = function(i, v) profile.guildAnnounce = v end,
							disabled = "OptionsDisabled",
						},
						toggleStopwatch = {
							type = "toggle",
							order = 5,
							desc = TIMEMANAGER_SHOW_STOPWATCH,
							name = "|TInterface\\Icons\\Spell_Holy_BorrowedTime:20:20:2:0"..cropped.."|t   "..STOPWATCH_TITLE,
							get = function(i) return profile.Stopwatch end,
							set = function(i, v) profile.Stopwatch = v
								if v then
									if isStopwatch then
										StopwatchFrame:Show()
										StopwatchTicker.timer = currentTime
										Stopwatch_Play()
									end
								else
									Stopwatch_Clear()
									StopwatchFrame:Hide()
								end
							end,
							disabled = "OptionsDisabled",
						},
						newline2 = {type = "description", order = 6, name = ""},
						broadcastBNet = {
							type = "toggle",
							order = 7,
							desc = BN_BROADCAST_TOOLTIP,
							name = function()
								if time() > (cd.randomIcon1 or 0) then
									cd.randomIcon1 = time() + 120
									local num = random(4)
									if	   num <= 2 then randomIcon1 = "PlusManz-BattleNet" -- \Data\enGB\locale-enGB.MPQ\Interface\FriendsFrame\PlusManz-BattleNet.blp
									elseif num == 3 then randomIcon1 = "Battlenet-WoWicon"
									elseif num == 4 then randomIcon1 = "Battlenet-Sc2icon"
									end
								end
								return "|TInterface\\FriendsFrame\\"..randomIcon1..":24|t  |cff82C5FF"..BATTLENET_FRIEND.."|r"
							end,
							get = function(i) return profile.BNetBroadcast end,
							set = function(i, v) profile.BNetBroadcast = v end,
							disabled = "OptionsDisabled",
						},
					},
				},
				inputDingMsg = {
					type = "input",
					order = 3,
					width = "full",
					name = " ", -- If it was like "" then usage wouldnt appear
					usage = legend,
					get = function(i)
						if profile.randomMessage then
							return "Random Messages: Enabled  |TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:12:12:0:0|t"
						else
							return profile.dingMsg[1]
						end
					end,
					set = function(i, v) profile.dingMsg[1] = v
						RSD:ValidateMessage(v)
						if #strtrim(v) == 0 then profile.dingMsg[1] = defaults.profile.dingMsg[1] end
					end,
					disabled = function() return not RSD:IsEnabled() or profile.randomMessage end,
				},
				descriptionExample = {
					type = "description",
					order = 4,
					name = function() return "   "..RSD:ReplaceText(profile.dingMsg[1], "ExampleDingMsg") end,
				},
				spacing = {type = "description", order = 5, name = ""},
				descriptionLevelSummary = {
					type = "description",
					order = 6,
					name = function() return RSD:LevelSummary() end,
				},
				descEnable = {
					type = "description",
					order = 7,
					fontSize = "large",
					name = function() return RSD:OptionsDisabled() and "\n Type |cff2E9AFE/rsd on|r to enable" or "" end,
				},
			},
		},
		Advanced = {
			type = "group",
			name = "",
			handler = RSD,
			args = {
				selectOutputFrame = {
					type = "select",
					order = 1,
					descStyle = "",
					name = "   |cffFFFFFFOutput Frame|r",
					values = function()
						local color, ChatWindows = "|cff2E9AFE", {}
						ChatWindows[1] = color.."#|r  UIErrorsFrame"
						ChatWindows[2] = color.."#|r  RaidWarningFrame"
						ChatWindows[3] = color.."#|r  RaidBossEmoteFrame"
						for i = 1, NUM_CHAT_WINDOWS do
							local b = GetChatWindowInfo(i)
							if #b > 0 then
								ChatWindows[i+3] = color..i..".|r "..b
							end
						end
						return ChatWindows
					end,
					get = function(i) return profile.outputFrame end,
					set = function(i, v) profile.outputFrame = v
						RSD:OutputFrame(nil, true)
					end,
					disabled = "OptionsDisabled",
				},
				newline01 = {type = "description", order = 2, name = ""},
				selectLanguage = {
					type = "select",
					order = 3,
					descStyle = "",
					name = "   |cffFFFFFF"..LANGUAGES_LABEL.."|r",
					values = function()
						local color, languages = "|cff2E9AFE", {}
						languages[1] = color.."#|r  |cffFBDB00"..DEFAULT.."|r"
						languages[2] = color.."#|r  |cff71D5FFRandom|r"
						for i = 1, GetNumLanguages() do
							languages[i+2] = color..i..".|r "..GetLanguageByIndex(i)
						end
						return languages
					end,
					get = function(i) return profile.Language end,
					set = function(i, v) profile.Language = v end,
					disabled = "OptionsDisabled",
				},
				newline02 = {type = "description", order = 4, name = ""},
				selectTimeFormat = {
					type = "select",
					order = 5,
					descStyle = "",
					name = "   |cffFFFFFFTime Format|r (|cff71D5FF"..MINUTES2.."|r)",
					values = {"|cffB6CA00X|r minutes, |cffF6ADC6Y|r seconds", "|cffB6CA00X|r.|cffF6ADC6Y|r minutes"},
					get = function(i) return profile.timeFormat end,
					set = function(i, v) profile.timeFormat = v end,
					disabled = "OptionsDisabled",
				},
				spacing01 = {type = "description", order = 6, name = " "},
				toggleFilterPlayed = {
					type = "toggle",
					order = 7,
					width = "full",
					desc = function()
						local s1 = format(TIME_PLAYED_TOTAL, format(TIME_DAYHOURMINUTESECOND, unpack( {ChatFrame_TimeBreakDown(totalTime)} )))
						local s2 = format(TIME_PLAYED_LEVEL, format(TIME_DAYHOURMINUTESECOND, unpack( {ChatFrame_TimeBreakDown(currentTime)} )))
						return format("%s\n\n%s", s1, s2)
					end,
					name = "|TInterface\\Icons\\Spell_Holy_Silence:20:20:1:0"..cropped.."|t  Filter /played",
					get = function(i) return profile.filterPlayed end,
					set = function(i, v) profile.filterPlayed = v end,
					disabled = "OptionsDisabled",
				},
				toggleDingEmote = {
					type = "toggle",
					order = 8,
					width = "full",
					desc = "\""..TUTORIAL_TITLE55.."\"",
					name = "|TInterface\\Icons\\Achievement_PVP_H_14:20:20|t |cffFFFFFF"..EMOTE389_CMD1.."|r  |cffFFFF00"..EMOTE.."|r",
					get = function(i) return profile.dingEmote end,
					set = function(i, v) profile.dingEmote = v end,
					disabled = "OptionsDisabled",
				},
				toggleRandomMessage = {
					type = "toggle",
					order = 9,
					width = "full",
					descStyle = "",
					name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:20:20:0:1|t  |cffF6ADC6Random|r Messages",
					get = function(i) return profile.randomMessage end,
					set = function(i, v) profile.randomMessage = v
						if v then
							ACD:Open("ReadySetDing_RandomMessage")
						end
					end,
					disabled = "OptionsDisabled",
				},
				spacing02 = {type = "description", order = 10, name = " "},
				rangeAnnounceDelay = {
					type = "range",
					order = 11,
					desc = "|cffF6ADC6"..DEFAULT.."|r = 0 "..strlower(SECONDS),
					name = "  |cffFFFFFF"..CHAT_ANNOUNCE.."|r "..L["Delay"],
					get = function(i) return profile.announceDelay end,
					set = function(i, v) profile.announceDelay = v end,
					min = 0, softMin = 0,
					max = 60, softMax = 10,
					step = 0.5,
					disabled = "OptionsDisabled",
				},
			},
		},
		GuildMemberDings = {
			type = "group",
			name = "|cff40FF40"..GUILD.." Member|r Dings",
			handler = RSD,
			args = {
				toggleGuildMemberAnnounce = {
					type = "toggle",
					order = 1,
					width = "full",
					descStyle = "",
					name = "|TInterface\\Icons\\Ability_Warrior_RallyingCry:20:20:1:0"..cropped.."|t  "..CHAT_ANNOUNCE.." |cff40FF40"..GUILD.." Member|r Dings ",
					get = function(i) return profile.guildMemberAnnounce end,
					set = function(i, v) profile.guildMemberAnnounce = v end,
					disabled = "OptionsDisabled",
				},
				toggleGuildMemberAchievementFiter = {
					type = "toggle",
					order = 2,
					width = "full",
					desc = LEVEL.." |cffB6CA0010|r, |cffB6CA0020|r, |cffB6CA0030|r, ...|r",
					name = function()
						if time() > (cd.randomIcon2 or 0) then
							cd.randomIcon2 = time() + 60
							randomIcon2 = math.random(9)*10
							if randomIcon2 == 90 then randomIcon2 = 85 end
						end
						return "|TInterface\\Icons\\Achievement_Level_"..randomIcon2..":20:20:1:0"..cropped.."|t  |cffFFFF00"..ACHIEVEMENTS.."|r "..FILTER
					end,
					get = function(i) return profile.guildMemberAchievementFilter end,
					set = function(i, v) profile.guildMemberAchievementFilter = v end,
					disabled = "OptionsDisabled",
				},
				toggleRandomMessageGuild = {
					type = "toggle",
					order = 3,
					width = "full",
					descStyle = "",
					name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:24:24:-2:1|t |cffF6ADC6Random|r |cff40FF40"..CHAT_MSG_GUILD.."|r Messages",
					get = function(i) return profile.randomMessageGuild end,
					set = function(i, v) profile.randomMessageGuild = v
						if v then
							ACD:Open("ReadySetDing_RandomMessageGuild")
						end
					end,
					disabled = "OptionsDisabled",
				},
				spacing01 = {type = "description", order = 4, name = " "},
				rangeGuildMemberFilter = {
					type = "range",
					order = 5,
					desc = "|cffF6ADC6"..DEFAULT.."|r = "..LEVEL.." 10",
					name = "  |cffFFFFFF"..LEVEL.."|r "..FILTER,
					get = function(i) return profile.guildMemberLevelFilter end,
					set = function(i, v) profile.guildMemberLevelFilter = v end,
					min = 2,
					max = 85,
					step = 1,
					disabled = "OptionsDisabled",
				},
				spacing02 = {type = "description", order = 6, name = " "},
				inputGuildMemberMsg = {
					type = "input",
					order = 7,
					width = "full",
					name = " ",
					usage = legend2,
					get = function(i)
						if profile.randomMessageGuild then
							return "Random Messages: Enabled  |TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:12:12:0:0|t"
						else
							return profile.guildMemberDingMsg[1]
						end
					end,
					set = function(i, v) profile.guildMemberDingMsg[1] = v
						if #strtrim(v) == 0 then profile.guildMemberDingMsg[1] = defaults.profile.guildMemberDingMsg[1] end
					end,
					disabled = function() return not RSD:IsEnabled() or profile.randomMessageGuild end,
				},
				descriptionExample = {
					type = "description",
					order = 8,
					name = function() return RSD:GetGuildExampleMsg(1) end,
				},
				description2 = {
					type = "description",
					order = 9,
					name = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n |cff71D5FF[TIME]|r = |cffF6ADC6Real world time|r (!)\n\n |cffFF0000Note:|r Level Speed Ranking is |cffF6ADC6experimental|r\n",
				},
				GuildMemberLevelSpeed = {
					type = "execute",
					order = 10,
					name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:-1"..cropped.."|t |cffFFFFFF"..L["Level Speed"].."|r",
					func = function()
						local list = {}
						for i = 1, GetNumGuildMembers() do
							local name = GetGuildRosterInfo(i)
							if realm[name] and realm[name][0] then
								list[realm[name][0]] = name
							end
						end
						local i, t = 1, {}
						for k, v in pairs(list) do
							t[i] = k
							i = i + 1
						end
						sort(t)
						for i, v in ipairs(t) do
							print(format("#%d |cff71D5FF%s|r |cffADFF2F%.2f|r %s/%s (|cffB6CA00%s|r)", i, list[v], v, HOUR, LEVEL, realm[list[v]][1]))
						end
					end,
					disabled = "OptionsDisabled",
				},
			},
		},
		Screenshot = {
			type = "group",
			name = "|cffFFFFFFDing|r "..L["Screenshot"],
			handler = RSD,
			args = {
				toggleScreenshot = {
					type = "toggle",
					order = 1,
					desc = BINDING_NAME_SCREENSHOT,
					name = "|TInterface\\Icons\\inv_misc_spyglass_03:20:20:1:0"..cropped.."|t  Ding |cffFBDB00"..L["Screenshot"].."|r",
					get = function() return profile.Screenshot end,
					set = function(i, v) profile.Screenshot = v end,
					disabled = "OptionsDisabled",
				},
				toggleScreenshotHideUI = {
					type = "toggle",
					order = 2,
					width = "full",
					descStyle = "",
					name = "|TInterface\\Icons\\INV_Gizmo_GoblingTonkController:20:20:1:0"..cropped.."|t  "..HIDE.." "..BUG_CATEGORY5,
					get = function(i) return profile.screenshotHideUI end,
					set = function(i, v) profile.screenshotHideUI = v end,
					disabled = function() return not RSD:IsEnabled() or not profile.Screenshot end,
				},
				toggleRaidWarningOutput = {
					type = "toggle",
					order = 3,
					width = "full",
					desc = "Useful for in your screenshot\n\n|cffFF0000Note:|r Doesn't work with |cffFFFF00["..HIDE.." "..BUG_CATEGORY5.."]|r",
					name = "|TInterface\\Icons\\Ability_Warrior_RallyingCry:20:20:1:0"..cropped.."|t  \""..CHAT_MSG_RAID_WARNING.."\" Message",
					get = function(i) return profile.RaidWarningOutput end,
					set = function(i, v) profile.RaidWarningOutput = v end,
					disabled = "OptionsDisabled",
				},
				spacing = {type = "description", order = 4, name = " "},
				rangeScreenshotDelay = {
					type = "range",
					order = 5,
					desc = "|cffF6ADC6"..DEFAULT.."|r = 1 "..strlower(SECONDS),
					name = "  |cffFFFFFF"..L["Screenshot"].."|r "..L["Delay"],
					get = function(i) return profile.screenshotDelay end,
					set = function(i, v) profile.screenshotDelay = v end,
					min = 0, softMin = 0,
					max = 60, softMax = 2,
					step = 0.1,
					disabled = "OptionsDisabled",
				},
			},
		},
		Sound = {
			type = "group",
			name = " |TInterface\\Icons\\INV_Misc_Bell_01:16:16:0:3"..cropped.."|t  |cffFFFFFFDing|r Sound",
			handler = RSD,
			args = {
				inputCustomSound = {
					type = "input",
					order = 1,
					width = "full",
					desc = "|cffFF0000Note:|r Restart is required for loading custom sound files",
					name = " ",
					get = function(i) return profile.customSound end,
					set = function(i, v) profile.customSound = v
						if #strtrim(v) == 0 then profile.customSound = defaults.profile.customSound end
					end,
					disabled = "OptionsDisabled",
				},
				executeTestSound = {
					type = "execute",
					order = 2,
					width = "half",
					name = "Test",
					func = function()
						--	would be kinda annoying if some1 accidentally spammed this in combination with long sound files
						if time() > (cd.customSound or 0) then
							cd.customSound = time() + 1
							if profile.customSound == soundExamples[2] then
								PSF(soundExamples[random(3, #soundExamples)], "Master")
							else
								PSF(profile.customSound, "Master")
							end
						end
					end,
					disabled = "OptionsDisabled",
				},
				spacing = {type = "description", order = 3, name = " "},
				selectSomeSoundPath = {
					type = "select",
					order = 4,
					descStyle = "",
					width = "full",
					name = "  |TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:20:20:0:1|t Examples",
					values = soundExamples,
					get = function(i) return profile.SomeSoundPath end,
					set = function(i, v) profile.SomeSoundPath = v; profile.customSound = soundExamples[v] end,
					disabled = "OptionsDisabled",
				},
			},
		},
		AutoGratz = {
			type = "group",
			name = "|cffFFFFFF"..L["Auto Gratz"].."|r",
			handler = RSD,
			args = {
				toggleAutoGratz = {
					type = "toggle",
					order = 1,
					width = "full",
					descStyle = "",
					name = "|TInterface\\Icons\\INV_Misc_Gift_05:20:20:1:0"..cropped.."|t  "..L["Auto Gratz"],
					get = function(i) return profile.AutoGratz end,
					set = function(i, v) profile.AutoGratz = v end,
					disabled = "OptionsDisabled",
				},
				AutoGratzAFK = {
					type = "toggle",
					order = 2,
					width = "full",
					desc = "|cffFFFF00\""..MARKED_AFK.."\"|r",
					name = "|TInterface\\Icons\\Spell_Nature_Sleep:20:20:1:0"..cropped.."|t  Disable on AFK",
					get = function(i) return profile.AutoGratzAFK end,
					set = function(i, v) profile.AutoGratzAFK = v end,
					disabled = "OptionsDisabled",
				},
				AllAchievements = {
					type = "toggle",
					order = 3,
					descStyle = "",
					name = "|TInterface\\Icons\\Achievement_Reputation_06:20:20:1:1"..cropped.."|t  All |cffFFFF00"..ACHIEVEMENTS.."|r",
					get = function(i) return profile.allAchievements end,
					set = function(i, v) profile.allAchievements = v end,
					disabled = "OptionsDisabled",
				},
				FilterAchievements = {
					type = "toggle",
					order = 4,
					desc = "Internal Blacklist",
					name = "|TInterface\\Icons\\Trade_Engineering:20:20:1:1"..cropped.."|t  +Filter",
					get = function(i) return profile.filterAchievements end,
					set = function(i, v) profile.filterAchievements = v end,
					disabled = function() return not RSD:IsEnabled() or not profile.allAchievements end,
				},
				spacing01 = {type = "description", order = 5, name = " "},
				rangeAutoGratzDelay = {
					type = "range",
					order = 6,
					desc = "|cffF6ADC6"..DEFAULT.."|r = 0 "..strlower(SECONDS).."\n(|cffFF8000Random|r 3-20)",
					name = L["Delay"],
					get = function(i) return profile.autoGratzDelay end,
					set = function(i, v) profile.autoGratzDelay = v end,
					min = 0, softMin = 0,
					max = 60, softMax = 10,
					step = 0.5,
					disabled = "OptionsDisabled",
				},
				rangeAutoGratzCooldown = {
					type = "range",
					order = 7,
					desc = "|cffF6ADC6"..DEFAULT.."|r = 300 "..strlower(SECONDS),
					name = L["Cooldown"],
					get = function(i) return profile.autoGratzCooldown end,
					set = function(i, v) profile.autoGratzCooldown = v end,
					min = 0, softMin = 0,
					max = 1200, softMax = 600,
					step = 1,
					disabled = "OptionsDisabled",
				},
				spacing02 = {type = "description", order = 8, name = " "},
				header = {type = "header", order = 9, name = ""},
				inputAutoGratzMsg1 = {
					type = "input",
					order = 10,
					name = "",
					get = function(i) return profile.autoGratzMsg[1] end,
					set = function(i, v) profile.autoGratzMsg[1] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[1] = defaults.profile.autoGratzMsg[1] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg2 = {
					type = "input",
					order = 11,
					name = "",
					get = function(i) return profile.autoGratzMsg[2] end,
					set = function(i, v) profile.autoGratzMsg[2] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[2] = defaults.profile.autoGratzMsg[2] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg3 = {
					type = "input",
					order = 12,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[3] end,
					set = function(i, v) profile.autoGratzMsg[3] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[3] = defaults.profile.autoGratzMsg[3] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg4 = {
					type = "input",
					order = 13,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[4] end,
					set = function(i, v) profile.autoGratzMsg[4] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[4] = defaults.profile.autoGratzMsg[4] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg5 = {
					type = "input",
					order = 14,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[5] end,
					set = function(i, v) profile.autoGratzMsg[5] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[5] = defaults.profile.autoGratzMsg[5] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg6 = {
					type = "input",
					order = 15,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[6] end,
					set = function(i, v) profile.autoGratzMsg[6] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[6] = defaults.profile.autoGratzMsg[6] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg7 = {
					type = "input",
					order = 16,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[7] end,
					set = function(i, v) profile.autoGratzMsg[7] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[7] = defaults.profile.autoGratzMsg[7] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg8 = {
					type = "input",
					order = 17,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[8] end,
					set = function(i, v) profile.autoGratzMsg[8] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[8] = defaults.profile.autoGratzMsg[8] end end,
					disabled = "OptionsDisabled",
				},
				inputAutoGratzMsg9 = {
					type = "input",
					order = 18,
					descStyle = "",
					name = "",
					get = function(i) return profile.autoGratzMsg[9] end,
					set = function(i, v) profile.autoGratzMsg[9] = v
						if #strtrim(v) == 0 then profile.autoGratzMsg[9] = defaults.profile.autoGratzMsg[9] end end,
					disabled = "OptionsDisabled",
				},
				spacing = {type = "description", order = 19, name = "\n"},
				descriptionMessages = {
					type = "description",
					order = 20,
					fontSize = "medium",
					name = "|cff71D5FF[GZ]|r = "..strjoin(", ", unpack(gratzMsg)).."\n|cff71D5FF[SMILIE]|r = "..strjoin(", ", unpack(smilieMsg)).."\n",
				},
				descriptionRaidTarget = {
					type = "description",
					order = 21,
					fontSize = "medium",
					name = function()
						local t = {}
						for i = 1, 8 do
							t[i] = "  |T"..RT..i..":16:16:0:4|t {rt"..i.."}"
						end
						return strjoin("\n", unpack(t))
					end,
				},
			},
		},
		Stats = {
			type = "group",
			name = "",
			handler = RSD,
			args = {
				groupInline = {
					type = "group",
					name = " ",
					order = 1,
					inline = true,
					args = {
						Experience = {
							type = "description",
							order = 1,
							name = function() return format(" %s = |cffB6CA00%s|r / |cff71D5FF%s|r = |cffADFF2F%d%%|r", COMBAT_XP_GAIN, UnitXP("player"), UnitXPMax("player"), (UnitXP("player")/UnitXPMax("player"))*100) end,
						},
						LevelDate = {
							type = "description",
							order = 2,
							name = function()
								-- using table.maxn, since here it will include the corresponding level next to it
								-- and then it's affordable to rather show the outdated/previous level data, instead of "[No Data]"
								local a = char.dateStampList
								local b = table_maxn(a) > 0 and " "..LEVEL.." |cffB6CA00"..table_maxn(a).."|r: " or " "..LEVEL..": "
								return b..(a[table_maxn(a)] and "|cff71D5FF"..a[table_maxn(a)].."|r" or "|cffF6ADC6"..L["[No Data]"].."|r").."\n"
								-- I'm getting dizzy ...
							end,
						},
						RealTime = {
							type = "description",
							order = 3,
							name = function() return " "..L["Real Time"].." = "..(char.unixTimeList[player.level] and "|cffB6CA00"..RSD:TimetoString(time()-char.unixTimeList[player.level]).."|r" or "|cffF6ADC6"..L["[No Data]"].."|r") end,
						},
						LevelTime = {
							type = "description",
							order = 4,
							name = function() return " "..L["Level Time"].." = |cffADFF2F"..RSD:TimetoString(currentTime).."|r" end,
						},
						TotalTime = {
							type = "description",
							order = 5,
							name = function() return " "..L["Total Time"].." = |cff71D5FF"..RSD:TimetoString(totalTime).."|r" end,
						},
						LevelDiff = {
							type = "description",
							order = 6,
							name = function() return " "..L["Difference"].." = "..(RSD:TimeDiff(true) == L["[No Data]"] and "|cffF6ADC6"..L["[No Data]"].."|r" or "|cff6495ED"..RSD:TimeDiff(true).."|r").."\n" end,
						},
						XP_Speed = {
							type = "description",
							order = 7,
							name = function() return " "..format("%s %s = |cffADFF2F%d|r %s/%s", XP, SPEED, UnitXP("player")/(currentTime/3600), XP, HOUR) end,
						},
						LevelSpeed = {
							type = "description",
							order = 8,
							name = function() return " "..L["Level Speed"].." = "..(RSD:RecentLevelSpeed() == L["[No Data]"] and "|cffF6ADC6"..L["[No Data]"].."|r" or format("|cffB6CA00%.2f|r %s/%s", RSD:RecentLevelSpeed()/3600, HOUR, LEVEL)) end,
						},
						LevelSpeed_Avg = {
							type = "description",
							order = 9,
							name = function() return " "..L["Average Level Speed"].." = "..(player.level > 1 and format("|cff71D5FF%.2f|r %s/%s", (totalTime/3600)/(player.level-1), HOUR, LEVEL) or "|cffF6ADC6"..L["[No Data]"].."|r").."\n" end,
						},
						Activity = {
							type = "description",
							order = 10,
							name = function() return " "..L["Activity"].." = "..(char.unixTimeList[player.level] and "|cffB6CA00"..floor((currentTime/(time()-char.unixTimeList[player.level]))*100).."%|r" or "|cffF6ADC6"..L["[No Data]"].."|r") end,
						},
						TimeAFK = {
							type = "description",
							order = 11,
							name = function() return " "..L["AFK Time"].." = |cffB6CA00"..RSD:TimetoString(stats.timeAFK).."|r" end,
						},
						TimeAFK_Avg = {
							type = "description",
							order = 12,
							name = function() return " "..L["Total AFK Time"].." = |cff71D5FF"..RSD:TimetoString(stats.totalAFK).."|r\n" end,
						},
						Kills = {
							type = "description",
							order = 13,
							name = function() return " "..KILLS.." = |cffB6CA00"..stats.kills.."|r, "..L["Total Kills"].." = |cff71D5FF"..RSD:AchievementStatistics("kills").."|r" end,
						},
						Deaths = {
							type = "description",
							order = 14,
							name = function() return " "..DEATHS.." = |cffFF0000"..stats.deaths.."|r, "..L["Total Deaths"].." = |cffFF0000"..RSD:AchievementStatistics("deaths").."|r" end,
						},
						Quests = {
							type = "description",
							order = 15,
							name = function()
								local quests, daily = RSD:AchievementStatistics("quests")
								return " "..PLAYER_DIFFICULTY1.." "..QUESTS_LABEL.." = |cffADFF2F"..quests.."|r, "..DAILY.." "..QUESTS_LABEL.." = |cff6495ED"..daily.."|r"
							end,
						},
					},
				},
				spacing = {type = "description", order = 2, name = " "},
				PrintLevelData = {
					type = "execute",
					order = 3,
					name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:-1"..cropped.."|t  |cffFFFFFFLevel Data|r",
					func = function()
						for i = 2, player.maxLevel do
							if char.levelTimeList[i] then
								print(LEVEL.." |cffF6ADC6"..i-1 .."|r - |cff71D5FF"..i.."|r: |cffB6CA00"..RSD:TimetoString(char.levelTimeList[i], true).."|r   "..L["Total"]..": |cff71D5FF"..RSD:TimetoString(char.totalTimeList[i], true).."|r")
							end
						end
					end,
					disabled = "OptionsDisabled",
				},
				newline01 = {type = "description", order = 4, name = ""},
				ExportData = {
					type = "execute",
					order = 5,
					name = "|TInterface\\Icons\\Trade_Engineering:16:16:1:-1"..cropped.."|t  |cffFFFFFFExport|r",
					func = function() RSD:ExportData() end,
					disabled = "OptionsDisabled",
				},
				newline02 = {type = "description", order = 6, name = ""},
				PlaySound = {
					type = "execute",
					order = 7,
					desc = "|cffADFF2Fboosts e-peen|r",
					name = "|TSPELLS\\HOLIDAYS\\Heart:16:16:0:-1|t  |cffF6ADC6Play Sound|r", -- ...\Data\common.MPQ\SPELLS\HOLIDAYS\Heart.blp
					func = function()
						if time() > (cd.playSound or 0) then
							cd.playSound = time() + 3
							local descInterface = " /run |cffB6CA00PlaySoundFile(\"Sound\\\\Interface\\\\|r|cff71D5FF"
							local descSpell = " /run |cffB6CA00PlaySoundFile(\"Sound\\\\Spells\\\\|r|cff71D5FF"
							local descEnd = "|r|cffB6CA00.ogg\")|r\n"
							local num = random(10)

							if num <= 2 then PSF("Sound\\Interface\\LevelUp.ogg", "Master"); soundPath = descInterface.."LevelUp"..descEnd -- ...\Data\sound.MPQ\Sound\Interface\LevelUp.ogg -- Player Leveled Up
							elseif num == 3 or num == 4 then PSF("Sound\\Interface\\iQuestComplete.ogg", "Master"); soundPath = descInterface.."iQuestComplete"..descEnd -- ...\Data\sound.MPQ\Sound\Interface\iQuestComplete.ogg -- Quest Comepleted
							elseif num == 5 or num == 6 then PSF("Sound\\Spells\\AchievmentSound1.ogg", "Master"); soundPath = descSpell.."AchievmentSound1"..descEnd -- ...\Data\sound.MPQ\Sound\Spells\AchievmentSound1.ogg -- Achievement Gained
							elseif num == 7 or num == 8 then PSF("Sound\\Spells\\Resurrection.ogg", "Master"); soundPath = descSpell.."Resurrection"..descEnd -- ...\Data\sound.MPQ\Sound\Spells\Resurrection.ogg -- Resurrection
							elseif num == 9 then PSF("Sound\\Creature\\Paletress\\AC_Paletress_Death01.ogg", "Master"); soundPath = " /run |cffB6CA00PlaySoundFile(\"Sound\\\\Creature\\\\Paletress\\\\|r|cff71D5FFAC_Paletress_Death01"..descEnd -- lol
							elseif num == 10 then PSF("Sound\\Character\\BloodElf\\BloodElfFemaleFlirt02.ogg", "Master"); soundPath = " /run |cffB6CA00PlaySoundFile(\"Sound\\\\Character\\\\BloodElf\\\\|r|cff71D5FFBloodElfFemaleFlirt02"..descEnd
							end
						end
					end,
					disabled = "OptionsDisabled",
				},
				SoundPath = {
					type = "description",
					order = 8,
					name = function()
						return time() < (cd.playSound or 0) and soundPath or "\n"
					end,
				},
			},
		},
		RandomMessage = {
			type = "group",
			name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:24:24:0:5|t  Random Messages",
			handler = RSD,
			args = {
				input1 = {
					type = "input",
					order = 1,
					width = "full",
					name = "  Note: This part is kinda experimental, I'm a noob with frames / AceGUI ...",
					usage = legend,
					get = function(i) return profile.dingMsg[2] end,
					set = function(i, v) profile.dingMsg[2] = v
						if #strtrim(v) == 0 then profile.dingMsg[2] = defaults.profile.dingMsg[2] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description1 = {
					type = "description",
					order = 2,
					name = function() return "   "..RSD:ReplaceText(profile.dingMsg[2], true) end,
				},
				input2 = {
					type = "input",
					order = 3,
					width = "full",
					name = " ",
					usage = legend,
					get = function(i) return profile.dingMsg[3] end,
					set = function(i, v) profile.dingMsg[3] = v
						if #strtrim(v) == 0 then profile.dingMsg[3] = defaults.profile.dingMsg[3] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description2 = {
					type = "description",
					order = 4,
					name = function() return "   "..RSD:ReplaceText(profile.dingMsg[3], true) end,
				},
				input3 = {
					type = "input",
					order = 5,
					width = "full",
					name = " ",
					usage = legend,
					get = function(i) return profile.dingMsg[4] end,
					set = function(i, v) profile.dingMsg[4] = v
						if #strtrim(v) == 0 then profile.dingMsg[4] = defaults.profile.dingMsg[4] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description3 = {
					type = "description",
					order = 6,
					name = function() return "   "..RSD:ReplaceText(profile.dingMsg[4], true) end,
				},
				input4 = {
					type = "input",
					order = 7,
					width = "full",
					name = " ",
					usage = legend,
					get = function(i) return profile.dingMsg[5] end,
					set = function(i, v) profile.dingMsg[5] = v
						if #strtrim(v) == 0 then profile.dingMsg[5] = defaults.profile.dingMsg[5] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description4 = {
					type = "description",
					order = 8,
					name = function() return "   "..RSD:ReplaceText(profile.dingMsg[5], true) end,
				},
				input5 = {
					type = "input",
					order = 9,
					width = "full",
					name = " ",
					usage = legend,
					get = function(i) return profile.dingMsg[6] end,
					set = function(i, v) profile.dingMsg[6] = v
						if #strtrim(v) == 0 then profile.dingMsg[6] = defaults.profile.dingMsg[6] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description5 = {
					type = "description",
					order = 10,
					name = function() return "   "..RSD:ReplaceText(profile.dingMsg[6], true) end,
				},
			},
		},
		RandomMessageGuild = {
			type = "group",
			name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:24:24:0:5|t  Random |cff40FF40"..GUILD.."|r Messages",
			handler = RSD,
			args = {
				input1 = {
					type = "input",
					order = 1,
					width = "full",
					name = " ",
					usage = legend2,
					get = function(i) return profile.guildMemberDingMsg[2] end,
					set = function(i, v) profile.guildMemberDingMsg[2] = v
						if #strtrim(v) == 0 then profile.guildMemberDingMsg[2] = defaults.profile.guildMemberDingMsg[2] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description1 = {
					type = "description",
					order = 2,
					name = function() return RSD:GetGuildExampleMsg(2) end,
				},
				input2 = {
					type = "input",
					order = 3,
					width = "full",
					name = " ",
					usage = legend2,
					get = function(i) return profile.guildMemberDingMsg[3] end,
					set = function(i, v) profile.guildMemberDingMsg[3] = v
						if #strtrim(v) == 0 then profile.guildMemberDingMsg[3] = defaults.profile.guildMemberDingMsg[3] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description2 = {
					type = "description",
					order = 4,
					name = function() return RSD:GetGuildExampleMsg(3) end,
				},
				input3 = {
					type = "input",
					order = 5,
					width = "full",
					name = " ",
					usage = legend2,
					get = function(i) return profile.guildMemberDingMsg[4] end,
					set = function(i, v) profile.guildMemberDingMsg[4] = v
						if #strtrim(v) == 0 then profile.guildMemberDingMsg[4] = defaults.profile.guildMemberDingMsg[4] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description3 = {
					type = "description",
					order = 6,
					name = function() return RSD:GetGuildExampleMsg(4) end,
				},
				input4 = {
					type = "input",
					order = 7,
					width = "full",
					name = " ",
					usage = legend2,
					get = function(i) return profile.guildMemberDingMsg[5] end,
					set = function(i, v) profile.guildMemberDingMsg[5] = v
						if #strtrim(v) == 0 then profile.guildMemberDingMsg[5] = defaults.profile.guildMemberDingMsg[5] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description4 = {
					type = "description",
					order = 8,
					name = function() return RSD:GetGuildExampleMsg(5) end,
				},
				input5 = {
					type = "input",
					order = 9,
					width = "full",
					name = " ",
					usage = legend2,
					get = function(i) return profile.guildMemberDingMsg[6] end,
					set = function(i, v) profile.guildMemberDingMsg[6] = v
						if #strtrim(v) == 0 then profile.guildMemberDingMsg[6] = defaults.profile.guildMemberDingMsg[6] end
						RSD:ValidateMessage(v)
					end,
					disabled = "OptionsDisabled",
				},
				description5 = {
					type = "description",
					order = 10,
					name = function() return RSD:GetGuildExampleMsg(6) end,
				},
			},
		},
	},
}

-- autogratz input messages; compressed
-- why is this method not working? :(
--[[
for i = 1, 9 do
	options.args.AutoGratz.args["inputAutoGratzMsg"..i] = {
		type = "input",
		order = 5 + i,
		name = "",
		get = function(i) return profile.autoGratzMsg[i] end,
		set = function(i, v) profile.autoGratzMsg[i] = v
			if #strtrim(v) == 0 then
				profile.autoGratzMsg[i] = defaults.profile.autoGratzMsg[i]
			end
		end,
		disabled = "OptionsDisabled",
	}
end
]]

	-------------------------------
	---- OnInitialize, OnEnable ---
	-------------------------------

local titleName = "ReadySet|cffFFFFFFDing|r|TInterface\\AddOns\\ReadySetDing\\Images\\Windows7_Logo:16:16:3:0|t"

function RSD:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ReadySetDingDB", defaults, true)

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	self:RefreshConfig()

	self.db.global.version = VERSION
	self.db.global.fileType = FILETYPE

	ACR:RegisterOptionsTable("ReadySetDing_Main", options.args.Main)
	ACR:RegisterOptionsTable("ReadySetDing_Advanced", options.args.Advanced)
	ACR:RegisterOptionsTable("ReadySetDing_GuildMemberDings", options.args.GuildMemberDings)
	ACR:RegisterOptionsTable("ReadySetDing_Screenshot", options.args.Screenshot)
	ACR:RegisterOptionsTable("ReadySetDing_Sound", options.args.Sound)
	ACR:RegisterOptionsTable("ReadySetDing_AutoGratz", options.args.AutoGratz)
	ACR:RegisterOptionsTable("ReadySetDing_Stats", options.args.Stats)
	ACR:RegisterOptionsTable("ReadySetDing_Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	ACR:RegisterOptionsTable("ReadySetDing_RandomMessage", options.args.RandomMessage)
	ACR:RegisterOptionsTable("ReadySetDing_RandomMessageGuild", options.args.RandomMessageGuild)

	optionsFrame.Main = ACD:AddToBlizOptions("ReadySetDing_Main", titleName)
	optionsFrame.Advanced = ACD:AddToBlizOptions("ReadySetDing_Advanced", "|TInterface\\Icons\\Trade_Engineering:16:16:1:0"..cropped.."|t  "..ADVANCED, titleName)
	optionsFrame.GuildMemberDings = ACD:AddToBlizOptions("ReadySetDing_GuildMemberDings", "|TInterface\\GuildFrame\\GuildLogo-NoLogo:16:16:1:0:64:64:14:51:14:51|t  "..L["Guild Members"], titleName)
	optionsFrame.Screenshot = ACD:AddToBlizOptions("ReadySetDing_Screenshot", "|TInterface\\Icons\\inv_misc_spyglass_03:16:16:1:0"..cropped.."|t  "..L["Screenshot"], titleName)
	optionsFrame.Sound = ACD:AddToBlizOptions("ReadySetDing_Sound", "|TInterface\\Icons\\INV_Misc_Bell_01:16:16:1:0"..cropped.."|t  Sound", titleName)
	optionsFrame.AutoGratz = ACD:AddToBlizOptions("ReadySetDing_AutoGratz", "|TInterface\\Icons\\INV_Misc_Gift_05:16:16:1:0"..cropped.."|t  "..L["Auto Gratz"], titleName)
	optionsFrame.Stats = ACD:AddToBlizOptions("ReadySetDing_Stats", "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:1:0"..cropped.."|t  "..L["Stats"], titleName)
	optionsFrame.Profiles = ACD:AddToBlizOptions("ReadySetDing_Profiles", "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:0"..cropped.."|t  "..L["Profiles"], titleName)
	
	ACD:SetDefaultSize("ReadySetDing_RandomMessage", 600, 400)
	ACD:SetDefaultSize("ReadySetDing_RandomMessageGuild", 600, 400)

	self:RegisterChatCommand("rsd", "SlashCommand")
	self:RegisterChatCommand("readyset", "SlashCommand")
	self:RegisterChatCommand("readysetding", "SlashCommand")

	-- Define AceDB saved variables if not yet defined
	char.levelTimeList = char.levelTimeList or {}
	char.totalTimeList = char.totalTimeList or {}
	char.experienceList = char.experienceList or {}
	char.unixTimeList = char.unixTimeList or {}
	char.dateStampList = char.dateStampList or {}
	char.levelSummary = char.levelSummary or {}

	if not profile.enableAddOn then
		self:Disable()
	end
end

function RSD:OnEnable()
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("TIME_PLAYED_MSG")

	-- Guild Member
	self:RegisterEvent("GUILD_ROSTER_UPDATE")

	-- (Real ID) Friends
	self:RegisterEvent("FRIENDLIST_UPDATE")

	-- Kills, Deaths
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	-- Auto Gratz
	self:RegisterEvent("CHAT_MSG_PARTY", "CHAT_MSG")
	self:RegisterEvent("CHAT_MSG_GUILD", "CHAT_MSG")
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")

	-- AFK Time
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")

	-- level 1 data
	if player.level == 1 then
		char.unixTimeList[1] = char.unixTimeList[1] or time()
		char.dateStampList[1] = char.dateStampList[1] or date("%Y.%m.%d %H:%M:%S")
	end
	
	if profile.Stopwatch and player.level < 85 then
		StopwatchFrame:Show()
		StopwatchTicker.timer = TPM_current + AddedTime()
		Stopwatch_Play()
	end

	--------------
	--- Timers ---
	--------------

	-- wait 7 sec for other AddOns first that want to request /played
	self:ScheduleTimer(function()
		if TPM_total == 0 then
			filterPlayed = true
			RequestTimePlayed()
		end
	end, 7)

	self:ScheduleRepeatingTimer(function()
		GuildRoster() -- Update Guild Members
		ShowFriends() -- Update Friends (untested)
	end, 11)

	self:ScheduleRepeatingTimer(function() self:PartyDings() end, 3)	

	self:ScheduleRepeatingTimer(function()
		currentTime = TPM_current + AddedTime()
		totalTime = TPM_total + AddedTime()
		isStopwatch = player.level < 85 and currentTime < MAX_TIMER_SEC
	end, 1)
end

function RSD:OnDisable()
	self:UnregisterAllEvents() 
	self:CancelAllTimers()
	if profile.Stopwatch then
		Stopwatch_Clear()
		StopwatchFrame:Hide()
	end
end

	--------------------------
	--- Callback Functions ---
	--------------------------
	
function RSD:RefreshConfig()
	profile, realm, char = self.db.profile, self.db.realm, self.db.char
	stats = char.stats
end

-- refresh all menus
function RSD:NotifyChange()
	ACR:NotifyChange("ReadySetDing_Main")
	ACR:NotifyChange("ReadySetDing_Advanced")
	ACR:NotifyChange("ReadySetDing_GuildMemberDings")
	ACR:NotifyChange("ReadySetDing_Stats")
end

-- gray out options when AddOn disabled
function RSD:OptionsDisabled()
	return not self:IsEnabled()
end

function RSD:SlashCommand(input)
	if #strtrim(input) == 0 then
		InterfaceOptionsFrame_OpenToCategory(optionsFrame.Main)
	elseif input == "enable" or input == "on" or input == "1" then
		if not profile.enableAddOn then
			self:Enable()
			profile.enableAddOn = true
			self:Print("|cffADFF2FEnabled|r")
		else
			self:Print("Already |cffADFF2FEnabled|r")
		end
		self:NotifyChange()
	elseif input == "disable" or input == "off" or input == "0" then
		if profile.enableAddOn then
			self:Disable()
			profile.enableAddOn = false
			self:Print("|cffFF2424Disabled|r")
		else
			self:Print("Already |cffFF2424Disabled|r")
		end
		self:NotifyChange()

	-- dunno if someone would actually, if ever, use these shortcuts ..
	elseif input == "stats" or input == "stat" then
		InterfaceOptionsFrame_OpenToCategory(optionsFrame.Stats)
	elseif input == "export" or input == "exp" or input == "xp" then
		self:ExportData(true)

	else
		print("|cff2E9AFE/rsd|r |cffADFF2Fon|r: Enable AddOn\n|cff2E9AFE/rsd|r |cffFF2424off|r: Disable AddOn\n|cff2E9AFE/rsd|r |cffFFFF00stats|r: Open Stats\n|cff2E9AFE/rsd|r |cff71D5FFexport|r: Export to |cffFFFF00"..SLASH_SAY2.."|r (|cffFF2424SPAM!|r)")
	end
end

function RSD:GuildEmblem()
	if GuildFrameTabardEmblem then
		char.guildTexCoord = {GuildFrameTabardEmblem:GetTexCoord()}
	end
	if IsInGuild() and char.guildTexCoord then
		return format("|TInterface\\GuildFrame\\GuildEmblemsLG_01:30:30:-3:1:32:32:%s:%s:%s:%s|t", char.guildTexCoord[1]*32, char.guildTexCoord[7]*32, char.guildTexCoord[2]*32, char.guildTexCoord[8]*32)
	else
		return "|TInterface\\GuildFrame\\GuildLogo-NoLogo:30:30:-3:1|t"
	end
end

function RSD:TimetoString(value, fullString)
	local seconds = mod(floor(value), 60)
	local minutes = mod(floor(value/60), 60)
	local hours = mod(floor(value/3600), 24)
	local days = floor(value/86400)

	-- use a Frame object to get rid of the pipe characters
	-- so that they can be used in SendChatMessage
	local fseconds = bttn:GetText(bttn:SetFormattedText(D_SECONDS, seconds))
	local fminutes = bttn:GetText(bttn:SetFormattedText(D_MINUTES, minutes))
	local fhours = bttn:GetText(bttn:SetFormattedText(D_HOURS, hours))
	local fdays = bttn:GetText(bttn:SetFormattedText(D_DAYS, days))

	if value >= 86400 then
		return (hours > 0 or fullString) and format("%s, %s", fdays, fhours) or fdays
	elseif value >= 3600 then
		return (minutes > 0 or fullString) and format("%s, %s", fhours, fminutes) or fhours
	elseif value >= 60 then
		if seconds >= 6 or fullString then
			if profile.timeFormat == 1 then
				return format("%s, %s", fminutes, fseconds)
			else
				local xseconds = floor(seconds/6)
				if xseconds == 1 then
					-- problem: incorrectly returned as "x.1 minute"
					return format("%s.%s %s", minutes, xseconds, MINUTES1)
				else
					return bttn:GetText(bttn:SetFormattedText(D_MINUTES2, minutes.."."..xseconds))
				end
			end
		else
			return fminutes
		end
	elseif value >= 0 then
		return fseconds
	else
		return "ERROR: "..value
	end
end

function RSD:TimeDiff(example)
	local timeDiff = 0
	if char.levelTimeList[player.level] then
		if example then
			timeDiff = char.levelTimeList[player.level] - currentTime
		else
			local levelTime = char.levelTimeList
			if levelTime[player.level-1] then
				timeDiff = levelTime[player.level-1] - levelTime[player.level]
			end
		end
	end
	if timeDiff < 0 then
		return "- "..self:TimetoString(-timeDiff)
	elseif timeDiff > 0 then
		return "+ "..self:TimetoString(timeDiff)
	else
		return L["[No Data]"]
	end
end

-- update [AFK]
local function TimeAFK()
	timeAFK2 = time()
	stats.timeAFK = stats.timeAFK + (timeAFK2-timeAFK1)
	stats.totalAFK = stats.totalAFK + (timeAFK2-timeAFK1)
end

function RSD:LevelSummary()
	local level = player.level
	if char.levelTimeList[level] and char.levelCounter then
		char.levelSummary[char.levelCounter] = format(" %s |cffF6ADC6%s|r - |cff71D5FF%s|r:  |cffB6CA00%s|r        %s:  |cff71D5FF%s|r", LEVEL, level-1, level, self:TimetoString(char.levelTimeList[level], true), L["Total"], self:TimetoString(char.totalTimeList[level], true))
	end
	-- sanity check for strjoin, or it will choke on a nil that was lying around :/
	for i = 1, table_maxn(char.levelSummary) do
		char.levelSummary[i] = char.levelSummary[i] or " |cffFF0000N/A|r"
	end
	return strjoin("\n", unpack(char.levelSummary))
end

-- [SPEED]; look for a 3 or smaller level difference
function RSD:RecentLevelSpeed()
	local levelTime = char.levelTimeList
	for i = 3, 1, -1 do
		if levelTime[player.level-i] then
			return ((levelTime[player.level-i] + (TPM_total-char.totalTimeList[player.level-i])) + AddedTime()) / (i+1)
		end
	end
	return levelTime[player.level] and (levelTime[player.level] + currentTime) or L["[No Data]"]
end

local cache = {}

local function GetClassColor(class)
	if cache[class] then
		return cache[class]
	else
		cache[class] = format("%02X%02X%02X", RAID_CLASS_COLORS[class].r*255, RAID_CLASS_COLORS[class].g*255, RAID_CLASS_COLORS[class].b*255)
		return cache[class]
	end
end

function RSD:OutputFrame(msg, example)
	if profile.outputFrame == 1 then
		if example then msg = "UIErrorsFrame" end
		UIErrorsFrame:AddMessage(msg)
	elseif profile.outputFrame ==  2 then
		if example then msg = "RaidWarningFrame" end
		RaidNotice_AddMessage(RaidWarningFrame, msg, {r=1, g=1, b=1})
	elseif profile.outputFrame ==  3 then
		if example then msg = "RaidBossEmoteFrame" end
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, {r=1, g=1, b=1})
	else
		for i = 1, NUM_CHAT_WINDOWS do
			if example then msg = "ReadySetDing: |cff71D5FF"..i..". "..GetChatWindowInfo(i).."|r" end
			if i == profile.outputFrame-3 then
				_G["ChatFrame"..i]:AddMessage(msg)
			end
		end
	end
end

local autoGratzTimer

function RSD:AutoGratz(msgType, name)
	local msg = profile.autoGratzMsg[random(#profile.autoGratzMsg)]
	if not msg then print("[ERROR] No AutoGratz Message") return end
	msg = gsub(msg, "%[[Nn][Aa][Mm][Ee]%]", (random(2) == 1 and name or name:lower()))
	msg = gsub(msg, "%[[Rr][Tt]%]", "{rt"..random(8).."}")
	msg = gsub(msg, "%[[Gg][Zz]%]", gratzMsg[random(#gratzMsg)])
	msg = gsub(msg, "%[[Ss][Mm][Ii][Ll][Ii][Ee]%]", smilieMsg[random(#smilieMsg)])
	autoGratzTimer = self:ScheduleTimer(function()
		SCM(msg, msgType)
	end, profile.autoGratzDelay == 0 and random(30, 200) / 10 or profile.autoGratzDelay)
end

-- http://www.wowhead.com/achievements=2
-- GetStatistic(AchievementID) returns a string type, but it will be "coerced" to a number type, I guess
function RSD:AchievementStatistics(info)
	local questsTotal, questsDaily, totalKills, totalDeaths

	if info == "quests" then
		if GS(98) == "--" then questsTotal = 0 else questsTotal = GS(98) end -- 98 = Quests completed
		if GS(97) == "--" then questsDaily = 0 else questsDaily = GS(97) end -- 97 = Daily quests completed
		-- Quests Completed(Achievement) = Quests completed(Statistic) - Daily quests completed(Statistic); thank you aldon@wowhead
		return questsTotal - questsDaily, questsDaily
	elseif info == "kills" then
		if GS(1197) == "--" then totalKills = 0 else totalKills = GS(1197) end -- 1197 = Total kills
		return totalKills
	elseif info == "deaths" then
		if GS(60) == "--" then totalDeaths = 0 else totalDeaths = GS(60) end -- 60 = Total Deaths
		return totalDeaths
	end
end

-- export level data to print/say (without spamming the server)
function RSD:ExportData(exportSay)
	local export
	local a, b, c = {}, {}, {} -- delay; coloring for print; showed data type

--	why is there a throttle here anyway ... button bashers? spammers? xD
--	at least this will make sure LoggingChat() will be correctly set to it's previous value
	if time() > (cd.export or 0) then
		cd.export = time() + 17

		if exportSay then
			a[1], a[2], a[3], a[4], a[5] = 0, 4, 8, 12, 16
			b[1], b[2], b[3], b[4] = "", "", "", ""
			export = SCM

			local isLogging = LoggingChat()
			LoggingChat(true)

			self:ScheduleTimer(function()
				LoggingChat(isLogging)
				if c[1] or c[2] or c[3] or c[4] or c[5] then
					self:Print("Logged Data to |cff71D5FF..\\Logs\\WoWChatLog.txt|r")
				end
			end, 17)
		else
			a[1], a[2], a[3], a[4], a[5] = 0, 0.5, 1, 1.5, 2.0
			b[1], b[2], b[3], b[4] = "|cffF6ADC6", "|cffB6CA00", "|cff71D5FF", "|r"
			export = print
		end

		-- Level Time
		self:ScheduleTimer(function()
			for i = 2, player.maxLevel do
				if char.levelTimeList[i] then
					if not c[1] then export("# "..L["Level Time"]); c[1] = true end
					export(b[1]..i-1 ..b[4].."-"..b[2]..i..b[4]..": "..b[3]..char.levelTimeList[i]..b[4])
				end
			end
		end, a[1])
		-- Total Time
		self:ScheduleTimer(function()
			for i = 2, player.maxLevel do
				if char.totalTimeList[i] then
					if not c[2] then export("# "..L["Total Time"]); c[2] = true end
					export(b[1].. 1 ..b[4].."-"..b[2]..i..b[4]..": "..b[3]..char.totalTimeList[i]..b[4])
				end
			end
		end, a[2])
		-- Experience / Hour
		self:ScheduleTimer(function()
			for i = 2, player.maxLevel do
				if char.experienceList[i] then
					if not c[3] then export("# "..XP.."/"..HOUR); c[3] = true end
					export(b[1]..i-1 ..b[4].."-"..b[2]..i..b[4]..": "..b[3]..char.experienceList[i]..b[4])
				end
			end
		end, a[3])
		-- Timestamp
		self:ScheduleTimer(function()
			for i = 1, player.maxLevel do
				if char.dateStampList[i] then
					if not c[4] then export("# Timestamp"); c[4] = true end
					export(b[2]..i..b[4]..": "..b[3]..char.dateStampList[i]..b[4])
				end
			end
		end, a[4])
		-- Unix Timestamp
		self:ScheduleTimer(function()
			for i = 1, player.maxLevel do
				if char.unixTimeList[i] then
					if not c[5] then export("# Unix Timestamp"); c[5] = true end
					export(b[2]..i..b[4]..": "..b[3]..char.unixTimeList[i]..b[4])
				end
			end
		end, a[5])
	end
end

function RSD:GetGuildExampleMsg(index)
	--	GetNumGuildMembers returns 0 early in the game
	if IsInGuild() and GetNumGuildMembers() > 0 then
		local name, rank, _, level, class, zone, _, _, _, _, classFileName = GetGuildRosterInfo(random((GetNumGuildMembers())))
		if level == 85 then
			-- wow .. someone dinged level 86 :)
			level = 84
		end
		return "   "..self:ReplaceTextG(profile.guildMemberDingMsg[index], true, name, level+1, class, rank, zone, " in "..self:TimetoString(random(600, 7200)), " ("..format("%.2f", random(10, 30)/10).." "..HOUR.."/"..LEVEL..")", classFileName)
	else
		return "   |cffF6ADC6"..L["[No Data]"].."|r"
	end
end

function RSD:ValidateMessage(msg)
	-- my patterns. just. suck. ><
	local msg = gsub(self:ReplaceText(msg, true), "|r", "")
	msg = gsub(msg, "|cff......", "")
	msg = gsub(msg, "|T.-|t", "{rtN}")

	-- show an error if message length exceeds 127 or 255 chars
	local len = strlen(msg)
	if len > 127 and profile.BNetBroadcast then
		self:Print("|cff71D5FFReal ID|r |cffFF0000Message > 127 chars|r|r ("..len..")")
	end
	if len > 255 then
		self:Print("|cffFF0000Message > 255 chars|r ("..len..")")
	end
end

function RSD:ReplaceText(msg, isExample)
	-- sanity check, or gsub will choke on it
	if not msg then return "[ERROR] No Message" end

	local gsub = gsub

	-- ** massive great wall of gsubs instantly crits you for a ludicrous amount of antimatter dmg **
	-- ** your computer gets struck by a coronal loop .. unless you're happily reading this in the year 2014 .. **

	if isExample then
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%-%]", "|cffF6ADC6"..player.level.."|r")
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%]", "|cffF6ADC6"..(player.level == GetMaxPlayerLevel() and "[Max Level]" or player.level + 1).."|r")
		msg = msg:gsub("%[[Rr][Ee][Mm]%]", "|cffF6ADC6"..player.maxLevel - (player.level+1).."|r")
		msg = msg:gsub("%[[Mm][Aa][Xx]]", "|cffF6ADC6"..player.maxLevel.."|r")
		msg = msg:gsub("%[[Tt][Ii][Mm][Ee]%]", "|cff71D5FF"..self:TimetoString(currentTime).."|r")
		msg = msg:gsub("%[[Tt][Oo][Tt][Aa][Ll]%]", "|cff71D5FF"..self:TimetoString(totalTime).."|r")
		msg = msg:gsub("%[[Dd][Ii][Ff][Ff]%]", "|cff71D5FF"..self:TimeDiff(true).."|r")
		msg = msg:gsub("%[[Aa][Ff][Kk]%]", "|cff71D5FF"..self:TimetoString(stats.timeAFK).."|r")
		msg = msg:gsub("%[[Aa][Ff][Kk]%+%]", "|cff71D5FF"..self:TimetoString(stats.totalAFK).."|r")
		msg = msg:gsub("%[[Dd][Aa][Tt][Ee]%]", "|cff0070DD"..date("%m/%d/%y %H:%M").."|r")
		msg = msg:gsub("%[[Dd][Aa][Tt][Ee]2%]", "|cff0070DD"..date("%Y.%m.%d %H:%M").."|r")
		msg = msg:gsub("%[[Xx][Pp]%]", "|cffB6CA00"..floor(UnitXP("player")/(currentTime/3600)).."|r")
		if self:RecentLevelSpeed() == L["[No Data]"] then
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%]", "|cffF6ADC6"..L["[No Data]"].."|r")
		else
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%]", "|cffB6CA00"..format("%.2f",self:RecentLevelSpeed()/3600).."|r")
		end
		if player.level > 1 then
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%+%]", "|cffB6CA00"..format("%.2f",totalTime/(3600*(player.level-1))).."|r")
		else
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%+%]", "|cffF6ADC6"..L["[No Data]"].."|r")
		end
		msg = msg:gsub("%[[Kk][Ii][Ll][Ll][Ss]%]", "|cffFF0000"..stats.kills.."|r")
		msg = msg:gsub("%[[Kk][Ii][Ll][Ll][Ss]%+%]", "|cffFF0000"..self:AchievementStatistics("kills").."|r")
		msg = msg:gsub("%[[Dd][Ee][Aa][Tt][Hh][Ss]%]", "|cffFF0000"..stats.deaths.."|r")
		msg = msg:gsub("%[[Dd][Ee][Aa][Tt][Hh][Ss]%+%]", "|cffFF0000"..self:AchievementStatistics("deaths").."|r")
		msg = msg:gsub("%[[Qq][Uu][Ee][Ss][Tt][Ss]%]", "|cff58ACFA"..self:AchievementStatistics("quests").."|r")
		if GetRealZoneText() then
			msg = msg:gsub("%[[Zz][Oo][Nn][Ee]%]", "|cff58ACFA"..GetRealZoneText().."|r") -- not sure if its too early or already avaiable at this point
		else
			msg = msg:gsub("%[[Zz][Oo][Nn][Ee]%]", "|cffF6ADC6[No Zone Info]|r")
		end
		if IsInGuild() and GetGuildInfo("player") then
			msg = msg:gsub("%[[Gg][Uu][Ii][Ll][Dd]%]", "|cffADFF2F"..GetGuildInfo("player").."|r")
		else
			msg = msg:gsub("%[[Gg][Uu][Ii][Ll][Dd]%]", "|cffF6ADC6[No Guild]|r")
		end
		msg = msg:gsub("%[[Nn][Aa][Mm][Ee]%]", "|cffADFF2F"..player.name.."|r")
		msg = msg:gsub("%[[Cc][Ll][Aa][Ss][Ss]%]", "|cffADFF2F"..player.class.."|r")
		msg = msg:gsub("%[[Rr][Aa][Cc][Ee]%]", "|cffADFF2F"..player.race.."|r")
		msg = msg:gsub("%[[Ff][Aa][Cc][Tt][Ii][Oo][Nn]%]", "|cffADFF2F"..player.faction.."|r")
		msg = msg:gsub("%[[Rr][Ee][Aa][Ll][Mm]%]", "|cffADFF2F"..player.realm.."|r")
		for i = 1, 8 do
			msg = msg:gsub("%{[Rr][Tt]"..i.."%}", "|T"..RT..i..":12|t")
		end
		msg = msg:gsub("%{[Xx]%}", "|T"..RT.."7:12|t")
		msg = msg:gsub("%{[Ss][Tt][Aa][Rr]%}", "|T"..RT.."1:12|t")
		msg = msg:gsub("%{[Cc][Ii][Rr][Cc][Ll][Ee]%}", "|T"..RT.."2:12|t")
		msg = msg:gsub("%{[Dd][Ii][Aa][Mm][Oo][Nn][Dd]%}", "|T"..RT.."3:12|t")
		msg = msg:gsub("%{[Tt][Rr][Ii][Aa][Nn][Gg][Ll][Ee]%}", "|T"..RT.."4:12|t")
		msg = msg:gsub("%{[Mm][Oo][Oo][Nn]%}", "|T"..RT.."5:12|t")
		msg = msg:gsub("%{[Ss][Qq][Uu][Aa][Rr][Ee]%}", "|T"..RT.."6:12|t")
		msg = msg:gsub("%{[Cc][Rr][Oo][Ss][Ss]%}", "|T"..RT.."7:12|t")
		msg = msg:gsub("%{[Ss][Kk][Uu][Ll][Ll]%}", "|T"..RT.."8:12|t")
	else
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%-%]", player.level-1)
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%]", player.level)
		msg = msg:gsub("%[[Rr][Ee][Mm]%]", player.maxLevel - player.level)
		msg = msg:gsub("%[[Mm][Aa][Xx]]", player.maxLevel)
		msg = msg:gsub("%[[Tt][Ii][Mm][Ee]%]", self:TimetoString(char.levelTimeList[player.level]))
		msg = msg:gsub("%[[Tt][Oo][Tt][Aa][Ll]%]", self:TimetoString(char.totalTimeList[player.level]))
		msg = msg:gsub("%[[Dd][Ii][Ff][Ff]%]", self:TimeDiff())
		msg = msg:gsub("%[[Aa][Ff][Kk]%]", self:TimetoString(stats.timeAFK))
		msg = msg:gsub("%[[Aa][Ff][Kk]%+%]", self:TimetoString(stats.totalAFK))
		msg = msg:gsub("%[[Dd][Aa][Tt][Ee]%]", date("%m/%d/%y %H:%M"))
		msg = msg:gsub("%[[Dd][Aa][Tt][Ee]2%]", date("%Y.%m.%d %H:%M"))
		msg = msg:gsub("%[[Xx][Pp]%]", char.experienceList[player.level])
		if self:RecentLevelSpeed() == L["[No Data]"] then
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%]", L["[No Data]"])
		else
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%]", format("%.2f",self:RecentLevelSpeed()/3600))
		end
		if player.level > 1 then
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%+%]", format("%.2f",(TPM_total+AddedTime())/(3600*(player.level-1))))
		else
			msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%+%]", L["[No Data]"])
		end
		msg = msg:gsub("%[[Kk][Ii][Ll][Ll][Ss]%]", stats.kills)
		msg = msg:gsub("%[[Kk][Ii][Ll][Ll][Ss]%+%]", self:AchievementStatistics("kills"))
		msg = msg:gsub("%[[Dd][Ee][Aa][Tt][Hh][Ss]%]", stats.deaths)
		msg = msg:gsub("%[[Dd][Ee][Aa][Tt][Hh][Ss]%+%]", self:AchievementStatistics("deaths"))
		msg = msg:gsub("%[[Qq][Uu][Ee][Ss][Tt][Ss]%]", self:AchievementStatistics("quests"))
		msg = msg:gsub("%[[Zz][Oo][Nn][Ee]%]", GetRealZoneText())
		msg = msg:gsub("%[[Gg][Uu][Ii][Ll][Dd]%]", select(1, GetGuildInfo("player")) or "[No Guild]")
		msg = msg:gsub("%[[Nn][Aa][Mm][Ee]%]", player.name)
		msg = msg:gsub("%[[Cc][Ll][Aa][Ss][Ss]%]", player.class)
		msg = msg:gsub("%[[Rr][Aa][Cc][Ee]%]", player.race)
		msg = msg:gsub("%[[Ff][Aa][Cc][Tt][Ii][Oo][Nn]%]", player.faction)
		msg = msg:gsub("%[[Rr][Ee][Aa][Ll][Mm]%]", player.realm)
		msg = msg:gsub("%[[Rr][Tt]%]", "{rt"..random(8).."}")
	end
	return msg
end

function RSD:ReplaceTextG(msg, isExample, name, level, class, rank, zone, time, levelSpeed, classColor)
	if not msg then return "[ERROR] No Message" end

	local gsub = gsub

	if isExample then
		msg = msg:gsub("%[[Nn][Aa][Mm][Ee]%]", format("|cff%s|Hplayer:%s|h%s|h|r", GetClassColor(classColor), name, name))
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%-%]", "|cffF6ADC6"..level-1 .."|r")
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%]", "|cffADFF2F"..level.."|r")
		msg = msg:gsub("%[[Cc][Ll][Aa][Ss][Ss]%]", "|cff71D5FF"..class.."|r")
		msg = msg:gsub("%[[Rr][Aa][Nn][Kk]%]", "|cffADFF2F"..rank.."|r")
		if zone then -- guild member's zone sometimes is nil
			msg = msg:gsub("%[[Zz][Oo][Nn][Ee]%]", "|cffF6ADC6"..zone.."|r")
		else
			msg = msg:gsub("%[[Zz][Oo][Nn][Ee]%]", "")
		end
		msg = msg:gsub("%[[Tt][Ii][Mm][Ee]%]", "|cff71D5FF"..time.."|r")
		msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%]", "|cffB6CA00"..levelSpeed.."|r")
	else
		msg = msg:gsub("%[[Nn][Aa][Mm][Ee]%]", name)
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%-%]", level-1)
		msg = msg:gsub("%[[Ll][Ee][Vv][Ee][Ll]%]", level)
		msg = msg:gsub("%[[Cc][Ll][Aa][Ss][Ss]%]", class)
		msg = msg:gsub("%[[Rr][Aa][Nn][Kk]%]", rank)
		msg = msg:gsub("%[[Zz][Oo][Nn][Ee]%]", zone or "")
		msg = msg:gsub("%[[Tt][Ii][Mm][Ee]%]", time)
		msg = msg:gsub("%[[Ss][Pp][Ee][Ee][Dd]%]", levelSpeed)
	end
	return msg
end

	-----------------------
	--- Event Functions ---
	-----------------------

function RSD:PLAYER_LEVEL_UP(event, level)
	-- update here, since UnitLevel("player") does not yet return the new value
	player.level = level
	playerDinged, filterPlayed = true, true
	RequestTimePlayed() -- call TIME_PLAYED_MSG

	-- reset if leveled 22+ times
	if not char.levelCounter or char.levelCounter > 21 then
		char.levelCounter = 0
	end
	char.levelCounter = char.levelCounter + 1
end

function RSD:TIME_PLAYED_MSG(event, ...)
--	these variables should be file-local scope -> vararg
	TPM_total, TPM_current = ...
	lastPlayed = time()

	if playerDinged then
		playerDinged = false

		local prevTime = char.totalTimeList[player.level-1]
		if prevTime then
			-- TotalTime @ Ding - TotalTime @ previous Ding
			levelTime = TPM_total - prevTime
		else
			-- if no data for previous level, fall back to less accurate data
			-- Last undinged LevelTime + (dinged TotalTime - last undinged TotalTime)
			levelTime = TPM_current2 + (TPM_total-TPM_total2)
		end

		-- save player data to arrays
		local level = player.level
		char.levelTimeList[level] = levelTime
		char.totalTimeList[level] = TPM_total
		char.experienceList[level] = floor(player.XPMax/(levelTime/3600))
		char.unixTimeList[level] = time()
		char.dateStampList[level] = date("%Y.%m.%d %H:%M:%S")

		-- play custom sound if the user supplied one, otherwise it will silently fail
		self:ScheduleTimer(function()
			if profile.customSound == soundExamples[2] then
				PSF(soundExamples[random(3, #soundExamples)], "Master")
			else
				PSF(profile.customSound, "Master")
			end
		end, 2)

		local text = self:ReplaceText(profile.dingMsg[profile.randomMessage and random(2, 6) or 1])
		local language
		if profile.Language == 2 then
			-- random language
			language = GetLanguageByIndex(random(GetNumLanguages()))
		elseif profile.Language > 2 then
			language = GetLanguageByIndex(profile.Language-2)
		end

		local instanceType = select(2, IsInInstance())
	--	Announce Ding Message
		if profile.partyAnnounce then
			-- announce to /say instead when soloing instance
			local msgType
			if instanceType == "none" or instanceType == "party" then
				msgType = GetNumPartyMembers() > 0 and "PARTY" or "SAY"
			elseif instanceType == "raid" then
				msgType = "RAID"
			elseif instanceType == "pvp" then
				msgType = "BATTLEGROUND"
			end
			self:ScheduleTimer(function()
				-- ugly fix, cut/slice the msg in two and send in two messages
				if strlen(text) > 255 then
					SCM(strsub(text, 1, 255), msgType, language)
					SCM(strsub(text, 256), msgType, language)
				else
					SCM(text, msgType, language)
				end
			end, profile.announceDelay)
		end

		-- local output to yourself; useful for in screenshots
		if profile.RaidWarningOutput then
			RaidNotice_AddMessage(RaidWarningFrame, text, {r=1, g=1, b=1})
		end

	--	Zone Announce
		if profile.zoneAnnounce then
			local channel = {GetChannelList()}
			for i = 1, 10 do
				-- the General channel could possibly have any channel number assigned 
				-- GetChannelName(GENERAL) doesn't seem to work, maybe only for custom named channels..
				if channel[i*2] == GENERAL then
					self:ScheduleTimer(function() SCM(text, "CHANNEL", nil, i*2-1) end, profile.announceDelay)
				end
			end
		end

	--	Guild Announce
		if profile.guildAnnounce and IsInGuild() then
			self:ScheduleTimer(function() SCM(text, "GUILD", language) end, profile.announceDelay)
		end

	--	Real ID Broadcast
		if profile.BNetBroadcast then
			-- save current Real ID Broadcast message
			self:ScheduleTimer(function()
				local broadcastMsg = select(3, BNGetInfo())
				BNSetCustomMessage(strsub(text, 1, 127))
				BNSetCustomMessage(broadcastMsg)
			end, profile.announceDelay)
		end

		if profile.dingEmote then
			DoEmote(EMOTE389_TOKEN, "none")
		end

	--	Screenshot
		if profile.Screenshot then
			-- Hide UI (+ optional delay) to show the LevelUp animation
			local timeHideUI = profile.screenshotDelay-1
			if timeHideUI < 0 then timeHideUI = 0 end -- change any negative value to zero
			-- get original alpha; for some reason its always a bit different than the set value e.g. 0.9 -> 0.988... 0.5 -> 0.498...
			local originalAlpha = UIParent:GetAlpha()
			-- got problems with timing hiding and showing UI again,
			-- so trying to Hide()/SetAlpha(0) 1 sec before screenshot
			if profile.screenshotHideUI then
				self:ScheduleTimer(function() UIParent:SetAlpha(0) end, timeHideUI)
			end
			self:ScheduleTimer(function() Screenshot() end, profile.screenshotDelay)
			if profile.screenshotHideUI then
				self:ScheduleTimer(function() UIParent:SetAlpha(originalAlpha) end, profile.screenshotDelay+1)
			end
		end

	--	Temporarily pause Stopwatch
		if profile.Stopwatch and player.level < 85 and TPM_current < MAX_TIMER_SEC then
			Stopwatch_Pause()
			self:ScheduleTimer(function()
				StopwatchTicker.timer = TPM_current + AddedTime()
				Stopwatch_Play()
			end, 30)
		end

		stats.kills, stats.deaths, stats.timeAFK = 0, 0, 0
		-- update level summary
		self:LevelSummary()
	else
		if profile.Stopwatch then
			if player.level < 85 and TPM_current < MAX_TIMER_SEC then
				-- currentTime var isn't updated yet
				StopwatchTicker.timer = TPM_current
			else
				Stopwatch_Clear()
				StopwatchFrame:Hide()
			end
		end
	end

	-- update/prepare stuff for next levelup
	TPM_total2, TPM_current2 = TPM_total, TPM_current
	player.XPMax = UnitXPMax("player")

	if InterfaceOptionsFrame:IsShown() then
		currentTime = TPM_current + AddedTime()
		totalTime = TPM_total + AddedTime()
		self:NotifyChange()
	end
end

local friendsLocal, friendsBnet = {}, {}

-- (Real ID) friends
function RSD:FRIENDLIST_UPDATE(event, ...)
	if profile.friendDings then
		for i = 1, select(2, GetNumFriends()) do
			local name, level, class = GetFriendInfo(i)
			if friendsLocal[name] and level > friendsLocal[name] then
				self:OutputFrame(format("|cff82C5FF|Hplayer:%s|h[%s]|h|r dinged %s |cffADFF2F%s|r", name, name, LEVEL, level))
			end
			if name then
				friendsLocal[name] = level
			end
		end
	end
	if profile.RealID_Dings then
		for i = 1, select(2, BNGetNumFriends()) do
			local presenceID, firstname, surname = BNGetFriendInfo(i)
			local _, name, _, realm, _, _, race, class, _, _, level = BNGetToonInfo(i)
			-- stupid starcraft 2; and just why is level a string type
			level = tonumber(level)
			local fullName = firstname.." "..surname
			local classColor = GetClassColor(revLOCALIZED_CLASS_NAMES[class] or "PRIEST")
			-- BNplayer might taint whatever it calls on rightclick
			local playerLink = format("|cff82C5FF|HBNplayer:%s:%s|h[%s]|r (|TInterface\\ChatFrame\\UI-ChatIcon-WOW:14:14:0:1|t|cff%s%s|h|r|cff82C5FF)|r", fullName, presenceID, fullName, classColor, name)
			if friendsBnet[name] and level and friendsBnet[name] > 0 and level > friendsBnet[name] then
				self:OutputFrame(format("|TInterface\\FriendsFrame\\UI-Toast-ToastIcons.tga:16:16:0:0:128:64:2:29:34:61|t%s dinged %s |cffADFF2F%s|r", playerLink, LEVEL, level))
			end
			friendsBnet[name] = level
		end
	end
end

local group = {}

function RSD:PartyDings()
	if profile.partyDings then
		local numRaidMembers = GetNumRaidMembers()
		local numPartyMembers = GetNumPartyMembers()

		local numGroupMembers = numRaidMembers > 0 and numRaidMembers or numPartyMembers > 0 and numPartyMembers or 0
		local groupType = numRaidMembers > 0 and "raid" or numPartyMembers > 0 and "party" 

		for i = 1, numGroupMembers do
			local guid = UnitGUID(groupType..i)
			local level = UnitLevel(groupType..i)
			local name, realm = UnitName(groupType..i)
			-- sanity checks
			if guid and group[guid] and group[guid] > 0 and level > group[guid] and name ~= player.name then
				self:OutputFrame(format("|cff%s|Hplayer:%s|h[%s]|h|r dinged %s |cffADFF2F%s|r", GetClassColor(select(2, UnitClass(groupType..i))), name..(realm and "-"..realm or ""), name, LEVEL, level))
			end
			group[guid] = level
		end
	end
end

-- this part is rather messy
function RSD:GUILD_ROSTER_UPDATE()
	if IsInGuild() and (profile.GuildMemberDings or profile.guildMemberAnnounce) then
		-- check all guild members (including offlines); imagine this for a guild with 1000 members ><
		-- this is to avoid conflicts with other addons that change SetGuildRosterShowOffline(), and for level change diffs
		for i = 1, GetNumGuildMembers() do
			local name, rank, _, level, class, zone, _, _, _, _, classFileName = GetGuildRosterInfo(i)

			-- sanity check: in rare cases GetGuildRosterInfo() returns only a nil
			-- although I kinda think that realm[nil] would evaluate to a nil anyway ..
			if name and realm[name] then
				-- save (last 3 levels) level speed to [0] key
				for j = 3, 1, -1 do
					-- ignore the [0] and [1] key values
					if realm[name][level-j] and level-j ~= 1 and level-j ~= 0 then
						realm[name][0] = (time()-realm[name][level-j][1]) / (3600*j)
						break
					else
						-- no up to date data (or not anymore)
						realm[name][0] = nil
					end
				end

				--	level changed
				if level > realm[name][1] and name ~= player.name then
					-- online check (40 sec grace period for logging in)
					if time() > timeLogin + 40 then
						local levelTimeG, levelSpeedG = "", ""
					
						--	level time; ignore the [1] key value
						if level-1 ~= 1 and type(realm[name][level-1]) == "table" then
							levelTimeG = " in "..self:TimetoString(time() - realm[name][level-1][1])
						end

						--	level speed
						if realm[name][0] then
							levelSpeedG = format(" (%.2f %s/%s)", 1/realm[name][0], HOUR, LEVEL)
						end

						--	level filters
						if level >= profile.guildMemberLevelFilter and (not profile.guildMemberAchievementFilter or (profile.guildMemberAchievementFilter and mod(level, 10) > 0 and level ~= 85)) then
							if profile.guildMemberAnnounce then
								SCM(self:ReplaceTextG(profile.guildMemberDingMsg[profile.randomMessageGuild and random(2, 6) or 1], false, name, level, class, rank, zone, levelTimeG, levelSpeedG), "GUILD")
							end
							if profile.GuildMemberDings then
								self:OutputFrame(self:ReplaceTextG(profile.guildMemberDingMsg[1], true, name, level, class, rank, zone, levelTimeG, levelSpeedG, classFileName))
							end
						end
						--	save time & date of levelup
						realm[name][level] = {}
						realm[name][level][1] = time()
						realm[name][level][2] = date("%Y.%m.%d %H:%M:%S")
					else
						--	level changed while user was offline
						realm[name][level] = false -- don't got time & date
						if profile.GuildMemberDings then
							if not showedDiffs and char.lastCheck then
								showedDiffs = true
								self:Print(format("|cffF6ADC6[%s]|r - |cffADFF2F[%s]|r", char.lastCheck, date("%Y.%m.%d %H:%M")))
							end
							print(format("|cff%s|Hplayer:%s|h[%s]|h|r %s |cffF6ADC6%s|r - |cffADFF2F%s|r (+|cff71D5FF%s|r)", GetClassColor(classFileName), name, name, LEVEL, realm[name][1], level, level-realm[name][1]))
						end
					end
				end
			end
			-- define guildmember / update level to [1] key
			realm[name] = realm[name] or {}
			realm[name][1] = level
		end
	end
end

-- Auto Gratz
function RSD:CHAT_MSG(event, msg, name)
	local throttle, msgType

	if event == "CHAT_MSG_PARTY" then
		throttle, msgType = cd.autoGratzParty, "PARTY"
	elseif event == "CHAT_MSG_GUILD" then
		throttle, msgType = cd.autoGratzGuild, "GUILD"
	end

	if profile.AutoGratz and name ~= player.name and strfind(msg, "[Dd][Ii][Nn][Gg]") and strlen(msg) <= 10 and time() > (throttle or 0) then
		cd.autoGratzParty = time() + profile.autoGratzCooldown		
		self:AutoGratz(msgType, name)
	end
end

function RSD:CHAT_MSG_GUILD_ACHIEVEMENT(event, msg, name)
	-- don't gratz if player is afk
	if profile.AutoGratzAFK and UnitIsAFK("player") then return end

	local achievementID = tonumber(strmatch(msg, "achievement:(%d+)"))
	if profile.AutoGratz and name ~= player.name and time() > (cd.autoGratzGuild or 0) then
		if (not profile.allAchievements and strfind(msg, LEVEL)) or profile.allAchievements then
			if ((profile.filterAchievements and not AchievementBlacklist[achievementID]) or not profile.filterAchievements) then
				cd.autoGratzGuild = time() + profile.autoGratzCooldown
				self:AutoGratz("GUILD", name)
			end
		end
	end
end

local MARKED_AFK_MESSAGE = gsub(MARKED_AFK_MESSAGE, "%%s", ".+")

function RSD:CHAT_MSG_SYSTEM(event, msg)
	if msg == MARKED_AFK or strfind(msg, MARKED_AFK_MESSAGE) then
		timeAFK1 = time()
	elseif msg == CLEARED_AFK and timeAFK1 then
		TimeAFK()
	end
end

-- update [AFK]
function RSD:PLAYER_LEAVING_WORLD()
	if UnitIsAFK("player") and timeAFK1 then
		TimeAFK()
	end
	-- time/date at logout for showing levelDiffs
	char.lastCheck = date("%Y.%m.%d %H:%M")
end

function RSD:COMBAT_LOG_EVENT_UNFILTERED(event, ...)

	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

		-- assigning all parameters for clarity
	local spellID, spellName, spellSchool
	local SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9

	local prefix = strsub(subevent, 1, 5)
	if prefix == "SWING" then
		SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
	elseif prefix == "SPELL" or prefix == "RANGE" or prefix == "DAMAG" then
		spellID, spellName, spellSchool, SuffixParam1, SuffixParam2, SuffixParam3, SuffixParam4, SuffixParam5, SuffixParam6, SuffixParam7, SuffixParam8, SuffixParam9 = select(12, ...)
	end

	-- [DEATHS]
	if subevent == "UNIT_DIED" and destName == player.name then
		stats.deaths = stats.deaths + 1
	end

	-- [KILLS]
	if sourceName == player.name then
		if strfind(subevent, "DAMAGE") and subevent ~= "ENVIRONMENTAL_DAMAGE" and subevent ~= "DAMAGE_SHIELD_MISSED" and SuffixParam2 > 0 and time() > (cd.PlayerKill or 0) then
			cd.PlayerKill = time() + 0.1
			stats.kills = stats.kills + 1
		end
	end
end

local function TimetoMilitaryTime(value)
	local seconds = mod(floor(value), 60)
	local minutes = mod(floor(value/60), 60)
	local hours = mod(floor(value/3600), 24)
	local days = floor(value/86400)

	if days > 0 then
		return format("%s:%02.f:%02.f:%02.f", days, hours, minutes, seconds)
	elseif hours > 0 then
		return format("%s:%02.f:%02.f", hours, minutes, seconds)
	else
		return format("%02.f:%02.f   ", minutes, seconds)
	end
end

	----------------------
	--- Filter /played ---
	----------------------

local oldChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed

function ChatFrame_DisplayTimePlayed(...)
	-- using /played manually should still work
	if not filterPlayed or not profile.filterPlayed then
		oldChatFrame_DisplayTimePlayed(...)
	end
	filterPlayed = false
end

	---------------------
	--- LibDataBroker ---
	---------------------

local TIME_PLAYED_TOTAL_TEXT = gsub(TIME_PLAYED_TOTAL, "%%s", "")
local TIME_PLAYED_LEVEL_TEXT = gsub(TIME_PLAYED_LEVEL, "%%s", "")

local function TooltipXPline()
	local curxp = UnitXP("player")
	local maxxp = UnitXPMax("player")
	return format("|cffADFF2F%d|r / |cff71D5FF%d|r = |cffFFFFFF%d%%|r", curxp, maxxp, (curxp/maxxp)*100)
end

local dataobject = {
	type = player.level < 85 and "data source" or "launcher",
	icon = "Interface\\AddOns\\ReadySetDing\\Images\\Windows7_Logo",
	OnClick = function(clickedframe, button)
		if IsModifierKeyDown() then
			RSD:SlashCommand(RSD:IsEnabled() and "0" or "1")
		else
			if InterfaceOptionsFrame:IsShown() and strfind(InterfaceOptionsFramePanelContainer.displayedPanel.name, "ReadySet|cffFFFFFFDing|r") then
				InterfaceOptionsFrame:Hide()
			else
				InterfaceOptionsFrame_OpenToCategory(optionsFrame.Main)
			end
		end
	end,
	OnTooltipShow = function(tt)
		tt:AddLine("|cffADFF2FReadySet|r|cffFFFFFFDing|r")
		tt:AddDoubleLine(EXPERIENCE_COLON, TooltipXPline())
		tt:AddDoubleLine(TIME_PLAYED_LEVEL_TEXT, format("|cffFFFFFF"..TIME_DAYHOURMINUTESECOND.."|r", unpack( {ChatFrame_TimeBreakDown(currentTime)} )))
		tt:AddDoubleLine(TIME_PLAYED_TOTAL_TEXT, format("|cffFFFFFF"..TIME_DAYHOURMINUTESECOND.."|r", unpack( {ChatFrame_TimeBreakDown(totalTime)} )))
		tt:AddLine("|cffFFFFFFClick|r to open the options menu")
		tt:AddLine("|cffFFFFFFShift-click|r to toggle this AddOn")
	end,
}

if player.level < 85 then
	RSD:ScheduleRepeatingTimer(function()
		dataobject.text = TimetoMilitaryTime(currentTime)
	end, 1)
else
	dataobject.text = "ReadySetDing"
end

LDB:NewDataObject("ReadySetDing", dataobject)