local NAME, S = ...
local RSD = ReadySetDing

local ACD = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LG = LibStub("LibGraph-2.0")

local L = S.L
local cd = S.cd
local player = S.player
local legend = S.legend
local args = S.args

local profile, realm, char, stats

function RSD:RefreshDB2()
	profile = self.db.profile
	realm = self.db.realm
	char = self.db.char
	stats = char.stats
end

local time = time
local format, gsub = format, gsub

	---------------------
	--- GlobalStrings ---
	---------------------

-- "[NAME] has reached level [LEVEL]!"
local GUILD_NEWS_FORMAT6A = GUILD_NEWS_FORMAT6:gsub("%%s", "[NAME]"):gsub("%%d", "[LEVEL]")

-- coloring
local TIME_PLAYED_TOTAL2 = gsub(TIME_PLAYED_TOTAL, "%%s", "|cff71D5FF%%s|r")
local TIME_PLAYED_LEVEL2 = gsub(TIME_PLAYED_LEVEL, "%%s", "|cff71D5FF%%s|r")

-- remove "%d"
local SECONDS_ABBR2 = gsub(SECONDS_ABBR, "%%d ", "")
local MINUTES_ABBR2 = gsub(MINUTES_ABBR, "%%d ", "")
local HOURS_ABBR2 = gsub(HOURS_ABBR, "%%d ", "")
local DAYS_ABBR2 = gsub(DAYS_ABBR, "%%d ", "")

	----------------
	--- Defaults ---
	----------------

S.defaults = {
	profile = {
		ShowParty = true,
		ShowRaid = true,
		ShowGuild = true,
		ShowFriend = true,
		ShowRealID = true,
		ChatParty = true,
		
		ShowMsg = "<ICON> [<CHAN>] [<NAME>]: Level <LEVEL>",
		
		DingMsg = {
			L.MSG_PLAYER_DING,
			TUTORIAL_TITLE55,
			PLAYER_LEVEL_UP.."!",
			"Ding! "..LEVEL.." <LEVEL>",
			L.MSG_PLAYER_DING2,
		},
		
		ShowOutput = 2,
		Language = 1,
		DingDelay = 0,
		NumRandomDing = 5,
		
		LegacyTime = true,
		TimeMaxCount = 2,
		
		FilterPlayed = true,
		GuildMemberLevelDiff = true,
		LevelGraph = true,
		
		GuildAFK = true,
		FilterLevelAchiev = true,
		MinLevelFilter = 10,
		NumRandomGuild = 5,
		
		GuildMsg = {
			GUILD_NEWS_FORMAT6A,
			"<NAME> is now "..LEVEL.." <LEVEL>!",
			"<NAME> dinged "..LEVEL.." <LEVEL>",
			"<NAME> leveled up to <LEVEL>!",
			"<NAME>: <LEVEL> [<ZONE>]",
		},
		
		GratzAFK = true,
		FilterAchiev = true,
		GratzDelay = 0,
		GratzCooldown = 300,
		NumRandomGratz = 9,
		
		GratzMsg = {
			[1] = "<GZ>",
			[4] = "<GZ>!",
			[7] = "<RT> gz <RT>",
			[2] = "gz!",
			[5] = "gz =)",
			[8] = "grats",
			[3] = "<GZ> <EMOT>",
			[6] = "<GZ> <NAME>",
			[9] = "<GZ> <NAME> <EMOT>",
		},
		
		ScreenshotDelay = 1,
		
		LibSharedMediaSound = true,
		SoundDelay = 4,
		CustomSound = S.sounds[2],
		ExampleSound = 2,
		SoundWidget = LSM:GetDefault(LSM.MediaType.SOUND),
	}
}

local defaults = S.defaults

	---------------
	--- Options ---
	---------------

