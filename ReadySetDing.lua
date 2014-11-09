-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2009.09.01					---
--- Version: 1.16 [2014.11.10]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/readysetding
--- WoWInterface	http://www.wowinterface.com/downloads/info16220-ReadySetDing.html

--- To Do:
-- guild member levels scroll window
-- more advanced graphs, guildmember graphs
-- custom achievements; use custom achiev lib

local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.BUILD = "Release"

ReadySetDing = LibStub("AceAddon-3.0"):NewAddon("ReadySetDing", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
local RSD = ReadySetDing
RSD.S = S -- debug purpose

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L

local profile, char

function RSD:RefreshDB1()
	profile = self.db.profile
	char = self.db.char
end

S.crop = ":64:64:4:60:4:60"
S.RT = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
S.white = {r=1, g=1, b=1}

S.cd = {} -- cooldowns
local cd = S.cd

S.args = {} -- message args

-- self reminder: don't "recycle" when tables are being reused in a way that they "conflict"
-- or just don't let them use the same index (=.=)
S.recycle = setmetatable({}, {__index = function(t, k)
	local v = {}
	rawset(t, k, v)
	return v
end})

	--------------
	--- Events ---
	--------------

S.events = {
	-- Player Level Up
	"PLAYER_LEVEL_UP",
	"TIME_PLAYED_MSG",
	
	-- Group Member Level Up
	"UNIT_LEVEL",
	
	-- Guild Member Level Up
	"GUILD_ROSTER_UPDATE",
	
	-- (Real ID) Friend Level Up
	"FRIENDLIST_UPDATE",
	"BN_FRIEND_INFO_CHANGED",
	
	-- AFK Time
	"CHAT_MSG_SYSTEM",
	"PLAYER_LEAVING_WORLD",
	
	-- Deaths
	"PLAYER_DEAD",
}

-- register/unregister events depending on options
S.levelremap = {
	ShowParty = "UNIT_LEVEL",
	ShowRaid = "UNIT_LEVEL",
	
	ShowGuild = "GUILD_ROSTER_UPDATE",
	GuildMemberDing = "GUILD_ROSTER_UPDATE",
	GuildMemberDiff = "GUILD_ROSTER_UPDATE",
	
	ShowFriend = "FRIENDLIST_UPDATE",
	ShowRealID = "BN_FRIEND_INFO_CHANGED",
}

-- determine if any of the UNIT_LEVEL options are enabled
function S.UNIT_LEVEL()
	return profile.ShowParty or profile.ShowRaid
end

-- determine if any of the GUILD_ROSTER_UPDATE options are enabled
function S.GUILD_ROSTER_UPDATE()
	return profile.ShowGuild or profile.GuildMemberDing or profile.GuildMemberDiff
end

	--------------
	--- Player ---
	--------------

S.player = {
	class = UnitClass("player"),
	englishClass = select(2, UnitClass("player")),
	faction = select(2, UnitFactionGroup("player")),
	level = UnitLevel("player"),
	maxlevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()],
	maxxp = UnitXPMax("player"),
	name = UnitName("player"),
	race = UnitRace("player"),
	realm = GetRealmName(),
}
local player = S.player

S.maxlevel = MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]

	------------
	--- Time ---
	------------

do
	function RSD:SecondsTime(v)
		return SecondsToTime(v, profile.TimeOmitSec, not profile.TimeAbbrev, profile.TimeMaxCount)
	end
	
	-- not capitalized
	local D_SECONDS = strlower(D_SECONDS)
	local D_MINUTES = strlower(D_MINUTES)
	local D_HOURS = strlower(D_HOURS)
	local D_DAYS = strlower(D_DAYS)
	
	-- exception for German capitalization
	if GetLocale() == "deDE" then
		D_SECONDS = _G.D_SECONDS
		D_MINUTES = _G.D_MINUTES
		D_HOURS = _G.D_HOURS
		D_DAYS = _G.D_DAYS
	end
	
	function RSD:TimeString(v, full)
		local sec = floor(v) % 60
		local minute = floor(v/60) % 60
		local hour = floor(v/3600) % 24
		local day = floor(v/86400)
		
		local fsec = format(D_SECONDS, sec)
		local fmin = format(D_MINUTES, minute)
		local fhour = format(D_HOURS, hour)
		local fday = format(D_DAYS, day)
		
		if v >= 86400 then
			return (hour > 0 or full) and format("%s, %s", fday, fhour) or fday
		elseif v >= 3600 then
			return (minute > 0 or full) and format("%s, %s", fhour, fmin) or fhour
		elseif v >= 60 then
			return (sec > 0 or full) and format("%s, %s", fmin, fsec) or fmin
		elseif v >= 0 then
			return fsec
		else
			return v
		end
	end
	
	local b = CreateFrame("Button")
	
	function RSD:Time(v)
		local s
		if profile.LegacyTime then
			s = self:TimeString(v, not profile.TimeOmitZero)
		else
			s = self:SecondsTime(v)
			s = profile.TimeLowerCase and s:lower() or s
		end
		-- sanitize for SendChatMessage by removing any pipe characters
		return b:GetText(b:SetText(s)) or ""
	end
	
	-- singular hour
	S.HOUR = gsub(b:GetText(b:SetFormattedText(_G.D_HOURS, 1)), "1 ", "")
