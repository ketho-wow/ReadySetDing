local NAME, S = ...
local RSD = ReadySetDing

local ACD = LibStub("AceConfigDialog-3.0")
local LG = LibStub("LibGraph-2.0")

local L = S.L
local player = S.player
local legend = S.legend
local args = S.args

local profile, char

function RSD:RefreshDB2()
	profile = self.db.profile
	char = self.db.char
end

local time = time
local unpack = unpack
local pairs, ipairs = pairs, ipairs
local format, gsub = format, gsub

	---------------------
	--- GlobalStrings ---
	---------------------

-- remove "%d"
local SECONDS_ABBR2 = gsub(SECONDS_ABBR, "%%d ", "")
local MINUTES_ABBR2 = gsub(MINUTES_ABBR, "%%d ", "")
local HOURS_ABBR2 = gsub(HOURS_ABBR, "%%d ", "")
local DAYS_ABBR2 = gsub(DAYS_ABBR, "%%d ", "")

local arrow = "|cffF6ADC6->|r"

	----------------
	--- Defaults ---
	----------------

S.defaults = {
	profile = {
		ShowGroup = true,
		ShowGuild = true,
		ShowFriend = true,
		ShowMsg = "<ICON> [<CHAN>] [<NAME>]: "..LEVEL.." <LEVEL>",

		ChatGroup = true,

		NumRandomDing = 5,
		DingMsg = {
			L.MSG_PLAYER_DING,
			TUTORIAL_TITLE55.." <LEVEL> :)",
			L.MSG_PLAYER_DING2,
			L.MSG_PLAYER_DING3,
			L.MSG_PLAYER_DING4,
		},

		ShowOutput = 1,
		Language = 1,

		NormalTime = true,
		TimeMaxCount = 2,

		LevelGraph = true,
		GuildChangelog = true,
	}
}

local defaults = S.defaults

	---------------
	--- Options ---
	---------------

