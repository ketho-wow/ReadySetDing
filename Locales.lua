local _, S = ...

local L = {
	deDE = {
		DELAY = "Verz\195\182gerung",
		LEVEL_SPEED = "Stufenaufstiegstempo",
		LEVEL_TIME = "Stufen-Spieldauer",
		MSG_PLAYER_DING = "Ding! Stufe <LEVEL> in <TIME>",
		TOTAL = "Insgesamt",
		TOTAL_TIME = "Spielzeit insgesamt",
		
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmen\195\188 zu \195\182ffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
	},
	enUS = {
		MSG_PLAYER_DING = TUTORIAL_TITLE55.." "..LEVEL.." <LEVEL> in <TIME>",
		MSG_PLAYER_DING2 = TUTORIAL_TITLE55.." "..LEVEL.." <LEVEL>",
		MSG_PLAYER_DING3 = "I reached "..LEVEL.." <LEVEL> in <ZONE>!",
		MSG_PLAYER_DING4 = "I have reached "..LEVEL.." <LEVEL>, only <LEVEL%> to go!",
		
		LEVEL_TIME = "Level Time",
		TOTAL_TIME = "Total Time",
		TIMESTAMP = "Timestamp",
		
		TOTAL = "Total",
		DELAY = "Delay",
		
		RANDOM_MESSAGE = "Random Message",
		
		TIME_FORMAT = "Time Format",
		TIME_FORMAT_LEGACY = "Legacy Time Format",
		TIME_OMIT_ZERO_VALUE = "Omit Zero Value",
		TIME_MAX_UNITS = "Max time units",
		TIME_OMIT_SECONDS = "Omit "..SECONDS,
		TIME_LOWER_CASE = "Lower Case",
		TIME_ABBREVIATE = "Abbreviate",
		
		LEVEL_GRAPH = LEVEL.." Graph",
		GUILD_CHANGELOG = GUILD.." Changelog",
		LEVEL_SPEED = LEVEL.." "..SPEED,
		
		BROKER_CLICK = "|cffFFFFFFClick|r to open the options menu",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-click|r to toggle this AddOn",
	},
	esES = {
		DELAY = "Retraso",
		LEVEL_SPEED = "Velocidad de Nivel",
		LEVEL_TIME = "Tiempo de Nivel",
		MSG_PLAYER_DING = "Ding! Nivel <LEVEL> en <TIME>",
		TOTAL_TIME = "Tiempo Total",
	},
	--esMX = {},
	frFR = {
	},
	itIT = {
	},
	koKR = {
		DELAY = "\236\167\128\236\151\176\236\139\156\234\176\132",
		LEVEL_GRAPH = "\235\160\136\235\178\168 \234\183\184\235\158\152\237\148\132",
		LEVEL_SPEED = "\235\160\136\235\178\168\236\151\133 \236\134\141\235\143\132",
		LEVEL_TIME = "\235\160\136\235\178\168 \237\148\140\235\160\136\236\157\180 \236\139\156\234\176\132",
		MSG_PLAYER_DING = "\235\145\144\235\145\165! <LEVEL> \235\160\136\235\178\168\234\185\140\236\167\128 <TIME> \236\134\140\236\154\148",
		MSG_PLAYER_DING2 = "\235\145\144\235\145\165! <LEVEL> \235\160\136\235\178\168",
		--MSG_PLAYER_DING3 = "<LEVEL> \235\160\136\235\178\168\236\157\180 \235\144\144\236\150\180\236\154\148~!", -- Needs review
		RANDOM_MESSAGE = "\235\172\180\236\158\145\236\156\132 \235\169\148\236\139\156\236\167\128",
		TOTAL = "\236\180\157",
		TOTAL_TIME = "\236\160\132\236\178\180 \236\139\156\234\176\132",
	},
	ptBR = {
	},
	ruRU = {
		DELAY = "\208\151\208\176\208\180\208\181\209\128\208\182\208\186\208\176", -- "Задержка"
		LEVEL_SPEED = "\208\161\208\186\208\190\209\128\208\190\209\129\209\130\209\140 \208\189\208\176\208\177\208\190\209\128\208\176 \209\131\209\128\208\190\208\178\208\189\209\143", -- "Скорость набора уровня"
		LEVEL_TIME = "\208\146\209\128\208\181\208\188\209\143 \208\183\208\176\209\130\209\128\208\176\209\135\208\181\208\189\208\189\208\190\208\181 \208\189\208\176 \209\131\209\128\208\190\208\178\208\181\208\189\209\140", -- "Время затраченное на уровень"
		TOTAL = "\208\158\208\177\209\137\208\181\208\181", -- "Общее"
		TOTAL_TIME = "\208\158\208\177\209\137\208\181\208\181 \208\178\209\128\208\181\208\188\209\143", -- "Общее время"
	},
	zhCN = {
		BROKER_CLICK = "|cffFFFFFF\231\130\185\229\135\187|r\230\137\147\229\188\128\233\128\137\233\161\185\232\143\156\229\141\149", -- "点击打开选项菜单"
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-\231\130\185\229\135\187|r \229\144\175\231\148\168\230\136\150\231\166\129\231\148\168\230\143\146\228\187\182", -- "Shift-点击 启用或禁用插件"
	},
	zhTW = {
	},
}

L.esMX = L.esES -- esMX is empty

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
