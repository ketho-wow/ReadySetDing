local _, S = ...

local L = {
	deDE = {
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmen\195\188 zu \195\182ffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
	},
	enUS = {
		MSG_PLAYER_DING = "Ding! "..LEVEL.." <LEVEL> in <TIME>",
		MSG_PLAYER_DING2 = "I've reached "..LEVEL.." <LEVEL>!",
		
		TIME_FORMAT = "Time Format",
		TIME_FORMAT_LEGACY = "Legacy Time Format",
		TIME_MAX_UNITS = "Max time units",
		TIME_OMIT_SECONDS = "Omit "..SECONDS,
		TIME_ABBREVIATE = "Abbreviate",
		
		FILTER_PLAYED_MESSAGE = FILTER.." |cffF6ADC6/played|r Message",
		NOT_FILTER_OTHER_ADDONS = "|cffFF0000Note:|r Does not filter /played when it's called by other AddOns",
		GUILDMEMBER_LEVEL_DIFF_LOGIN = "|cff40FF40"..GUILD.."|r Member "..LEVEL.." Diff on Login",
		LEVEL_GRAPH = LEVEL.." Graph",
		
		ANNOUNCE_GUILDMEMBER_LEVELUP = CHAT_ANNOUNCE.." |cff40FF40"..GUILD.."|r Member "..PLAYER_LEVEL_UP,
		FILTER_LEVEL_ACHIEVEMENTS = FILTER.." "..LEVEL.." |cffFFFF00"..ACHIEVEMENTS.."|r",
		MINIMUM_LEVEL_FILTER = MINIMUM.." "..LEVEL.." "..FILTER,
		
		AUTO_GRATZ = "Auto Gratz",
		
		SCREENSHOT_HIDE_UI = HIDE.." "..BUG_CATEGORY5,
		
		SOUND_PATH = SOUND_LABEL.." Path",
		
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
		
		DISABLE_AFK = DISABLE.." when "..AFK,
		RANDOM_MESSAGE = "Random Message",
		
		ARE_YOU_SURE = "Are you sure?",
		COOLDOWN = "Cooldown",
		DELAY = "Delay",
		EXAMPLES = "Examples",
		SOUNDS = "Sounds",
		TEST = "Test",
		TOTAL = "Total",
		
		LEVEL_TIME = "Level Time",
		TOTAL_TIME = "Total Time",
		LEVEL_SPEED = "Level Speed",
		TIMESTAMP = "Timestamp",
	},
	esES = {
	},
	esMX = {
	},
	frFR = {
	},
	itIT = {
	},
	koKR = {
	},
	ptBR = {
	},
	ruRU = {
	},
	zhCN = {
		BROKER_CLICK = "|cffFFFFFF\231\130\185\229\135\187|r\230\137\147\229\188\128\233\128\137\233\161\185\232\143\156\229\141\149", -- "点击打开选项菜单"
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-\231\130\185\229\135\187|r \229\144\175\231\148\168\230\136\150\231\166\129\231\148\168\230\143\146\228\187\182", -- "Shift-点击 启用或禁用插件"
	},
	zhTW = {
	},
}

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