S.options = {
	type = "group",
	childGroups = "tab",
	name = format("%s |cffADFF2F%s|r", NAME, GetAddOnMetadata(NAME, "Version")),
	args = {
		main = {
			type = "group", order = 1,
			name = GAMEOPTIONS_MENU,
			handler = RSD,
			get = "GetValue",
			set = "SetValue",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = "|cff3FBF3F"..SHOW.."|r",
					inline = true,
					args = {
						ShowGroup = {
							type = "toggle", order = 1,
							descStyle = "", width = "full",
							name = " |cffA8A8FF"..GROUP.."|r",
						},
						ShowGuild = {
							type = "toggle", order = 2,
							descStyle = "", width = "full",
							name = " |cff40FF40"..GUILD.."|r",
						},
						--[[
						ShowFriend = {
							type = "toggle", order = 3,
							descStyle = "", width = "full",
							name = " "..FRIENDS_WOW_NAME_COLOR_CODE..FRIENDS.."|r",
						},
						]]
						ShowMsg = {
							type = "input", order = 6,
							width = "full", usage = legend.show,
							name = " ",
							set = function(i, v)
								profile.ShowMsg = (strtrim(v) == "") and defaults.profile.ShowMsg or v
							end,
						},
						ShowPreview = {
							type = "description", order = 7,
							fontSize = "medium",
							name = function()
								local info = args
								local raceFile = select(2, UnitRace("player"))
								local sex = UnitSex("player")
								local raceIcon = S.GetRaceIcon(raceFile, sex, 1, 3)
								local classIcon = S.GetClassIcon(select(2, UnitClass("player")), 2, 3)
								info.icon = raceIcon..classIcon
								info.chan = IsInRaid() and "|cffFF7F00"..RAID.."|r" or "|cffA8A8FF"..PARTY.."|r"
								info.name = "|cff"..S.classCache[player.englishClass].._G.NAME.."|r"
								info.level = "|cffADFF2F"..player.level + (player.level == player.maxlevel and 0 or 1).."|r"
								return "  "..RSD:ReplaceArgs(profile.ShowMsg, info)
							end,
						},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = "|cff3FBF3F"..CHAT_ANNOUNCE.."|r",
					inline = true,
					args = {
						ChatGroup = {
							type = "toggle", order = 1,
							descStyle = "", width = "full",
							name = "|cffA8A8FF"..GROUP.."|r",
						},
						ChatGuild = {
							type = "toggle", order = 2,
							descStyle = "", width = "full",
							name = "|cff40FF40"..GUILD.."|r",
						},
						DingRandom = {
							type = "toggle", order = 4,
							descStyle = "", width = "full",
							name = "|cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
						},
						NumRandomDing = {
							type = "range", order = 5,
							descStyle = "",
							name = "# |cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
							min = 2, softMin = 2,
							max = 100, softMax = 25,
							step = 1,
							set = function(i, v)
								profile.NumRandomDing = v
								RSD:SetupRandomDing(v)
							end,
							hidden = function() return not profile.DingRandom end,
						},
						DingMsg1 = {
							type = "input", order = 7,
							width = "full", usage = legend.chat,
							name = " ",
							get = function(i) return profile.DingMsg[1] end,
							set = function(i, v)
								profile.DingMsg[1] = (strtrim(v) == "") and defaults.profile.DingMsg[1] or v
								RSD:ValidateLength(RSD:PreviewDing(1))
								S.activePreview[1] = nil -- clear the preview for random messages
							end,
						},
						PreviewDing = {
							type = "description", order = 8,
							fontSize = "medium",
							name = function() return RSD:PreviewDing(1) end,
						},
					},
				},
				Summary = {
					type = "description", order = 4,
					fontSize = "medium",
					name = function()
						local t = S.recycle[1]; wipe(t)
						for i = player.maxlevel, 2, -1 do
							if char.LevelTimeList[i] then
								tinsert(t, format("  %s |cffF6ADC6%s|r - |cff71D5FF%s|r: |cffB6CA00%s|r  --  %s: |cff71D5FF%s|r",
									LEVEL, i-1, i, RSD:Time(char.LevelTimeList[i]), L.TOTAL, RSD:Time(char.TotalTimeList[i])))
							end
						end
						return strjoin("\n", unpack(t))
					end,
				},
				spacing = {type = "description", order = 5, name = ""},
				Data = {
					type = "execute", order = 6,
					name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:-1"..S.crop.."|t  |cffFFFFFF"..HISTORY.."|r",
					func = "DataFrame",
				},
			},
		},
		advanced = {
			type = "group", order = 2,
			name = "|TInterface\\Icons\\Trade_Engineering:16:16:-2:-1"..S.crop.."|t "..ADVANCED_LABEL,
			handler = RSD,
			get = "GetValue",
			set = "SetValue",
			args = {
				inline1 = {
					type = "group", order = 1,
					name = "|cff3FBF3F"..SHOW.."|r",
					inline = true,
					args = {
						ShowOutput = {
							type = "select", order = 1,
							descStyle = "",
							name = "",
							values = function()
								local c = "|cff2E9AFE"
								local t = {
									c.."#|r  "..L.RaidWarningFrame,
									c.."#|r  "..(SHOW_COMBAT_TEXT == "0" and "|cff979797" or "")..COMBAT_TEXT_LABEL,
								}
								for i = 1, NUM_CHAT_WINDOWS do
									local window = GetChatWindowInfo(i)
									if #window > 0 then
										t[i+2] = c..i..".|r "..window
									end
								end
								return t
							end,
							set = function(i, v)
								profile.ShowOutput = v
								RSD:ShowLevelup()
							end,
						},
						spacing1 = {type = "description", order = 2, name = " "},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = "|cff3FBF3F"..CHAT_ANNOUNCE.."|r",
					inline = true,
					args = {
						Language = {
							type = "select", order = 1,
							descStyle = "",
							name = "   "..LANGUAGES_LABEL,
							values = function()
								local color, languages = "|cff2E9AFE", {}
								languages[1] = color.."#|r  "..DEFAULT
								languages[2] = color.."#|r  "..L.RANDOM
								for i = 1, GetNumLanguages() do
									languages[i+2] = color..i..".|r "..GetLanguageByIndex(i)
								end
								return languages
							end,
						},
					},
				},
				inline3 = {
					type = "group", order = 3,
					name = "|cff3FBF3F"..L.TIME_FORMAT.."|r",
					inline = true,
					args = {
						PreviewTime = {
							type = "description", order = 1,
							fontSize = "large",
							name = function()
								local s = profile.NormalTime and RSD:TimeString(S.TimeOmitZero, not profile.TimeOmitZero) or RSD:Time(S.TimeUnits[profile.TimeMaxCount])
								return "|cffF6ADC6"..s.."|r"
							end,
						},
						header1 = {type = "header", order = 2, name = ""},
						NormalTime = {
							type = "toggle", order = 3,
							width = "full", descStyle = "",
							name = function() return (profile.NormalTime and "" or "|cff979797")..L.TIME_FORMAT_NORMAL end,
						},
						TimeOmitZero = {
							type = "toggle", order = 4,
							width = "full",
							desc = format("%s %s %s", RSD:TimeString(S.TimeOmitZero, true), arrow, RSD:TimeString(S.TimeOmitZero, false)),
							name = L.TIME_OMIT_ZERO,
							hidden = function() return not profile.NormalTime end,
						},
						TimeOmitSec = {
							type = "toggle", order = 5,
							width = "full",
							desc = SECONDS.." "..arrow.." |cffFF0000"..NOT_APPLICABLE.."|r",
							name = L.TIME_OMIT_SECONDS,
							hidden = "NormalTime",
						},
						TimeLowerCase = {
							type = "toggle", order = 6,
							width = "full",
							desc = format("%s %s %s", HOURS, arrow, HOURS:lower()),
							name = L.TIME_LOWER_CASE,
							hidden = "NormalTime",
						},
						TimeAbbrev = {
							type = "toggle", order = 7,
							width = "full",
							desc = format("%s %s %s\n%s %s %s\n%s %s %s\n%s %s %s",
								SECONDS, arrow, SECONDS_ABBR2, MINUTES, arrow, MINUTES_ABBR2, HOURS, arrow, HOURS_ABBR2, DAYS, arrow, DAYS_ABBR2),
							name = L.TIME_ABBREVIATE,
							hidden = "NormalTime",
						},
						TimeMaxCount = {
							type = "range", order = 8,
							descStyle = "",
							name = "   "..L.TIME_MAX_UNITS,
							min = 1,
							max = 4,
							step = 1,
							hidden = "NormalTime",
						},
					},
				},
				spacing1 = {type = "description", order = 4, name = ""},
				Stopwatch = {
					type = "toggle", order = 5,
					width = "full", desc = TIMEMANAGER_SHOW_STOPWATCH,
					name = "|TInterface\\Icons\\Spell_Holy_BorrowedTime:16:16:2:0"..S.crop.."|t  "..STOPWATCH_TITLE,
					set = function(i, v)
						profile.Stopwatch = v
						local t = S.curTPM + time() - S.lastPlayed
						if v then
							if S.CanUseStopwatch(t) then
								S.StopwatchStart(t)
							end
						else
							S.StopwatchEnd()
						end
					end,
				},
				Screenshot = {
					type = "toggle", order = 6,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\inv_misc_spyglass_03:16:16:1:0"..S.crop.."|t  "..BINDING_NAME_SCREENSHOT,
				},
				LevelGraph = {
					type = "toggle", order = 7,
					width = "full", descStyle = "",
					name = "|TINTERFACE\\ICONS\\achievement_guildperk_fasttrack_rank2:16:16:1:0"..S.crop.."|t  "..L.LEVEL_GRAPH,
					set = function(i, v)
						profile.LevelGraph = v
						-- when opened in Blizzard Options Panel
						if not ReadySetDing_LevelGraph then return end
						ReadySetDing_LevelGraph[v and "Show" or "Hide"](ReadySetDing_LevelGraph)
					end,
				},
				GuildChangelog = {
					type = "toggle", order = 8,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\INV_Misc_Book_07:16:16:1:0"..S.crop.."|t  "..L.GUILD_CHANGELOG,
					disabled = function() return not IsInGuild() or not profile.ShowGuild end,
				},
			},
		},
	},
}

