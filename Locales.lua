local _, S = ...

local L = {
	enUS = {
		MSG_PLAYER_DING = TUTORIAL_TITLE55.." "..LEVEL.." <LEVEL> in <TIME>",
		MSG_PLAYER_DING2 = TUTORIAL_TITLE55.." "..LEVEL.." <LEVEL>",
		MSG_PLAYER_DING3 = "I reached "..LEVEL.." <LEVEL> in <ZONE>!",
		MSG_PLAYER_DING4 = "I reached "..LEVEL.." <LEVEL>, only <LEVEL%> to go!",
		
		LEVEL_TIME = "Level Time",
		TOTAL_TIME = "Total Time",
		TIMESTAMP = "Timestamp",
		
		TOTAL = "Total",
		
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
	deDE = {
		GUILD_CHANGELOG = "Stufenunterschied Gildenmitglieder", -- Needs review
		LEVEL_GRAPH = "Stufendiagramm", -- Needs review
		LEVEL_SPEED = "Stufenaufstiegstempo",
		LEVEL_TIME = "Stufen-Spieldauer",
		MSG_PLAYER_DING = "Ding! Stufe <LEVEL> in <TIME>",
		MSG_PLAYER_DING2 = "Ding! Stufe <LEVEL>",
		MSG_PLAYER_DING3 = "Ich habe Stufe <LEVEL> in <ZONE> erreicht!",
		MSG_PLAYER_DING4 = "Ich habe Stufe <LEVEL> erreicht, es sind nur noch <LEVEL%> übrig!",
		RANDOM_MESSAGE = "Zufällige Mitteilung",
		TIME_ABBREVIATE = "Abkürzen",
		TIME_FORMAT = "Zeitformat",
		TIME_FORMAT_LEGACY = "Altes Zeitformat",
		TIME_LOWER_CASE = "Kleinschrift", -- Needs review
		TIME_MAX_UNITS = "Zeiteinheiten", -- Needs review
		TIME_OMIT_SECONDS = "Sekunden auslassen", -- Needs review
		TIME_OMIT_ZERO_VALUE = "Nullwerte auslassen", -- Needs review
		TIMESTAMP = "Zeitstempel",
		TOTAL = "Insgesamt",
		TOTAL_TIME = "Spielzeit insgesamt",
		
		BROKER_CLICK = "|cffFFFFFFKlickt|r, um das Optionsmen\195\188 zu \195\182ffnen",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-klickt|r, um dieses AddOn ein-/auszuschalten",
	},
	esES = {
		LEVEL_SPEED = "Velocidad de Nivel", -- Needs review
		LEVEL_TIME = "Tiempo de Nivel", -- Needs review
		MSG_PLAYER_DING = "Ding! Nivel <LEVEL> en <TIME>", -- Needs review
		TOTAL_TIME = "Tiempo Total", -- Needs review
	},
	--esMX = {},
	frFR = {
	},
	itIT = {
	},
	koKR = {
		LEVEL_GRAPH = "레벨 그래프",
		LEVEL_SPEED = "레벨업 속도",
		LEVEL_TIME = "레벨 플레이 시간",
		MSG_PLAYER_DING = "두둥! <LEVEL> 레벨까지 <TIME> 소요",
		MSG_PLAYER_DING2 = "두둥! <LEVEL> 레벨",
		MSG_PLAYER_DING3 = "<LEVEL> 레벨이 됐어요~!", -- Needs review
		RANDOM_MESSAGE = "무작위 메시지",
		TOTAL = "총",
		TOTAL_TIME = "전체 시간",
	},
	ptBR = {
	},
	ruRU = {
		LEVEL_SPEED = "Скорость набора уровня", -- Needs review
		LEVEL_TIME = "Время затраченное на уровень", -- Needs review
		TOTAL = "Общее", -- Needs review
		TOTAL_TIME = "Общее время", -- Needs review
	},
	zhCN = {
		GUILD_CHANGELOG = "公会更新日志",
		LEVEL_GRAPH = "升级图表",
		LEVEL_SPEED = "升级速度",
		LEVEL_TIME = "升级时间",
		MSG_PLAYER_DING = "升级! 等级 <LEVEL> 使用 <TIME>",
		MSG_PLAYER_DING2 = "升级! 等级 <LEVEL>",
		MSG_PLAYER_DING3 = "我在 <ZONE> 升级到等级 <LEVEL> !",
		MSG_PLAYER_DING4 = "我已经升到等级 <LEVEL>，只剩 <LEVEL%> 级!",
		RANDOM_MESSAGE = "随机讯息",
		TIME_ABBREVIATE = "缩写",
		TIME_FORMAT = "时间格式",
		TIME_FORMAT_LEGACY = "标准时间格式",
		TIME_LOWER_CASE = "小写英文字母",
		TIME_MAX_UNITS = "最大时间单位",
		TIME_OMIT_SECONDS = "省略秒数",
		TIME_OMIT_ZERO_VALUE = "忽略零",
		TIMESTAMP = "时间戳记",
		TOTAL = "总共",
		TOTAL_TIME = "总时间",

		BROKER_CLICK = "|cffFFFFFF点击|r打开选项菜单",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-点击|r 启用或禁用插件",
	},
	zhTW = {
		GUILD_CHANGELOG = "公會更新日誌",
		LEVEL_GRAPH = "升級圖表",
		LEVEL_SPEED = "升級速度",
		LEVEL_TIME = "升級時間",
		MSG_PLAYER_DING = "升級! 等級 <LEVEL> 使用 <TIME>",
		MSG_PLAYER_DING2 = "升級! 等級 <LEVEL>",
		MSG_PLAYER_DING3 = "我在 <ZONE> 升級到等級 <LEVEL> !",
		MSG_PLAYER_DING4 = "我已經升到等級 <LEVEL>，只剩 <LEVEL%> 級!",
		RANDOM_MESSAGE = "隨機訊息",
		TIME_ABBREVIATE = "縮寫",
		TIME_FORMAT = "時間格式",
		TIME_FORMAT_LEGACY = "標準時間格式",
		TIME_LOWER_CASE = "小寫英文字母",
		TIME_MAX_UNITS = "最大時間單位",
		TIME_OMIT_SECONDS = "省略秒數",
		TIME_OMIT_ZERO_VALUE = "忽略零",
		TIMESTAMP = "時間戳記",
		TOTAL = "總共",
		TOTAL_TIME = "總時間",
		
		BROKER_CLICK = "|cffFFFFFF點擊|r打開選項菜單",
		BROKER_SHIFT_CLICK = "|cffFFFFFFShift-點擊|r 啟用或禁用插件",
	},
}

L.esMX = L.esES -- esMX is empty

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