end

	---------------------------
	--- Time Format Example ---
	---------------------------

do
	local tday, thour, tmin, tsec = random(9), random(23), random(59), random(59)
	
	S.TimeUnits = {
		60*tmin,
		60*tmin + tsec,
		3600*thour + 60*tmin + tsec,
		86400*tday + 3600*thour + 60*tmin + tsec,
	}
	
	S.TimeOmitZero = 3600*thour
end

	-----------------
	--- Stopwatch ---
	-----------------

function S.StopwatchStart(v)
	StopwatchFrame:Show()
	if v then
		StopwatchTicker.timer = v
	else
		Stopwatch_Clear()
	end
	Stopwatch_Play()
end

function S.StopwatchEnd()
	Stopwatch_Clear()
	StopwatchFrame:Hide()
end

function S.CanUseStopwatch(v)
	return player.level < player.maxlevel and v < MAX_TIMER_SEC
end

	--------------------------
	--- Level Achievements ---
	--------------------------

do
	local levels = {10, 20, 30, 40, 50, 60, 70, 80, 85, 90, 100}
	
	S.Levels = {}
	
	for _, v in ipairs(levels) do
		S.Levels[v] = true
	end
	
	S.AchievIcons = {}
	
	for i, v in ipairs(levels) do
		S.AchievIcons[i] = "|TInterface\\Icons\\Achievement_Level_"..v..":24:24:0:0"..S.crop.."|t"
	end
end

	--------------------
	--- Class Colors ---
	--------------------

S.classCache = setmetatable({}, {__index = function(t, k)
	local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[k]
	local v = format("%02X%02X%02X", color.r*255, color.g*255, color.b*255)
	rawset(t, k, v)
	return v
end})

function RSD:WipeCache()
	wipe(S.classCache)
end

	------------------
	--- Race Icons ---
	------------------

S.racePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"

S.RACE_ICON_TCOORDS_256 = { -- GlueXML\CharacterCreate.lua L25 (4.3.3.15354)
	HUMAN_MALE		= {0, 32, 0, 128},
	DWARF_MALE		= {32, 64, 0, 128},
	GNOME_MALE		= {64, 96, 0, 128},
	NIGHTELF_MALE	= {96, 128, 0, 128},

	TAUREN_MALE		= {0, 32, 128, 256},
	SCOURGE_MALE	= {32, 64, 128, 256},
	TROLL_MALE		= {64, 96, 128, 256},
	ORC_MALE		= {96, 128, 128, 256},

	HUMAN_FEMALE	= {0, 32, 256, 384},  
	DWARF_FEMALE	= {32, 64, 256, 384},
	GNOME_FEMALE	= {64, 96, 256, 384},
	NIGHTELF_FEMALE	= {96, 128, 256, 384},

	TAUREN_FEMALE	= {0, 32, 384, 512},   
	SCOURGE_FEMALE	= {32, 64, 384, 512}, 
	TROLL_FEMALE	= {64, 96, 384, 512}, 
	ORC_FEMALE		= {96, 128, 384, 512}, 

	BLOODELF_MALE	= {128, 160, 128, 256},
	BLOODELF_FEMALE	= {128, 160, 384, 512}, 

	DRAENEI_MALE	= {128, 160, 0, 128},
	DRAENEI_FEMALE	= {128, 160, 256, 384}, 

	GOBLIN_MALE		= {160, 192, 128, 256},
	GOBLIN_FEMALE	= {160, 192, 384, 512},

	WORGEN_MALE		= {160, 192, 0, 128},
	WORGEN_FEMALE	= {160, 192, 256, 384},
	
	PANDAREN_MALE	= {192, 224, 0, 128},
	PANDAREN_FEMALE	= {192, 224, 256, 384},
}