local options = S.options

	---------------
	--- Methods ---
	---------------

function RSD:GetValue(i)
	return profile[i[#i]]
end

function RSD:SetValue(i, v)
	profile[i[#i]] = v
end

function RSD:NormalTime()
	return profile.NormalTime
end

	-----------------------
	--- Random Messages ---
	-----------------------

local prev = {}
S.activePreview = {}

function RSD:SetupRandomDing(num)
	local ding = options.args.main.args.inline2.args

	-- create new options
	for i = prev[1] or 2, num do
		ding["DingMsg"..i] = {
			type = "input", order = (i+4)*2, -- 10, 12, 14, ...
			width = "full", name = "",
			get = function(info) return profile.DingMsg[i] end,
			set = function(info, v)
				-- intentionally set v to nil if there are no applicable defaults (up to index 5)
				-- the announce code would then fallback to the default message
				if strtrim(v) == "" then
					profile.DingMsg[i] = defaults.profile.DingMsg[i]
				else
					profile.DingMsg[i] = v
				end
				self:ValidateLength(self:PreviewDing(i))
				S.activePreview[1] = i
			end,
			hidden = function() return not profile.DingRandom end,
		}
		ding["DingPreview"..i] = {
			type = "description", order = (i+4)*2+1,
			fontSize = "medium",
			name = function() return self:PreviewDing(i) end,
			hidden = function() return not profile.DingRandom or S.activePreview[1] ~= i end,
		}
	end

	-- discard unused options
	for i = num+1, prev[1] or 0 do
		ding["DingMsg"..i] = nil
		ding["DingPreview"..i] = nil
	end
	prev[1] = num
end

	----------------
	--- Validate ---
	----------------

function RSD:ValidateLength(msg)
	msg = msg:gsub("|c%x%x%x%x%x%x%x%x(.-)|r", "%1")

	-- notify if message length exceeds 255 chars
	local length = strlen(msg)-2 -- account for the two prepending blank spaces in preview
	if length > 255 then
		self:Print("|cffFF0000Message > 255 chars|r ("..length..")")
	end
end

	---------------
	--- Preview ---
	---------------

function RSD:PreviewDing(i)
	local args = args
	args.level = "|cffADFF2F"..(player.level == player.maxlevel and player.level or player.level + 1).."|r"
	args["level-"] = "|cffF6ADC6"..player.level.."|r"
	args["level#"] = "|cffF6ADC6"..player.maxlevel.."|r"
	args["level%"] = "|cffF6ADC6"..player.maxlevel - (player.level + 1).."|r"
	args.time = "|cff71D5FF"..self:Time(S.curTPM + time() - S.lastPlayed).."|r"
	args.total = "|cff71D5FF"..self:Time(S.totalTPM + time() - S.lastPlayed).."|r"
	args.date = "|cff0070DD"..date("%Y.%m.%d %H:%M:%S").."|r"
	args.date2 = "|cff0070DD"..date("%m/%d/%y %H:%M:%S").."|r"
	args.afk = "|cffFFFF00"..self:Time(char.timeAFK).."|r"
	args["afk+"] = "|cffFFFF00"..self:Time(char.totalAFK).."|r"
	args.zone = GetRealZoneText() or GetSubZoneText() or ZONE

	return "  "..self:ReplaceArgs(profile.DingMsg[i], args)
end

	-------------
	--- Graph ---
	-------------

do
	local x1, y1 = 5, -60
	local x2, y2 = 0, -50

	function RSD:ShowGraph(parent)
		if not profile.LevelGraph or not next(char.LevelTimeList) then return end

		if not ReadySetDing_LevelGraph then
			-- if there are multiple ACD frames shown, this seems to parent to the first one instead, when the second one is opened
			local level = LG:CreateGraphLine("ReadySetDing_LevelGraph", parent, "TOPLEFT", "TOPRIGHT", x1, y1, 0, 200)
			local total = LG:CreateGraphLine("ReadySetDing_TotalGraph", level, "TOPLEFT", "BOTTOMLEFT", x2, y2, 0, 200)
			RSD:UpdateGraph(level, total)
		else
			-- set parent/points again, since it can be shown next to 2 different kinds of option panels
			local level = ReadySetDing_LevelGraph
			local total = ReadySetDing_TotalGraph
			level:ClearAllPoints(); level:SetPoint("TOPLEFT", parent, "TOPRIGHT", x1, y1)
			total:ClearAllPoints(); total:SetPoint("TOPLEFT", level, "BOTTOMLEFT", x2, y2)
			level:SetParent(parent)
			level:Show()
		end
	end
end

-- some dirty hooks
do
	local hasHook

	-- AceConfigDialog frames are created on opening
	hooksecurefunc(ACD, "Open", function(self, appName)
		if appName ~= "ReadySetDing_Parent" or not ACD.OpenFrames.ReadySetDing_Parent then return end

		RSD:ShowGraph(ACD.OpenFrames.ReadySetDing_Parent.frame)

		-- ACD frames get "recycled", so the graphs could possibly show up next to another addon as well
		-- There is the physical "Close" button and ACD.CloseAll, this hook accounts for both methods
		if not hasHook then
			hasHook = true
			hooksecurefunc(ACD.OpenFrames.ReadySetDing_Parent, "OnRelease", function()
				if ReadySetDing_LevelGraph then -- sanity check; sometimes seems to occur at creation of a new character
					ReadySetDing_LevelGraph:Hide()
				end
			end)
		end
	end)
end

-- hooksecurefunc("InterfaceOptionsList_DisplayPanel", function(frame)
-- 	if InterfaceOptionsFramePanelContainer.displayedPanel.name == NAME then
-- 		RSD:ShowGraph(InterfaceOptionsFrame)
-- 	else
-- 		if ReadySetDing_LevelGraph then -- sanity check
-- 			ReadySetDing_LevelGraph:Hide()
-- 		end
-- 	end
-- end)

do
	local startCoord = {0, 0}

	local levelColor = {.68, 1, .18, .7}
	local totalColor = {.44, .84, 1, .7}

	local function getLowestLevel()
		for i = 2, player.maxlevel do
			if char.LevelTimeList[i] then
				return i
			end
		end
	end

	local graphs
	local fstrings = {{}, {}} -- keep track of and reuse fontstrings
	local graphcolor = {levelColor, totalColor}
	local xpoints = {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}

	local function UpdateXLabels(level, total, ...)
		-- hack some X-axis labels in, since LibGraph doesnt really support it
		-- no idea how they would properly implement it though, if they did
		graphs = graphs or {level, total}

		for k, gr in pairs(graphs) do
			for k2, v2 in pairs(xpoints) do
				if not fstrings[k][k2] then
					fstrings[k][k2] = CreateFrame("Frame", nil, level):CreateFontString()
					local fs = fstrings[k][k2]
					fs:SetFontObject("GameFontHighlight")
					fs:SetTextColor(unpack(graphcolor[k]))
					fs:ClearAllPoints()
					fs:SetPoint(v2, gr, v2, 0, -14)
					fs:Show()
				end
				fstrings[k][k2]:SetText(select(k2, ...))
			end
		end
	end

	-- maybe make graphs customizable in some way in the future
	function RSD:UpdateGraph(level, total)
		local minLvl = getLowestLevel()
		if not minLvl then return end
		local hasLevelOne = char.LevelTimeList[2] -- if we have level 2, then we can show level 1 (0;0) too
		local offset = hasLevelOne and 1 or 0

		local MaxLvl = table.maxn(char.LevelTimeList)
		local XLevels = MaxLvl - minLvl + offset
		local XRealWidth = min(XLevels * 25, 500)

		level:SetWidth(XRealWidth)
		total:SetWidth(XRealWidth)

		local YLevelHeight = 0
		local YTotalHeight = char.TotalTimeList[table.maxn(char.TotalTimeList)]

		local t1 = S.recycle[4]; wipe(t1)

		if hasLevelOne then
			t1[1] = startCoord
		end

		for i = minLvl, player.maxlevel do
			local levelTime = char.LevelTimeList[i]
			if levelTime then
				tinsert(t1, {i-minLvl+offset, levelTime}) -- level 2: 2+1-2 == 2
				YLevelHeight = levelTime > YLevelHeight and levelTime or YLevelHeight
			end
		end

		level:AddDataSeries(t1, levelColor)

		local t2 = S.recycle[5]; wipe(t2)

		if hasLevelOne then
			t2[1] = startCoord
		end

		for i = minLvl, player.maxlevel do
			if char.TotalTimeList[i] then
				tinsert(t2, {i-minLvl+offset, char.TotalTimeList[i]})
			end
		end
		total:AddDataSeries(t2, totalColor)

		level.XMin = 0; level.XMax = XLevels
		level.YMin = 0; level.YMax = YLevelHeight
		level:SetGridSpacing(1, YLevelHeight / 4)
		level:SetYLabels(nil, 1) -- no idea how this actually works...

		total.XMin = 0; total.XMax = XLevels
		total.YMin = 0; total.YMax = YTotalHeight
		total:SetGridSpacing(1, YTotalHeight / 4)
		total:SetYLabels(nil, 1)

		local realMinLvl = hasLevelOne and 1 or minLvl
		local midLvl = floor((MaxLvl+realMinLvl)/2) -- the spacing is kinda off when we round down values
		UpdateXLabels(level, total, realMinLvl, midLvl, MaxLvl)
	end
end

	-----------------
	--- DataFrame ---
	-----------------

-- I peeked into Prat's CopyChat code for the ScrollFrame & EditBox <.<
-- and FloatingChatFrameTemplate for the ResizeButton >.>
function RSD:DataFrame()
	if not ReadySetDingData then
		local f = CreateFrame("Frame", "ReadySetDingData", UIParent, "DialogBoxFrame")
		f:SetPoint("CENTER"); f:SetSize(600, 500)

		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
			edgeSize = 16,
			insets = { left = 8, right = 6, top = 8, bottom = 8 },
		})
		f:SetBackdropBorderColor(0, .44, .87, 0.5)

	---------------
	--- Movable ---
	---------------

		f:EnableMouse(true) -- also seems to be automatically enabled when setting the OnMouseDown script
		f:SetMovable(true); f:SetClampedToScreen(true)
		f:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				self:StartMoving()
			end
		end)
		f:SetScript("OnMouseUp", f.StopMovingOrSizing)

	-------------------
	--- ScrollFrame ---
	-------------------

		local sf = CreateFrame("ScrollFrame", "ReadySetDingDataScrollFrame", ReadySetDingData, "UIPanelScrollFrameTemplate")
		sf:SetPoint("LEFT", 16, 0)
		sf:SetPoint("RIGHT", -32, 0)
		sf:SetPoint("TOP", 0, -16)
		sf:SetPoint("BOTTOM", ReadySetDingDataButton, "TOP", 0, 0)

	---------------
	--- EditBox ---
	---------------

		local eb = CreateFrame("EditBox", "ReadySetDingDataEditBox", ReadySetDingDataScrollFrame)
		eb:SetSize(sf:GetSize()) -- seems inheriting the points won't automatically set the width/size

		eb:SetMultiLine(true)
		eb:SetFontObject("ChatFontNormal")
		eb:SetAutoFocus(false) -- make keyboard not automatically focused to this editbox
		eb:SetScript("OnEscapePressed", function(self)
			--self:ClearFocus()
			f:Hide() -- rather hide, since we only use it for copying to clipboard
		end)

		sf:SetScrollChild(eb)

	-----------------
	--- Resizable ---
	-----------------

		f:SetResizable(true)
		if S.isRetail then
			f:SetResizeBounds(150, 100)
		else
			f:SetMinResize(150, 100) -- at least show the "okay" button
		end

		local rb = CreateFrame("Button", "ReadySetDingDataResizeButton", ReadySetDingData)
		rb:SetPoint("BOTTOMRIGHT", -6, 7); rb:SetSize(16, 16)

		rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

		rb:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				f:StartSizing("BOTTOMRIGHT")
				self:GetHighlightTexture():Hide() -- we only want to see the PushedTexture now
				SetCursor("UI-Cursor-Size") -- hide the cursor
			end
		end)
		rb:SetScript("OnMouseUp", function(self, button)
			f:StopMovingOrSizing()
			self:GetHighlightTexture():Show()
			SetCursor(nil) -- show the cursor again
			eb:SetWidth(sf:GetWidth()) -- update editbox to the new scrollframe width
		end)

		f:Show()
	else
		ReadySetDingData:Show()
	end

	if ACD.OpenFrames.ReadySetDing_Parent then
		-- the ACD window's Strata is "FULLSCREEN_DIALOG", and changing FrameLevels seems troublesome
		ReadySetDingData:SetFrameStrata("TOOLTIP")
	end

	ReadySetDingDataEditBox:SetText(self:GetData())
	GameTooltip:Hide() -- most likely the popup frame will prevent the GameTooltip's OnLeave script from firing
