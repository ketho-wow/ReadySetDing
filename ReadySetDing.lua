-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2009.09.01					---
-------------------------------------------
--- Curse			http://mods.curse.com/addons/wow/readysetding
--- WoWInterface	http://www.wowinterface.com/downloads/info16220-ReadySetDing.html

--- To Do:
-- guild member levels scroll window
-- more advanced graphs, guildmember graphs

local NAME, S = ...

ReadySetDing = LibStub("AceAddon-3.0"):NewAddon("ReadySetDing", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
local RSD = ReadySetDing
RSD.S = S -- debug purpose

S.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

local profile, char

function RSD:RefreshDB1()
	profile = self.db.profile
	char = self.db.char
end

S.crop = ":64:64:4:60:4:60"
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
}

	--------------
	--- Player ---
	--------------

S.player = {
	class = UnitClass("player"),
	englishClass = select(2, UnitClass("player")),
	faction = select(2, UnitFactionGroup("player")),
	level = UnitLevel("player"),
	maxlevel = GetMaxLevelForPlayerExpansion(),
	maxxp = UnitXPMax("player"),
	name = UnitName("player"),
	race = UnitRace("player"),
	realm = GetRealmName(),
}
local player = S.player

S.maxlevel = GetMaxLevelForLatestExpansion()

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
		if profile.NormalTime then
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

-- For these races, the names are shortened for the atlas
local fixedRaceAtlasNames = {
	["highmountaintauren"] = "highmountain",
	["lightforgeddraenei"] = "lightforged",
	["scourge"] = "undead",
	["zandalaritroll"] = "zandalari",
}

-- GetRaceAtlas was removed from framexml in 10.0.0
local function GetRaceAtlas(raceName, gender, useHiRez)
	if (fixedRaceAtlasNames[raceName]) then
		raceName = fixedRaceAtlasNames[raceName]
	end
	local formatingString = useHiRez and "raceicon128-%s-%s" or "raceicon-%s-%s"
	return formatingString:format(raceName, gender)
end

S.sexName = {nil, "male", "female"}

function S.GetRaceIcon(name, genderID, x, y)
	local atlas = GetRaceAtlas(name:lower(), S.sexName[genderID])
	local icon = CreateAtlasMarkup(atlas, 16, 16, x, y)
	return icon
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

S.legend = {}
S.legend.show = "\n|cff71D5FFICON|r, |cffA8A8FFCHAN|r, |cffFFFFFFNAME|r, |cffADFF2FLEVEL|r"
S.legend.chat = "\n|cffADFF2FLEVEL,|r |cffF6ADC6LEVEL-, LEVEL#, LEVEL%|r"
	.."\n|cff71D5FFTIME, TOTAL,|r |cff0070DDDATE, DATE2|r"
	.."\n|cffFFFF00AFK, AFK+,|r"

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
	"RaidWarningFrame",
	COMBAT_TEXT_LABEL,
}

function RSD:ShowLevelup(msg, args)
	local v = profile.ShowOutput
	msg = msg and self:ReplaceArgs(msg, args) or sinks[v] -- fallback to example; does not include chat windows

	if v == 1 then
		-- RaidWarningFrame shows max 2 messages at the same time
		-- they're called "slots" as in "RaidWarningFrameSlot1"
		RaidNotice_AddMessage(RaidWarningFrame, msg, S.white)
	elseif v == 2 then
		CombatText_AddMessage(msg, CombatText_StandardScroll, 1, 1, 1)
	else
		local i = v-2
		_G["ChatFrame"..i]:AddMessage(msg or (NAME..": |cff71D5FF"..i..". "..GetChatWindowInfo(i).."|r"))
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