S.options = {
	type = "group",
	childGroups = "tab",
	name = format("|TInterface\\AddOns\\ReadySetDing\\Images\\Windows7_Logo:16:16:0:2|t %s |cffADFF2Fv%s|r |cffFFFFFF(|r|cff57A3FFBeta|r|cffFFFFFF)|r", NAME, S.VERSION),
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
					set = "SetValueShow",
					args = {
						ShowParty = {
							type = "toggle", order = 1,
							descStyle = "",
							name = " |cffA8A8FF"..PARTY.."|r",
						},
						ShowFriend = {
							type = "toggle", order = 2,
							descStyle = "",
							name = " "..FRIENDS_WOW_NAME_COLOR_CODE..FRIENDS.."|r",
						},
						ShowGuild = {
							type = "toggle", order = 3,
							descStyle = "",
							name = " |cff40FF40"..GUILD.."|r",
						},
						ShowRaid = {
							type = "toggle", order = 4,
							descStyle = "",
							name = " |cffFF7F00"..RAID.."|r",
						},
						ShowRealID = {
							type = "toggle", order = 5,
							descStyle = "",
							name = " "..FRIENDS_BNET_NAME_COLOR_CODE..BATTLENET_FRIEND.."|r",
						},
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
								local raceIcon = S.GetRaceIcon(strupper(select(2, UnitRace("player"))).."_"..S.sexremap[UnitSex("player")], 1, 3)
								local classIcon = S.GetClassIcon(select(2, UnitClass("player")), 2, 3)
								args.icon = raceIcon..classIcon
								args.chan = GetNumRaidMembers() > 0 and "|cffFF7F00"..RAID.."|r" or "|cffA8A8FF"..PARTY.."|r"
								args.name = "|cff"..S.classCache[player.englishClass].._G.NAME.."|r"
								args.level = "|cffADFF2F"..player.level + (player.level == player.maxlevel and 0 or 1).."|r"
								return "  "..RSD:ReplaceArgs(profile.ShowMsg, args)
							end,
						},
					},
				},
				inline2 = {
					type = "group", order = 2,
					name = "|cff3FBF3F"..CHAT_ANNOUNCE.."|r",
					inline = true,
					args = {
						ChatParty = {
							type = "toggle", order = 1,
							descStyle = "",
							name = "|TInterface\\Icons\\Ability_Warrior_RallyingCry:16:16:1:0"..S.crop.."|t  |cffA8A8FF"..PARTY.."|r",
						},
						ChatGuild = {
							type = "toggle", order = 2,
							descStyle = "",
							name = function()
								local emblem
								if IsInGuild() and GuildFrameTabardEmblem and time() > (cd.emblem or 0) then
									cd.emblem = time() + 60
									char.GuildEmblem = {GuildFrameTabardEmblem:GetTexCoord()}
									emblem = format("|TInterface\\GuildFrame\\GuildEmblemsLG_01:30:30:-3:1:32:32:%s:%s:%s:%s|t", char.guildTexCoord[1]*32, char.guildTexCoord[7]*32, char.guildTexCoord[2]*32, char.guildTexCoord[8]*32)
								else
									emblem = "|TInterface\\GuildFrame\\GuildLogo-NoLogo:30:30:-3:1|t"
								end
								return emblem.."|cff40FF40"..GUILD.."|r"
							end,
						},
						DingRandom = {
							type = "toggle", order = 3,
							descStyle = "",
							name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:16:16:1:1|t  |cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
						},
						ChatZone = {
							type = "toggle", order = 4,
							descStyle = "",
							name = "|TInterface\\Icons\\INV_Misc_Map_01:16:16:1:0"..S.crop.."|t  "..ZONE,
						},
						ChatBroadcast = {
							type = "toggle", order = 5,
							desc = BN_BROADCAST_TOOLTIP,
							name = "|TInterface\\FriendsFrame\\PlusManz-BattleNet:24|t  |cff82C5FF"..BATTLENET_FRIEND.."|r",
						},
						NumRandomDing = {
							type = "range", order = 6,
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
				spacing1 = {type = "description", order = 3, name = ""},
				LevelSummary = {
					type = "description", order = 4,
					fontSize = "medium",
					name = function()
						local revt = S.recycle[1]; wipe(revt)
						local tsize = #char.LevelSummary + 1
						for i, v in pairs(char.LevelSummary) do
							revt[tsize-i] = v
						end
						return strjoin("\n", unpack(revt))
					end,
				},
			},
		},
		advanced = {
			type = "group", order = 2,
			name = ADVANCED_LABEL,
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
							name = "   Output",
							values = function()
								local c = "|cff2E9AFE"
								local t = {
									c.."#|r  "..(SHOW_COMBAT_TEXT == "0" and "|cff979797" or "")..COMBAT_TEXT_LABEL, -- new
									c.."#|r  RaidWarningFrame",
									c.."#|r  RaidBossEmoteFrame",
									c.."#|r  UIErrorsFrame",
								}
								for i = 1, NUM_CHAT_WINDOWS do
									local window = GetChatWindowInfo(i)
									if #window > 0 then
										t[i+4] = c..i..".|r "..window
									end
								end
								return t
							end,
							set = function(i, v)
								profile.ShowOutput = v
								RSD:Output()
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
						DingDelay = {
							type = "range", order = 1,
							desc = "("..strlower(SECONDS)..")",
							name = L.DELAY,
							min = 0, softMin = 0,
							max = 60, softMax = 10,
							step = 0.5,
						},
						Language = {
							type = "select", order = 2,
							descStyle = "",
							name = "   "..LANGUAGES_LABEL,
							values = function()
								local color, languages = "|cff2E9AFE", {}
								languages[1] = color.."#|r  "..DEFAULT
								languages[2] = color.."#|r  Random"
								for i = 1, GetNumLanguages() do
									languages[i+2] = color..i..".|r "..GetLanguageByIndex(i)
								end
								return languages
							end,
							
						},
						spacing1 = {type = "description", order = 3, name = " "},
					},
				},
				inline3 = {
					type = "group", order = 3,
					name = "|cff3FBF3F"..L.TIME_FORMAT.."|r",
					inline = true,
					args = {
						LegacyTime = {
							type = "toggle", order = 1,
							width = "full",
							desc = function() return "|cffF6ADC6"..RSD:TimeString(S.LegacyTime).."|r" end,
							name = function() return (profile.LegacyTime and "" or "|cff979797")..L.TIME_FORMAT_LEGACY end,
						},
						TimeMaxCount = {
							type = "range", order = 2,
							desc = function() return "|cffF6ADC6"..SecondsToTime(S.TimeUnits[profile.TimeMaxCount], profile.TimeOmitSec, not profile.TimeAbbrev, profile.TimeMaxCount).."|r" end,
							name = "   "..L.TIME_MAX_UNITS,
							min = 1,
							max = 4,
							step = 1,
							hidden = function() return profile.LegacyTime end,
						},
						TimeOmitSec = {
							type = "toggle", order = 3,
							desc = SECONDS.." -> |cffFF0000"..NOT_APPLICABLE.."|r",
							name = L.TIME_OMIT_SECONDS,
							hidden = function() return profile.LegacyTime end,
						},
						TimeAbbrev = {
							type = "toggle", order = 4,
							desc = format("%s -> %s\n%s -> %s\n%s -> %s\n%s -> %s", SECONDS, SECONDS_ABBR2, MINUTES, MINUTES_ABBR2, HOURS, HOURS_ABBR2, DAYS, DAYS_ABBR2),
							name = L.TIME_ABBREVIATE,
							hidden = function() return profile.LegacyTime end,
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
				LevelGraph = {
					type = "toggle", order = 6,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\Spell_Fire_BurningSpeed:16:16:1:0"..S.crop.."|t  "..L.LEVEL_GRAPH,
					set = function(i, v)
						profile.LevelGraph = v
						-- when opened in Blizzard Options Panel
						if not ReadySetDing_LevelGraph then return end
						ReadySetDing_LevelGraph[v and "Show" or "Hide"](ReadySetDing_LevelGraph)
					end,
				},
				FilterPlayed = {
					type = "toggle", order = 7,
					width = "full",
					desc = function()
						local level = format(TIME_PLAYED_LEVEL2, format(TIME_DAYHOURMINUTESECOND, unpack( {ChatFrame_TimeBreakDown(S.curTPM + time() - S.lastPlayed)} )))
						local total = format(TIME_PLAYED_TOTAL2, format(TIME_DAYHOURMINUTESECOND, unpack( {ChatFrame_TimeBreakDown(S.totalTPM + time() - S.lastPlayed)} )))
						return format("%s\n\n%s\n\n%s", level, total, L.NOT_FILTER_OTHER_ADDONS)
					end,
					name = "|TInterface\\Icons\\Spell_Holy_Silence:16:16:1:0"..S.crop.."|t  "..L.FILTER_PLAYED_MESSAGE,
				},
				GuildMemberLevelDiff = {
					type = "toggle", order = 8,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\INV_Misc_Book_07:16:16:1:0"..S.crop.."|t  "..L.GUILDMEMBER_LEVEL_DIFF_LOGIN,
				},
			},
		},
		guildmember = {
			type = "group", order = 3,
			name = GUILD,
			handler = RSD,
			get = "GetValue",
			set = "SetValue",
			args = {
				AnnGuildMember = {
					type = "toggle", order = 1,
					width = "full", descStyle = "",
					name = "|TINTERFACE\\ICONS\\achievement_guildperk_fasttrack_rank2:16:16:1:1"..S.crop.."|t  "..L.ANNOUNCE_GUILDMEMBER_LEVELUP,
				},
				inline1 = {
					type = "group", order = 2,
					name = " ",
					inline = true,
					disabled = function() return not profile.AnnGuildMember end,
					args = {
						GuildAFK = {
							type = "toggle", order = 1,
							width = "full", descStyle = "",
							name = "|TInterface\\Icons\\Spell_Nature_Sleep:16:16:1:0"..S.crop.."|t  "..L.DISABLE_AFK,
						},
						GuildRandom = {
							type = "toggle", order = 2,
							width = "full", descStyle = "",
							name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:16:16:1:1|t  |cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
						},
						FilterLevelAchiev = {
							type = "toggle", order = 3,
							width = "full", descStyle = "",
							name = " "..L.FILTER_LEVEL_ACHIEVEMENTS,
						},
						AchievExample = {
							type = "description", order = 4,
							name = "         "..strjoin("  ", unpack(S.AchievIcons))
						},
						spacing1 = {type = "description", order = 5, name = " "},
						MinLevelFilter = {
							type = "range", order = 6,
							descStyle = "",
							name = " "..L.MINIMUM_LEVEL_FILTER,
							min = 2,
							max = 85,
							step = 1,
						},
						NumRandomGuild = {
							type = "range", order = 7,
							descStyle = "",
							name = "# |cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
							min = 2, softMin = 2,
							max = 100, softMax = 25,
							step = 1,
							set = function(i, v)
								profile.NumRandomGuild = v
								RSD:SetupRandomGuild(v)
							end,
							hidden = function() return not profile.GuildRandom end,
						},
					},
				},
				GuildMsg1 = {
					type = "input", order = 3,
					width = "full", usage = legend.guild,
					name = " ",
					get = function(i) return profile.GuildMsg[1] end,
					set = function(i, v)
						profile.GuildMsg[1] = (strtrim(v) == "") and defaults.profile.GuildMsg[1] or v
						RSD:ValidateLength(RSD:PreviewGuild(1))
						S.activePreview[2] = nil
					end,
				},
				PreviewGuild = {
					type = "description", order = 4,
					fontSize = "medium",
					name = function() return RSD:PreviewGuild(1) end,
				},
				spacing1 = {type = "description", order = -2, name = " "},
				GuildMemberLevelSpeed = {
					type = "execute", order = -1,
					name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:-1"..S.crop.."|t |cffFFFFFF"..L.LEVEL_SPEED.."|r",
					func = function()
						local list = S.recycle[1]; wipe(list)
						for i = 1, GetNumGuildMembers() do
							local name, _, level = GetGuildRosterInfo(i)
							if realm[name] and realm[name][level] then
								-- drycoded
								for j = 3, 1, -1 do
									-- ignore the [1] index
									if realm[name][level-j] and level-j >= 1 then
										local speed = (time()-realm[name][level-j][1]) / (3600*j)
										list[speed] = name
										break
									end
								end
							end
						end
						
						local t = S.recycle[2]; wipe(t)
						for k in pairs(list) do
							tinsert(t, k)
						end
						sort(t)
						
						for i, v in ipairs(t) do
							print(format("#%d |cff71D5FF%s|r |cffADFF2F%.2f|r %s/%s (|cffB6CA00%s|r)", i, list[v], v, S.HOUR, LEVEL, realm[list[v]][1]))
						end
					end,
					hidden = function() return not IsInGuild() end,
				},
			},
		},
		autogratz = {
			type = "group", order = 4,
			name = L.AUTO_GRATZ,
			handler = RSD,
			get = "GetValue",
			set = "SetValue",
			args = {
				AutoGratz = {
					type = "toggle", order = 1,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\INV_Misc_Gift_05:16:16:1:0"..S.crop.."|t  "..L.AUTO_GRATZ,
				},
				inline1 = {
					type = "group", order = 2,
					name = " ",
					inline = true,
					disabled = function() return not profile.AutoGratz end,
					args = {
						GratzAFK = {
							type = "toggle", order = 1,
							width = "full", descStyle = "",
							desc = "|cffFFFF00\""..MARKED_AFK.."\"|r",
							name = "|TInterface\\Icons\\Spell_Nature_Sleep:16:16:1:0"..S.crop.."|t  "..L.DISABLE_AFK,
						},
						GratzRandom = {
							type = "toggle", order = 2,
							width = "full", descStyle = "",
							name = "|TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:16:16:1:1|t  |cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
						},
						AnyAchiev = {
							type = "toggle", order = 3,
							descStyle = "",
							name = "|TInterface\\Icons\\Achievement_Reputation_06:16:16:1:1"..S.crop.."|t  |cffFFFF00"..ACHIEVEMENTS.."|r",
						},
						FilterAchiev = {
							type = "toggle", order = 4,
							desc = "Internal Blacklist",
							name = "|TInterface\\Icons\\Trade_Engineering:16:16:1:1"..S.crop.."|t  +"..FILTER,
							disabled = function() return not profile.AutoGratz or not profile.AnyAchiev end,
						},
						spacing1 = {type = "description", order = 5, name = " "},
						GratzDelay = {
							type = "range", order = 6,
							desc = "0 = |cffFF8000Random|r 3-17 "..strlower(SECONDS),
							name = L.DELAY,
							min = 0, softMin = 0,
							max = 60, softMax = 10,
							step = 0.5,
						},
						GratzCooldown = {
							type = "range", order = 7,
							desc = function() return format(ITEM_COOLDOWN_TOTAL_SEC, profile.GratzCooldown) end,
							name = L.COOLDOWN,
							min = 0, softMin = 0,
							max = 1200, softMax = 600,
							step = 1,
						},
						NumRandomGratz = {
							type = "range", order = 8,
							descStyle = "",
							name = "# |cffF6ADC6"..L.RANDOM_MESSAGE.."|r",
							min = 2, softMin = 2,
							max = 99, softMax = 30,
							step = 1,
							set = function(i, v)
								profile.NumRandomGratz = v
								RSD:SetupRandomGratz(v)
							end,
							hidden = function() return not profile.GratzRandom end,
						},
					},
				},
				GratzMsg1 = {
					type = "input", order = 10,
					name = " ",
					usage = legend.gratz,
					get = function(i) return profile.GratzMsg[1] end,
					set = function(i, v) profile.GratzMsg[1] = (strtrim(v) == "") and defaults.profile.GratzMsg[1] or v end,
				},
				inline2 = {
					type = "group", order = -1,
					name = " ",
					inline = true,
					args = {
						RaidTarget = {
							type = "description", order = 1,
							fontSize = "medium",
							name = S.RaidTargetIcons.."\n",
						},
						ExampleMessage = {
							type = "description", order = 2,
							fontSize = "medium",
							name = "|cff71D5FF[RT]|r = {rt1-8}\n|cff71D5FF[GZ]|r = "..strjoin(", ", unpack(legend.gz)).."\n|cff71D5FF[EMOT]|r = "..strjoin(", ", unpack(legend.emot)),
						},
					},
				},
			},
		},
		screenshot = {
			type = "group", order = 5,
			name = BINDING_NAME_SCREENSHOT,
			handler = RSD,
			get = "GetValue",
			set = "SetValue",
			args = {
				Screenshot = {
					type = "toggle", order = 1,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\inv_misc_spyglass_03:16:16:1:0"..S.crop.."|t  "..BINDING_NAME_SCREENSHOT,
				},
				inline1 = {
					type = "group", order = 2,
					name = " ",
					inline = true,
					disabled = function() return not profile.Screenshot end,
					args = {
						HideUI = {
							type = "toggle", order = 1,
							width = "full", descStyle = "",
							name = "|TInterface\\Icons\\INV_Gizmo_GoblingTonkController:16:16:1:0"..S.crop.."|t  "..L.SCREENSHOT_HIDE_UI,
						},
						spacing1 = {type = "description", order = 2, name = ""},
						ScreenshotDelay = {
							type = "range", order = 3,
							desc = "("..strlower(SECONDS)..")",
							name = L.DELAY,
							min = 0, softMin = 0,
							max = 60, softMax = 2,
							step = 0.1,
						},
					},
				},
				ReadySet7 = {
					type = "description", order = 3,
					name = "|TInterface\\AddOns\\ReadySetDing\\Images\\ReadySet7:32:128:9:-3|t"
				},
				Windows7Awesome = {
					type = "description", order = 4,
					name = " |TInterface\\AddOns\\ReadySetDing\\Images\\Windows7_Logo:64:64:0:0|t    |TInterface\\AddOns\\ReadySetDing\\Images\\Awesome:64:64:0:0|t"
				},
				spacing1 = {type = "description", order = 5, name = " "},
				PrintSummary = {
					type = "execute", order = 6,
					name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:1:-1"..S.crop.."|t  |cffFFFFFFSummary|r",
					func = function()
						for i = 2, player.maxlevel do
							if char.LevelTimeList[i] then
								print(format("%s |cffF6ADC6%d|r - |cff71D5FF%d|r: |cffB6CA00%s|r ; %s: |cff71D5FF%s|r",
									LEVEL, i-1, i, RSD:Time(char.LevelTimeList[i], true), L.TOTAL, RSD:Time(char.TotalTimeList[i], true)))
							end
						end
					end,
				},
				newline1 = {type = "description", order = 7, name = ""},
				ExportPrint = {
					type = "execute", order = 8,
					name = "|TInterface\\Icons\\Trade_Engineering:16:16:1:-1"..S.crop.."|t  |cffFFFFFFExport to |cff71D5FFprint|r|r",
					func = function() RSD:ExportData(print) end,
				},
				newline2 = {type = "description", order = 9, name = ""},
				ExportSay = {
					type = "execute", order = 10,
					name = "|TInterface\\Icons\\Trade_Engineering:16:16:1:-1"..S.crop.."|t  |cffFFFFFFExport to|r |cffFFFF00"..SLASH_SAY2.."|r",
					confirm = true, confirmText = L.ARE_YOU_SURE.." (|cffFF0000"..BNET_REPORT_SPAM.."|r)",
					func = function() RSD:ExportData(SendChatMessage) end,
				},
			},
		},
		sound = {
			type = "group", order = 6,
			name = SOUND_LABEL,
			handler = RSD,
			get = "GetValue",
			set = "SetValue",
			args = {
				Sound = {
					type = "toggle", order = 1,
					width = "full", descStyle = "",
					name = "|TInterface\\Icons\\INV_Misc_Bell_01:16:16:1:0"..S.crop.."|t  "..SOUND_LABEL,
				},
				LibSharedMediaSound = {
					type = "toggle", order = 2,
					width = "full", descStyle = "",
					name = "|TInterface\\Common\\VOICECHAT-SPEAKER:20:20:4:0|t |cff4E96F7LibSharedMedia|r "..SOUND_LABEL,
				},
				inline1 = {
					type = "group", order = 3,
					name = " ",
					inline = true,
					disabled = function() return not profile.Sound end,
					args = {
						SoundWidget = {
							type = "select", order = 1,
							descStyle = "",
							values = LSM:HashTable("sound"),
							dialogControl = "LSM30_Sound",
							name = "",
							hidden = function() return not profile.LibSharedMediaSound end,
						},
						CustomSound = {
							type = "input", order = 2,
							width = "full",
							desc = "|cffFF0000Note:|r Client Restart is required for loading custom sound files",
							name = "   "..L.SOUND_PATH,
							set = function(i, v) profile.CustomSound = (strtrim(v) == "") and defaults.profile.CustomSound or v end,
							hidden = function() return profile.LibSharedMediaSound end,
						},
						ExampleSound = {
							type = "select", order = 3,
							width = "full", descStyle = "",
							name = "   "..L.EXAMPLES,
							values = S.sounds,
							set = function(i, v)
								profile.ExampleSound = v
								profile.CustomSound = S.sounds[v]
							end,
							hidden = function() return profile.LibSharedMediaSound end,
						},
						spacing1 = {type = "description", order = 4, name = " "},
						SoundDelay = {
							type = "range", order = 5,
							desc = "("..strlower(SECONDS)..")",
							name = L.DELAY,
							min = 0, softMin = 0,
							max = 60, softMax = 10,
							step = 1,
						},
					},
				},
				TestSound = {
					type = "execute", order = 4,
					name = L.TEST,
					width = "half",
					func = function()
						-- would be kinda annoying if someone accidentally spammed
						-- this in combination with long sound files
						if time() > (cd.TestSound or 0) then
							cd.TestSound = time() + 1
							if profile.CustomSound == S.sounds[2] then
								PlaySoundFile(S.sounds[random(3, #S.sounds)], "Master")
							else
								PlaySoundFile(profile.CustomSound, "Master")
							end
						end
					end,
					hidden = function() return profile.LibSharedMediaSound end,
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

function RSD:SetValueShow(i, v)
	profile[i[#i]] = v

	-- require both ShowParty and ShowRaid being disabled, in order to unregister UNIT_LEVEL
	local event = S.levelremap[i[#i]]
	v = (event == "UNIT_LEVEL") and S.ShowGroup() or v
	self[v and "RegisterEvent" or "UnregisterEvent"](self, event)
end

function RSD:RefreshShowEvents()
	for option, event in pairs(S.levelremap) do
		local v = (event == "UNIT_LEVEL") and S.ShowGroup() or profile[option]
		self[v and "RegisterEvent" or "UnregisterEvent"](self, event)
	end
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

function RSD:SetupRandomGuild(num)
	local guild = options.args.guildmember.args
	
	for i = prev[2] or 2, num do
		guild["GuildMsg"..i] = {
			type = "input", order = (i+2)*2, -- 6, 8, 10, ...
			width = "full", name = "",
			get = function(info) return profile.GuildMsg[i] end,
			set = function(info, v)
				if strtrim(v) == "" then
					profile.GuildMsg[i] = defaults.profile.GuildMsg[i]
				else
					profile.GuildMsg[i] = v
				end
				self:ValidateLength(self:PreviewGuild(i))
				S.activePreview[2] = i
			end,
			hidden = function() return not profile.GuildRandom end,
		}
		guild["GuildPreview"..i] = {
			type = "description", order = (i+2)*2+1,
			fontSize = "medium",
			name = function() return self:PreviewGuild(i) end,
			hidden = function() return not profile.GuildRandom or S.activePreview[2] ~= i end,
		}
	end
	
	for i = num+1, prev[2] or 0 do
		guild["GuildMsg"..i] = nil
		guild["GuildPreview"..i] = nil
	end
	prev[2] = num
end

function RSD:SetupRandomGratz(num)
	local gratz = options.args.autogratz.args
	
	for i = prev[3] or 2, num do
		gratz["GratzMsg"..i] = {
			type = "input", order = i+10,
			name = "",
			get = function(info) return profile.GratzMsg[i] end,
			set = function(info, v)
				if strtrim(v) == "" then
					profile.GratzMsg[i] = defaults.profile.GratzMsg[i]
				else
					profile.GratzMsg[i] = v
				end
			end,
			hidden = function() return not profile.GratzRandom end,
		}
	end
	
	for i = num+1, prev[3] or 0 do
		gratz["GratzMsg"..i] = nil
	end
	prev[3] = num
end

	----------------
	--- Validate ---
	----------------

function RSD:ValidateLength(msg)
	-- my patterns. just. suck. ><
	local msg = self:ReplaceArgs(msg, args)
	msg = msg:gsub("|cff......", "")
	msg = msg:gsub("|r", "")
	msg = msg:gsub("|T.-|t", "{rtN}")

	-- notify if message length exceeds 127 or 255 chars
	local len = strlen(msg)-2 -- account for the two prepending blank spaces in preview
	if len > 127 and profile.ChatBroadcast then
		self:Print("|cff71D5FF"..BATTLENET_FRIEND.."|r |cffFF0000Message > 127 chars|r|r ("..len..")")
	end
	if len > 255 then
		self:Print("|cffFF0000Message > 255 chars|r ("..len..")")
	end
end

	---------------
	--- Preview ---
	---------------

function RSD:PreviewDing(i)
	local args = args
	args.level = "|cffADFF2F"..player.level + (player.level == player.maxlevel and 0 or 1).."|r"
	args["level-"] = "|cffF6ADC6"..player.level.."|r"
	args["level#"] = "|cffF6ADC6"..player.maxlevel.."|r"
	args["level%"] = "|cffF6ADC6"..player.maxlevel - (player.level + 1).."|r"
	args.time = "|cff71D5FF"..self:Time(S.curTPM + time() - S.lastPlayed).."|r"
	args.total = "|cff71D5FF"..self:Time(S.totalTPM + time() - S.lastPlayed).."|r"
	args.date = "|cff0070DD"..date("%Y.%m.%d %H:%M:%S").."|r"
	args.date2 = "|cff0070DD"..date("%m/%d/%y %H:%M:%S").."|r"
	args.afk = "|cffFFFF00"..self:Time(stats.timeAFK).."|r"
	args["afk+"] = "|cffFFFF00"..self:Time(stats.totalAFK).."|r"
	args.death = "|cffFF0000"..stats.death.."|r"
	args["death+"] = "|cffFF0000"..self:AchievStat("death").."|r"
	args.quest = "|cff58ACFA"..self:AchievStat("quest").."|r"
	args.rt = "|T"..S.RT..random(8)..":16:16:0:3|t"
	-- hidden args
	args.name = "|cffADFF2F"..player.name.."|r"
	args.class = "|cffADFF2F"..player.class.."|r"
	args.race = "|cffADFF2F"..player.race.."|r"
	args.faction = "|cffADFF2F"..player.faction.."|r"
	args.realm = "|cffADFF2F"..player.realm.."|r"
	args.zone = "|cff58ACFA"..(GetRealZoneText() or GetSubZoneText() or ZONE).."|r"
	args.guild = "|cffADFF2F"..(GetGuildInfo("player") or ERR_GUILD_PLAYER_NOT_IN_GUILD).."|r"
	args.ilv = "|cffA335EE"..floor(GetAverageItemLevel()).."|r"
	
	local msg = self:PreviewRaidTarget(profile.DingMsg[i])
	return "  "..self:ReplaceArgs(msg, args)
end

function RSD:PreviewGuild(i)
	if IsInGuild() and GetNumGuildMembers() > 0 then -- sanity check
		local name, rank, _, level, class, zone = GetGuildRosterInfo(random((GetNumGuildMembers())))
		if not name then return ERROR_CAPS end -- sanity check
		
		local args = args
		args.level = "|cffADFF2F"..((level == player.maxlevel) and level or level+1).."|r" -- fix level 86
		args["level-"] = "|cffF6ADC6"..level.."|r"
		args.realtime = "|cff71D5FF"..self:Time(random(600, 7200)).."|r"
		args.name = "|cff71D5FF"..name.."|r"
		args.class = "|cff0070DD"..class.."|r"
		args.rank = "|cff0070DD"..rank.."|r"
		args.zone = "|cff0070DD"..(zone or ZONE).."|r"
		args.rt = "|T"..S.RT..random(8)..":16:16:0:3|t"
		
		local msg = self:PreviewRaidTarget(profile.GuildMsg[i])
		return "  "..self:ReplaceArgs(msg, args)
	else
		return "  |cffFFFF00"..ERR_GUILD_PLAYER_NOT_IN_GUILD.."|r"
	end
end

function RSD:PreviewRaidTarget(msg)
	-- undefined random message
	if not msg then return end
	-- convert Raid Target icons; FrameXML\ChatFrame.lua L3168 (4.3.3.15354)
	for k in gmatch(msg, "%b{}") do
		local rt = strlower(gsub(k, "[{}]", ""))
		if ICON_TAG_LIST[rt] and ICON_LIST[ICON_TAG_LIST[rt]] then
			msg = msg:gsub(k, ICON_LIST[ICON_TAG_LIST[rt]].."16:16:0:3|t")
		end
	end
	return msg
end

	-------------
	--- Graph ---
	-------------

-- AceConfigDialog frames are created on opening
hooksecurefunc(ACD, "Open", function(self, app)
	if not next(char.LevelTimeList) or not profile.LevelGraph then return end
	
	-- also gets called by Blizard Options Panel
	if app == "ReadySetDing_Parent" and ACD.OpenFrames.ReadySetDing_Parent then
		if not ReadySetDing_LevelGraph then
			-- if there are multiple ACD frames shown, this seems to parent to the first one instead, when the second one is opened
			local level = LG:CreateGraphLine("ReadySetDing_LevelGraph", ACD.OpenFrames.ReadySetDing_Parent.frame, "TOPLEFT", "TOPRIGHT", 5, -65, 0, 200)
			local total = LG:CreateGraphLine("ReadySetDing_TotalGraph", ReadySetDing_LevelGraph, "TOPLEFT", "BOTTOMLEFT", 0, -40, 0, 200)
			RSD:UpdateGraph(level, total)
			
			-- ACD frames get "recycled", so the graphs could possibly show up next to another addon as well
			-- There is the physical "Close" button and ACD.CloseAll, this hook accounts for both methods
			hooksecurefunc(self.OpenFrames.ReadySetDing_Parent, "OnRelease", function()
				level:Hide()
			end)
		else
			ReadySetDing_LevelGraph:Show()
		end
	end
end)

do
	local t1, t2 = {}, {}
	
	function RSD:UpdateGraph(level, total)
		local XWidth = table.maxn(char.LevelTimeList) - 1
		local XRealWidth = min(XWidth * 25, 400)
		
		level:SetWidth(XRealWidth)
		total:SetWidth(XRealWidth)
		
		local YLevelHeight = 0
		local YTotalHeight = char.TotalTimeList[table.maxn(char.TotalTimeList)]
		
		wipe(t1); t1[1] = {0, 0}
		for i = 2, player.maxlevel do
			local levelTime = char.LevelTimeList[i]
			if levelTime then
				tinsert(t1, {i-1, levelTime})
				YLevelHeight = levelTime > YLevelHeight and levelTime or YLevelHeight
			end
		end
		level:AddDataSeries(t1, {.68, 1, .18, .7})
		
		wipe(t2); t2[1] = {0, 0}
		for i = 2, player.maxlevel do
			if char.TotalTimeList[i] then
				tinsert(t2, {i-1, char.TotalTimeList[i]})
			end
		end
		total:AddDataSeries(t2, {.44, .84, 1, .7})
		
		level.XMin = 0; level.XMax = XWidth
		level.YMin = 0; level.YMax = YLevelHeight
		level:SetGridSpacing(1, YLevelHeight / 4)
		
		total.XMin = 0; total.XMax = XWidth
		total.YMin = 0; total.YMax = YTotalHeight
		total:SetGridSpacing(1, YTotalHeight / 4)
	end
end

	--------------
	--- Export ---
	--------------

do
	-- a = delay; b = coloring for print; c = header
	local a, b, c = {}, {}, {}
	
	-- try to avoid spamming the server
	function RSD:ExportData(sink)
		
		-- why is there a throttle here anyway ... button bashers? spammers? xD
		if time() > (cd.export or 0) then
			cd.export = time() + 3
			
			if sink == print then
				for i = 1, 5 do
					a[i] = 0.5 * (i-1) -- 0, 0.5, 1, 1.5, 2.0
				end
				b[1], b[2], b[3], b[4], b[5] = "|r", "|cffF6ADC6", "|cffB6CA00", "|cff71D5FF", "|cffFFFF00"
				
			elseif sink == SendChatMessage and time() > (cd.exportsay or 0) then
				-- try to make sure LoggingChat will be correctly set to it's previous value after the delay
				cd.exportsay = time() + 17
				for i = 1, 5 do
					a[i] = 4 * (i-1) -- 0, 4, 8, 12, 16
					b[i] = ""
				end
				
				local isLogging = LoggingChat()
				LoggingChat(true) -- start logging
				
				self:ScheduleTimer(function()
					LoggingChat(isLogging) -- revert to original
					self:Print("Logged Data to |cff71D5FF...\\Logs\\WoWChatLog.txt|r")
				end, 17)
			end
			
			-- Level Time
			self:ScheduleTimer(function()
				for i = 2, player.maxlevel do
					if char.LevelTimeList[i] then
						if not c[1] then sink("# "..L.LEVEL_TIME); c[1] = true end
						sink(format("%s%d%s-%s%d%s: %s%s%s", b[2], i-1, b[1], b[3], i, b[1], b[4], char.LevelTimeList[i], b[1]))
					end
				end
			end, a[1])
			
			-- Total Time
			self:ScheduleTimer(function()
				for i = 2, player.maxlevel do
					if char.TotalTimeList[i] then
						if not c[2] then sink("# "..L.TOTAL_TIME); c[2] = true end
						sink(format("%s%d%s-%s%d%s: %s%s%s", b[2], 1, b[1], b[3], i, b[1], b[4], char.TotalTimeList[i], b[1]))
					end
				end
			end, a[2])
						
			-- Unix Timestamp
			self:ScheduleTimer(function()
				for i = 1, player.maxlevel do
					if char.UnixTimeList[i] then
						if not c[3] then sink("# Unix "..L.TIMESTAMP); c[3] = true end
						sink(format("%s%d%s: %s%s%s", b[3], i, b[1], b[4], char.UnixTimeList[i], b[1]))
					end
				end
				wipe(c) -- reset headers
			end, a[3])
			
			-- Timestamp
			self:ScheduleTimer(function()
				for i = 1, player.maxlevel do
					if char.DateStampList[i] then
						if not c[4] then sink("# "..L.TIMESTAMP); c[4] = true end
						sink(format("%s%d%s: %s%s%s", b[3], i, b[1], b[4], char.DateStampList[i], b[1]))
					end
				end
			end, a[4])
			
			-- Experience / Hour
			self:ScheduleTimer(function()
				for i = 2, player.maxlevel do
					-- global.maxxp is added in v0.96
					if char.LevelTimeList[i] and self.db.global.maxxp[i-1] then
						if not c[5] then sink(format("# %s/%s (%s%s%s)", XP, S.HOUR, b[5], MAXIMUM.." "..XP, b[1])); c[5] = true end
						sink(format("%s%d%s-%s%d%s: %s%s%s (%s%s%s)",
							b[2], i-1, b[1], b[3], i, b[1], b[4], floor(self.db.global.maxxp[i-1] / (char.LevelTimeList[i]/3600)), b[1], b[5], self.db.global.maxxp[i-1], b[1]))
					end
				end
			end, a[5])
		end
	end
end