end

function RSD:GetData()
	local t = S.recycle[6]; wipe(t)
	local s = S.recycle[7]; wipe(s)

	for i = 1, 6 do
		t[i] = S.recycle[i+7]; wipe(t[i])
	end

	-- Summary
	t[1][1] = "# "..ACHIEVEMENT_SUMMARY_CATEGORY
	for i = 2, player.maxlevel do
		if char.LevelTimeList[i] then
			-- use tinsert in the (likely) case of holes in the SavedVars tables
			tinsert(t[1], format("%s |cffF6ADC6%d|r - |cff71D5FF%d|r: |cffB6CA00%s|r -- %s: |cff71D5FF%s|r",
				LEVEL, i-1, i, self:Time(char.LevelTimeList[i]), L.TOTAL, self:Time(char.TotalTimeList[i])))
		end
	end

	-- Level Time
	t[2][1] = "# "..L.LEVEL_TIME
	for i = 2, player.maxlevel do
		if char.LevelTimeList[i] then
			tinsert(t[2], format("|cffF6ADC6%d|r-|cffB6CA00%d|r: |cff71D5FF%s|r", i-1, i, char.LevelTimeList[i]))
		end
	end

	-- Total Time
	t[3][1] = "# "..L.TOTAL_TIME
	for i = 2, player.maxlevel do
		if char.TotalTimeList[i] then
			tinsert(t[3], format("|cffB6CA00%d|r: |cff71D5FF%s|r", i, char.TotalTimeList[i]))
		end
	end

	-- Timestamp
	t[4][1] = "# "..L.TIMESTAMP
	for i = 1, player.maxlevel do
		if char.DateStampList[i] then
			tinsert(t[4], format("|cffB6CA00%d|r: |cff71D5FF%s|r", i, char.DateStampList[i]))
		end
	end

	-- Unix Timestamp
	t[5][1] = "# Unix "..L.TIMESTAMP
	for i = 1, player.maxlevel do
		if char.UnixTimeList[i] then
			tinsert(t[5], format("|cffB6CA00%d|r: |cff71D5FF%s|r", i, char.UnixTimeList[i]))
		end
	end

	-- Experience / Hour
	t[6][1] = format("# %s / %s", XP, S.HOUR)
	for i = 2, player.maxlevel do
		-- global.maxxp is added in v0.96
		local levelTime = char.LevelTimeList[i]
		local maxxp = self.db.global.maxxp[i-1]
		if levelTime and maxxp then
			levelTime = levelTime / 3600
			tinsert(t[6], format("|cffF6ADC6%d|r-|cffB6CA00%d|r: |cffFFFF00%s|r / |cff0070DD%.2f|r = |cff71D5FF%s|r", i-1, i, maxxp, levelTime, floor(maxxp / levelTime)))
		end
	end

	for i = 1, #t do
		s[i] = strjoin("\n", unpack(t[i]))
	end

	-- I suppose the color codes make the string kinda long -- gsub("|", "||")
	return strjoin("\n\n", unpack(s))
end