S.sexremap = {nil, "MALE", "FEMALE"}

local raceIconCache = setmetatable({}, {__index = function(t, k)
	local coords = strjoin(":", unpack(S.RACE_ICON_TCOORDS_256[k]))
	local v = format("|T%s:16:16:%%s:%%s:256:512:%s|t", S.racePath, coords)
	rawset(t, k, v)
	return v
end})

-- x and y vary so we can't cache that
function S.GetRaceIcon(k, x, y)
	return format(raceIconCache[k], x, y)
end

	-------------------
	--- Class Icons ---
	-------------------

S.classPath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

S.CLASS_ICON_TCOORDS_256 = CopyTable(CLASS_ICON_TCOORDS)

for k1, v1 in pairs(S.CLASS_ICON_TCOORDS_256) do
	for k2, v2 in ipairs(v1) do
		S.CLASS_ICON_TCOORDS_256[k1][k2] = v2*256
	end
end

local classIconCache = setmetatable({}, {__index = function(t, k)
	local coords = strjoin(":", unpack(S.CLASS_ICON_TCOORDS_256[k]))
	local v = format("|T%s:16:16:%%s:%%s:256:256:%s|t", S.classPath, coords)
	rawset(t, k, v)
	return v
end})

function S.GetClassIcon(k, x, y)
	return format(classIconCache[k], x, y)
end

	--------------------
	--- Class Names  ---
	--------------------

-- Real ID level up only provides the localized class name
S.revLOCALIZED_CLASS_NAMES = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	S.revLOCALIZED_CLASS_NAMES[v] = k
end
for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	S.revLOCALIZED_CLASS_NAMES[v] = k
end

	--------------
	--- Legend ---
	--------------

do
	local legend = {}
	
	legend.show = "\n|cff71D5FFICON|r, |cffA8A8FFCHAN|r, |cffFFFFFFNAME|r, |cffADFF2FLEVEL|r"
	
	legend.chat = "\n|cffADFF2FLEVEL,|r |cffF6ADC6LEVEL-, LEVEL#, LEVEL%|r"
		.."\n|cff71D5FFTIME, TOTAL,|r |cff0070DDDATE, DATE2|r"
		.."\n|cffFFFF00AFK, AFK+,|r |cffFF0000DEATH, DEATH+|r\n"
		..TARGETICONS..": |cffFFFFFF{rt5} |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:12|t|r, |cffFF8000RT|r"
	
	local playerColor = S.classCache[player.englishClass]
	
	legend.guild = "\n|cffADFF2FLEVEL|r, |cffF6ADC6LEVEL-, LEVEL#, LEVEL%|r"
		.."\n|cff"..playerColor.."NAME|r, |cff"..playerColor.."CLASS|r, |cff0070DDRANK|r, |cff0070DDZONE|r"
		.."\n|cff71D5FFREALTIME|r, |cffFF8000RT|r"
	
	S.legend = legend
end

	--------------
	--- Sounds ---
	--------------

