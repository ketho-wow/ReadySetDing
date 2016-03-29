local _, S = ...

local L = {
	enUS = {
		BROKER_CLICK = "Click to open the options menu",
		BROKER_SHIFT_CLICK = "Shift-click to toggle this AddOn",
		GUILD_CHANGELOG = "Guild Changelog",
		LEVEL_GRAPH = LEVEL.." Graph",
		LEVEL_SPEED = LEVEL.." "..SPEED,
		LEVEL_TIME = "Level Time",
		MSG_PLAYER_DING = TUTORIAL_TITLE55.." "..LEVEL.." <LEVEL> in <TIME>",
		MSG_PLAYER_DING2 = TUTORIAL_TITLE55.." "..LEVEL.." <LEVEL>",
		MSG_PLAYER_DING3 = "I reached "..LEVEL.." <LEVEL> in <ZONE>!",
		MSG_PLAYER_DING4 = "I reached "..LEVEL.." <LEVEL>, only <LEVEL%> to go!",
		RaidWarningFrame = "RaidWarningFrame",
		RANDOM = "Random",
		RANDOM_MESSAGE = "Random Message",
		TIME_ABBREVIATE = "Abbreviate",
		TIME_FORMAT = "Time Format",
		TIME_FORMAT_NORMAL = "Normal Time Format",
		TIME_LOWER_CASE = "Lower Case",
		TIME_MAX_UNITS = "Max time units",
		TIME_OMIT_SECONDS = "Omit "..SECONDS,
		TIME_OMIT_ZERO = "Omit Zero",
		TIMESTAMP = "Timestamp",
		TOTAL = "Total",
		TOTAL_TIME = "Total Time",
	},
	deDE = {
		BROKER_CLICK = "Klickt, um das Optionsmenü zu öffnen", -- Needs review
		BROKER_SHIFT_CLICK = "Shift-klickt, um dieses AddOn ein-/auszuschalten", -- Needs review
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
		TIME_FORMAT_NORMAL = "Normal Zeitformat", -- Needs review
		TIME_LOWER_CASE = "Kleinschrift", -- Needs review
		TIME_MAX_UNITS = "Zeiteinheiten", -- Needs review
		TIME_OMIT_SECONDS = "Sekunden auslassen", -- Needs review
		TIME_OMIT_ZERO = "Nullwerte auslassen", -- Needs review
		TIMESTAMP = "Zeitstempel",
		TOTAL = "Insgesamt",
		TOTAL_TIME = "Spielzeit insgesamt",
	},
	esES = {
		BROKER_CLICK = "Haz clic para ver opciones", -- Needs review
		BROKER_SHIFT_CLICK = "Mayús-clic para activar/desactivar", -- Needs review
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
		BROKER_CLICK = "点击打开选项菜单", -- Needs review
		BROKER_SHIFT_CLICK = "Shift-点击启用或禁用插件", -- Needs review
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
		TIME_FORMAT_BLIZZARD = "标准时间格式",
		TIME_LOWER_CASE = "小写英文字母",
		TIME_MAX_UNITS = "最大时间单位",
		TIME_OMIT_SECONDS = "省略秒数",
		TIME_OMIT_ZERO = "忽略零",
		TIMESTAMP = "时间戳记",
		TOTAL = "总共",
		TOTAL_TIME = "总时间",
	},
	zhTW = {
		BROKER_CLICK = "左鍵打開選項選單", -- Needs review
		BROKER_SHIFT_CLICK = "Shift-左鍵啟用或停用插件", -- Needs review
		GUILD_CHANGELOG = "公會更新日誌",
		LEVEL_GRAPH = "升級圖表",
		LEVEL_SPEED = "升級速度",
		LEVEL_TIME = "升級時間",
		MSG_PLAYER_DING = "升級! 等級 <LEVEL> 使用 <TIME>",
		MSG_PLAYER_DING2 = "升級! 等級 <LEVEL>",
		MSG_PLAYER_DING3 = "我在 <ZONE> 升級到等級 <LEVEL> !",
		MSG_PLAYER_DING4 = "我已經升到等級 <LEVEL>，只剩 <LEVEL%> 級!",
		RaidWarningFrame = "團隊警告", -- Needs review
		RANDOM = "隨機", -- Needs review
		RANDOM_MESSAGE = "隨機訊息",
		TIME_ABBREVIATE = "縮寫",
		TIME_FORMAT = "時間格式",
		TIME_FORMAT_NORMAL = "標準時間格式", -- Needs review
		TIME_LOWER_CASE = "小寫英文字母",
		TIME_MAX_UNITS = "最大時間單位",
		TIME_OMIT_SECONDS = "省略秒數",
		TIME_OMIT_ZERO = "忽略零", -- Needs review
		TIMESTAMP = "時間戳記",
		TOTAL = "總共",
		TOTAL_TIME = "總時間",
	},
}

L.esMX = L.esES -- esMX is empty

S.L = setmetatable(L[GetLocale()] or L.enUS, {__index = function(t, k)
	local v = rawget(L.enUS, k) or k
	rawset(t, k, v)
	return v
end})