S.sounds = {
	"Interface\\AddOns\\ReadySetDing\\Sounds\\mysound.mp3",
	"|cffF6ADC6Random|r",
	"Sound\\Interface\\LevelUp.ogg",
	"sound\\INTERFACE\\UI_GuildLevelUp.ogg",
	"Sound\\Interface\\iQuestComplete.ogg",
	"Sound\\Spells\\AchievmentSound1.ogg",
	"Sound\\Spells\\Resurrection.ogg",
	"Sound\\Doodad\\BellTollAlliance.ogg",
	"sound\\CREATURE\\MANDOKIR\\VO_ZG2_MANDOKIR_LEVELUP_EVENT_01.ogg",
	"sound\\CREATURE\\JINDO\\VO_ZG2_JINDO_MANDOKIR_LEVELS_UP_01.ogg",
	"Sound\\character\\BloodElf\\BloodElfFemaleCongratulations02.ogg",
	"Sound\\character\\Human\\HumanVocalFemale\\HumanFemaleCongratulations01.ogg",
	"Sound\\character\\NightElf\\NightElfVocalFemale\\NightElfFemaleCongratulations01.ogg",
	"Sound\\Character\\BloodElf\\BloodElfFemaleFlirt02.ogg",
	"Sound\\Creature\\Paletress\\AC_Paletress_Death01.ogg",
	"Sound\\character\\Orc\\OrcVocalMale\\OrcMaleCheer01.ogg",
	"Sound\\creature\\Peon\\PeonPissed3.ogg",
	"Sound\\creature\\HoodWolf\\HoodWolfTransformPlayer01.ogg",
	"Sound\\creature\\Illidan\\BLACK_Illidan_04.ogg",
	"Sound\\creature\\LichKing\\IC_Lich King_FMAttack01.ogg",
	"sound\\CREATURE\\Deathwing\\VO_DS_DEATHWING_MAELSTROMSPELL_05.OGG",
	"Sound\\Music\\GlueScreenMusic\\wow_main_theme.mp3",
	"sound\\music\\cataclysm\\MUS_WordsAndMusicByEvent_E01.mp3",
	"Sound\\Music\\Musical Moments\\angelic\\angelic01.mp3",
	"Sound\\Music\\WorldEvents\\AllianceFirepole.mp3",
	"Sound\\Music\\ZoneMusic\\TavernDwarf\\RA_DwarfTavern1A.mp3",
}

	-------------
	--- Stats ---
	-------------

-- http://www.wowhead.com/achievements=2
function RSD:AchievStat(info)
	if info == "quest" then
		local questsTotal = GetStatistic(98); questsTotal = (questsTotal == "--") and 0 or questsTotal -- 98 = Quests completed
		local questsDaily = GetStatistic(97); questsDaily = (questsDaily == "--") and 0 or questsDaily -- 97 = Daily quests completed
		return questsTotal - questsDaily -- thank you aldon@wowhead
	elseif info == "death" then
		local totalDeaths = GetStatistic(60); totalDeaths = (totalDeaths == "--") and 0 or totalDeaths -- 60 = Total Deaths
		return totalDeaths
	end
end

	---------------
	--- Replace ---
	---------------

function RSD:ReplaceArgs(msg, args)
	-- new random messages init as nil
	if not msg then return "" end
	
	for k in gmatch(msg, "%b<>") do
		-- remove <>, make case insensitive
		local s = strlower(gsub(k, "[<>]", ""))
		
		-- escape special characters
		-- a maybe better alternative to %p is "[%%%.%-%+%?%*%^%$%(%)%[%]%{%}]"
		s = gsub(args[s] or s, "(%p)", "%%%1")
		k = gsub(k, "(%p)", "%%%1")
		
		msg = msg:gsub(k, s)
	end
	wipe(args)
	return msg
end

	--------------
	--- Output ---
	--------------

local sinks = {
	COMBAT_TEXT_LABEL,
	"RaidWarningFrame",
	"RaidBossEmoteFrame",
	"UIErrorsFrame",
}

function RSD:Output(msg, args)
	local v = profile.ShowOutput
	msg = msg and self:ReplaceArgs(msg, args) or sinks[v] -- fallback to example; does not include chat windows
	
	if v == 1 then
		CombatText_AddMessage(msg, COMBAT_TEXT_SCROLL_FUNCTION, 1, 1, 1)
	elseif v == 2 then
		-- RaidWarningFrame / RaidBossEmoteFrame shows max 2 messages at the same time
		-- they're called "slots" as in "RaidWarningFrameSlot1"
		RaidNotice_AddMessage(RaidWarningFrame, msg, S.white)
	elseif v == 3 then
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, S.white)
	elseif v == 4 then
		UIErrorsFrame:AddMessage(msg)
	else
		for i = 1, NUM_CHAT_WINDOWS do
			if i == v-4 then
				_G["ChatFrame"..i]:AddMessage(msg or (NAME..": |cff71D5FF"..i..". "..GetChatWindowInfo(i).."|r"))
				break
			end
		end
	end
end

	----------------------
	--- Filter /played ---
	----------------------

local old = ChatFrame_DisplayTimePlayed

function ChatFrame_DisplayTimePlayed(...)
	-- using /played manually should still work, including when it's called by other addons
	-- when filterPlayed is true it will just only filter the next upcoming /played message
	if not S.filterPlayed then
		old(...)
	end
	S.filterPlayed = false
end
