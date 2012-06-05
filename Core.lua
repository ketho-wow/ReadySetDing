local NAME, S = ...
local RSD = ReadySetDing

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local L = S.L
local options = S.options
local player = S.player
local cd = S.cd
local args = S.args

local profile, realm, char

S.lastPlayed = time()
S.totalTPM, S.curTPM = 0, 0
local curTPM2, totalTPM2

local pairs, ipairs = pairs, ipairs
local format, gsub = format, gsub

	---------------------------
	--- Ace3 Initialization ---
	---------------------------

local appKey = {
	"ReadySetDing_Main",
	"ReadySetDing_Advanced",
	"ReadySetDing_GuildMember",
	"ReadySetDing_AutoGratz",
	"ReadySetDing_Screenshot",
}

local appValue = {
	ReadySetDing_Main = options.args.main,
	ReadySetDing_Advanced = options.args.advanced,
	ReadySetDing_GuildMember = options.args.guildmember,
	ReadySetDing_AutoGratz = options.args.autogratz,
	ReadySetDing_Screenshot = options.args.screenshot,
	ReadySetDing_Data = options.args.data,
}

local slashCmds = {"rsd", "readyset", "readysetding"}

function RSD:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ReadySetDingDB", S.defaults, true)
	
	self.db.global.version = S.VERSION
	self.db.global.build = S.BUILD
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
	self:RefreshDB()
	
	ACR:RegisterOptionsTable("ReadySetDing_Parent", options)
	ACD:AddToBlizOptions("ReadySetDing_Parent", NAME)
	ACD:SetDefaultSize("ReadySetDing_Parent", 650, 575)
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME)
	end
	
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	profiles.order = 6
	profiles.name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:-2:-1"..S.crop.."|t "..profiles.name
	ACR:RegisterOptionsTable("ReadySetDing_Profiles", profiles)
	ACD:AddToBlizOptions("ReadySetDing_Profiles", profiles.name, NAME)
	
	----------------------
	--- Slash Commands ---
	----------------------
	
	for _, v in ipairs(slashCmds) do
		self:RegisterChatCommand(v, "SlashCommand")
	end
	
	-----------------------------
	--- Custom SavedVariables ---
	-----------------------------
	
	char.LevelTimeList = char.LevelTimeList or {}
	char.TotalTimeList = char.TotalTimeList or {}
	char.DateStampList = char.DateStampList or {}
	char.UnixTimeList = char.UnixTimeList or {}
	self.db.global.maxxp = self.db.global.maxxp or {}
	
	-- character specific
	char.timeAFK = char.timeAFK or 0
	char.totalAFK = char.totalAFK or 0
	char.death = char.death or 0
	
	-- level 1 init
	if player.level == 1 then
		char.DateStampList[1] = char.DateStampList[1] or date("%Y.%m.%d %H:%M:%S")
		char.UnixTimeList[1] = char.UnixTimeList[1] or time()
	end
	
	-- "backwards compatibility" with v0.95 data; prefer capitalization for SavedVars
	if char.levelTimeList then
		for k, v in pairs(char.levelTimeList) do
			char.LevelTimeList[k] = v
		end
		char.levelTimeList = nil
		
		for k, v in pairs(char.totalTimeList) do
			char.TotalTimeList[k] = v
		end
		char.totalTimeList = nil
		
		for k, v in pairs(char.dateStampList) do
			char.DateStampList[k] = v
		end
		char.dateStampList = nil
		
		for k, v in pairs(char.unixTimeList) do
			char.UnixTimeList[k] = v
		end
		char.unixTimeList = nil
		
		-- can just build it straight from LevelTimeList
		char.levelSummary = nil
		char.experienceList = nil
	end
	
	-- renamed/removed in v1.05
	if char.stats then
		char.stats = nil
	end
end

local f = CreateFrame("Frame")
local delay = 0

-- wait 4 sec first for any other AddOns that want to request /played too
function f:WaitPlayed(elapsed)
	delay = delay + elapsed
	if delay > 4 then
		if S.totalTPM == 0 then
			RequestTimePlayed()
		end
		self:SetScript("OnUpdate", nil)
	end
end

function RSD:OnEnable()
	for k, v in pairs(S.events) do
		if type(v) == "table" then
			for _, event in ipairs(v) do
				self:RegisterEvent(event, k)
			end
		else
			self:RegisterEvent(v)
		end
	end
	
	-- filter /played message
	S.filterPlayed = profile.FilterPlayed and true or false
	
	-- support [Class Colors] by Phanx
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback("WipeCache", self)
	end
	
	--------------
	--- Timers ---
	--------------
	
	-- standalone OnUpdate is more stable than AceTimer on client startup imho
	f:SetScript("OnUpdate", f.WaitPlayed)
	
	-- this kinda defeats the purpose of registering/unregistering events according to options <.<
	self:ScheduleRepeatingTimer(function()
		-- the returns of UnitLevel() aren't yet updated on UNIT_LEVEL
		if S.UNIT_LEVEL() then
			self:UNIT_LEVEL("UNIT_LEVEL")
		end
		if S.GUILD_ROSTER_UPDATE() then
			GuildRoster() -- fires GUILD_ROSTER_UPDATE
		end
		-- FRIENDLIST_UPDATE doesn't fire on actual friend levelups
		-- the returns of GetFriendInfo() only get updated when FRIENDLIST_UPDATE fires
		if profile.ShowFriend then
			ShowFriends() -- fires FRIENDLIST_UPDATE
		end
		-- BN_FRIEND_INFO_CHANGED doesn't fire on login; but it does on actual levelups; just to be sure
		if profile.ShowRealID then
			self:BN_FRIEND_INFO_CHANGED("BN_FRIEND_INFO_CHANGED")
		end
	end, 11)
end

function RSD:OnDisable()
	self:UnregisterAllEvents() 
	self:CancelAllTimers()
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:UnregisterCallback("WipeCache", self)
	end
end

local setupRandom = {
	"Ding",
	"Guild",
	"Gratz",
}

function RSD:RefreshDB()
	-- table shortcuts
	profile = self.db.profile
	char = self.db.char
	realm = self.db.realm
		
	-- update table references in other files
	for i = 1, 3 do
		self["RefreshDB"..i](self)
	end
	
	-- init random messages
	for _, v in ipairs(setupRandom) do
		self["SetupRandom"..v](self, profile["NumRandom"..v])
	end
	
	self:RefreshEvents() -- register/unregister level events according to options
	
	-- stopwatch (only on changing profiles; it's not yet initialized at start)
	-- but don't hide stopwatch, we'd want a library for that lol
	local v = S.curTPM + time() - S.lastPlayed
	if profile.Stopwatch and S.curTPM > 0 and S.CanUseStopwatch(v) then
		S.StopwatchStart(v)
	end
	
	-- graphs
	if ReadySetDing_LevelGraph then
		ReadySetDing_LevelGraph[profile.LevelGraph and "Show" or "Hide"](ReadySetDing_LevelGraph)
	end
	
	-- clear random message preview
	wipe(S.activePreview)
end

	----------------------
	--- Slash Commands ---
	----------------------

local enable = {
	["1"] = true,
	on = true,
	enable = true,
	load = true,
}

local disable = {
	["0"] = true,
	off = true,
	disable = true,
	unload = true,
}

function RSD:SlashCommand(input)
	if enable[input] then
		self:Enable()
		self:Print("|cffADFF2F"..VIDEO_OPTIONS_ENABLED.."|r")
	elseif disable[input] then
		self:Disable()
		self:Print("|cffFF2424"..VIDEO_OPTIONS_DISABLED.."|r")
	else
		ACD:Open("ReadySetDing_Parent")
	end
end

	----------------
	--- Level Up ---
	----------------

local playerDinged

function RSD:PLAYER_LEVEL_UP(event, ...)
	local level = ...
	player.level = level -- on another note, UnitLevel is not yet updated
	playerDinged = true
	S.filterPlayed = profile.FilterPlayed and true or false
	RequestTimePlayed() -- TIME_PLAYED_MSG
end

function RSD:TIME_PLAYED_MSG(event, ...)
	S.totalTPM, S.curTPM = ...
	S.lastPlayed = time()
	
	if playerDinged then
		playerDinged = false
		
		local levelTime
		local prevTime = char.TotalTimeList[player.level-1]
		if prevTime then
			-- TotalTime @ Ding - TotalTime @ previous Ding
			levelTime = S.totalTPM - prevTime
		else
			-- undinged LevelTime + (dinged TotalTime - undinged TotalTime)
			levelTime = curTPM2 + (S.totalTPM - totalTPM2)
		end
		
		-- update player data
		local level = player.level
		char.LevelTimeList[level] = levelTime
		char.TotalTimeList[level] = S.totalTPM
		char.UnixTimeList[level] = time()
		char.DateStampList[level] = date("%Y.%m.%d %H:%M:%S")
		self.db.global.maxxp[level-1] = player.maxxp
		
		-- play custom sound if the user supplied one
		if profile.Sound then
			self:ScheduleTimer(function()
				local sound
				if profile.LibSharedMediaSound then
					sound = LSM:HashTable(LSM.MediaType.SOUND)[profile.SoundWidget]
				else
					sound = (profile.CustomSound == S.sounds[2]) and S.sounds[random(3, #S.sounds)] or profile.CustomSound
				end
				PlaySoundFile(sound, "Master")
			end, profile.SoundDelay)
		end
		
		-- Language
		local lang
		if profile.Language == 2 then
			lang = GetLanguageByIndex(random(GetNumLanguages()))
		elseif profile.Language > 2 then
			lang = GetLanguageByIndex(profile.Language-2)
		end
		
		local text = self:ChatDing(levelTime)
		
		-- Party/Raid Announce
		if profile.ChatParty then
			local chan = GetNumRaidMembers() > 0 and "RAID" or GetNumPartyMembers() > 0 and "PARTY" or "SAY"
			if select(2, IsInInstance()) == "pvp" then
				chan = "BATTLEGROUND"
			end
			self:ScheduleTimer(function()
				-- send in two messages
				if strlen(text) > 255 then
					SendChatMessage(strsub(text, 1, 255), chan, lang)
					SendChatMessage(strsub(text, 256), chan, lang)
				else
					SendChatMessage(text, chan, lang)
				end
			end, profile.DingDelay)
		end
		
		-- Guild Announce
		if profile.ChatGuild and IsInGuild() then
			self:ScheduleTimer(function()
				SendChatMessage(text, "GUILD", lang)
			end, profile.DingDelay)
		end
		
		-- Zone Announce
		if profile.ChatZone then
			local channel = {GetChannelList()}
			for i = 1, 10 do
				-- the General channel could possibly have any channel number assigned 
				if channel[i*2] == GENERAL then
					self:ScheduleTimer(function()
						SendChatMessage(text, "CHANNEL", nil, i*2-1)
					end, profile.DingDelay)
					break
				end
			end
		end
		
		-- Real ID Broadcast
		if profile.ChatBroadcast then
			self:ScheduleTimer(function()
				-- save current message
				local origMsg = select(3, BNGetInfo())
				BNSetCustomMessage(strsub(text, 1, 127))
				BNSetCustomMessage(origMsg)
			end, profile.DingDelay)
		end
		
		-- Screenshot
		if profile.Screenshot then
			if profile.RaidWarning then
				RaidNotice_AddMessage(RaidWarningFrame, text, {r=1, g=1, b=1})
			end
			
			local timeHide = profile.ScreenshotDelay - 1
			 -- change any negative value to zero (e.g. 0.5 - 1)
			if timeHide < 0 then timeHide = 0 end
			
			-- "hide" UI 1 sec before taking screenshot
			-- SetAlpha can be called while in combat contrary to Show/Hide
			if profile.HideUI then
				self:ScheduleTimer(function()
					UIParent:SetAlpha(0)
				end, timeHide)
			end
			
			-- take screenshot
			self:ScheduleTimer(function()
				Screenshot()
			end, profile.ScreenshotDelay)
			
			-- "show" UI again
			local origAlpha = UIParent:GetAlpha()
			if profile.HideUI then
				self:ScheduleTimer(function()
					UIParent:SetAlpha(origAlpha)
				end, profile.ScreenshotDelay + 1)
			end
		end
		
		if profile.Stopwatch and S.CanUseStopwatch(S.curTPM) then
			-- temporarily pause
			Stopwatch_Pause()
			self:ScheduleTimer(function()
				-- play again
				S.StopwatchStart(S.curTPM + time() - S.lastPlayed)
			end, 60)
		end
		
		-- reset current level specific data
		char.timeAFK, char.death = 0, 0
		
	--------------
	--- Graphs ---
	--------------
		
		local levelg = ReadySetDing_LevelGraph
		local totalg = ReadySetDing_TotalGraph
		
		if levelg and profile.LevelGraph then
			levelg:ResetData()
			totalg:ResetData()
			self:UpdateGraph(levelg, totalg)
		end
		
	else
		-- Blizzard_TimeManager is not yet loaded, but we're being delayed anyway
		if profile.Stopwatch and S.CanUseStopwatch(S.curTPM) then
			S.StopwatchStart(S.curTPM)
		end
	end
	
	-- update config if currently shown
	if ACD.OpenFrames.ReadySetDing_Parent then
		ACR:NotifyChange("ReadySetDing_Parent")
	end
	
	-- update for next levelup
	totalTPM2, curTPM2 = S.totalTPM, S.curTPM
	
	-- UnitXPMax is not yet readily updated
	self:ScheduleTimer(function()
		player.maxxp = UnitXPMax("player")
	end, 2)
end

function RSD:ChatDing(levelTime)
	local args = args
	args.level = player.level
	args["level-"] = player.level - 1
	args["level#"] = player.maxlevel
	args["level%"] = player.maxlevel - player.level
	args.time = self:Time(levelTime)
	args.total = self:Time(S.totalTPM)
	args.date = date("%Y.%m.%d %H:%M:%S")
	args.date2 = date("%m/%d/%y %H:%M:%S")
	args.afk = self:Time(char.timeAFK)
	args["afk+"] = self:Time(char.totalAFK)
	args.death = char.death
	args["death+"] = self:AchievStat("death")
	args.quest = self:AchievStat("quest")
	args.rt = "{rt"..random(8).."}"
	-- hidden args
	args.name = player.name
	args.class = player.class
	args.race = player.race
	args.faction = player.faction
	args.realm = player.realm
	args.zone = GetRealZoneText() or GetSubZoneText() or ZONE
	args.guild = GetGuildInfo("player") or ""
	args.ilv = floor(GetAverageItemLevel())
	
	-- fallback to default in case of blank (nil) random message
	local msg = profile.DingRandom and profile.DingMsg[random(profile.NumRandomDing)] or profile.DingMsg[1]
	return self:ReplaceArgs(msg, args)
end

	-------------
	--- Group ---
	-------------

local group = {}

function RSD:UNIT_LEVEL()
	local numParty = profile.ShowParty and GetNumPartyMembers() or 0
	local numRaid = profile.ShowRaid and GetNumRaidMembers() or 0

	local numGroup = (numRaid > 0) and numRaid or (numParty > 0) and numParty or 0
	local groupType = (numRaid > 0) and "raid" or (numParty > 0) and "party"
	local chan = (numRaid > 0) and "|cffFF7F00"..RAID.."|r" or (numParty > 0) and "|cffA8A8FF"..PARTY.."|r"
	
	for i = 1, numGroup do
		local guid = UnitGUID(groupType..i)
		local name, realm = UnitName(groupType..i)
		local level = UnitLevel(groupType..i)
		-- level can return as 0 when party members are not yet in the instance/zone
		if guid and level and level > 0 then
			if group[guid] and group[guid] > 0 and level > group[guid] and name ~= player.name then
				local class = select(2, UnitClass(groupType..i))
				local race = select(2, UnitRace(groupType..i))
				local sex = UnitSex(groupType..i)
				
				local raceIcon = S.GetRaceIcon(strupper(race).."_"..S.sexremap[sex], 1, 1)
				local classIcon = S.GetClassIcon(class, 1, 1)
				args.icon = raceIcon..classIcon
				
				args.chan = chan
				
				local classColor = S.classCache[select(2, UnitClass(groupType..i))]
				args.name = format("|cff%s|Hplayer:%s|h%s|h|r", classColor, name..(realm and "-"..realm or ""), name)
				
				args.level = "|cffADFF2F"..level.."|r"
				
				self:Output(profile.ShowMsg, args)
			end
			group[guid] = level
		end
	end
end

	-------------
	--- Guild ---
	-------------

local showedDiffs, showedHeader

-- now this is an even bigger mess than before ._.
-- completely drycoded/untested
function RSD:GUILD_ROSTER_UPDATE(event)
	if IsInGuild() and time() > (cd.guild or 0) then
		cd.guild = time() + 10
		local chan = "|cff40FF40"..GUILD.."|r"
		
		for i = 1, GetNumGuildMembers() do
			local name, rank, _, level, class, zone, _, _, _, _, englishClass = GetGuildRosterInfo(i)
			
			-- sanity checks
			if name and realm[name] and level > realm[name][1] and name ~= player.name then
				if showedDiffs then
					local realtime = 0
					if level-1 ~= 1 and realm[name][level-1] then
						realtime = time() - realm[name][level-1][1]
					end
					
					-- args for ShowGuild specifically
					args.icon = S.GetClassIcon(englishClass, 1, 1)
					args.chan = chan
					args.name = format("|cff%s|Hplayer:%s|h%s|h|r", S.classCache[englishClass], name, name)
					args.level = "|cffADFF2F"..level.."|r"
					-- hidden args
					args.class = "|cff"..S.classCache[englishClass]..class.."|r"
					args.rank = rank
					args.zone = zone
					args.realtime = realtime
					
					if profile.ShowGuild then
						self:Output(profile.ShowMsg, args)
					end
					
					if profile.GuildMemberDing then
						-- filters
						local afk = profile.GuildAFK and not UnitIsAFK("player") or not profile.GuildAFK
						local achiev = profile.FilterLevelAchiev and not S.Levels[level] or not profile.FilterLevelAchiev
						
						if afk and achiev then
							SendChatMessage(self:ChatGuild(name, level, class, rank, zone, realtime), "GUILD")
						end
					end
					
					-- save time & date
					realm[name][level] = {time(), date("%Y.%m.%d %H:%M:%S")}
				else
					-- level changed while user was offline
					if profile.GuildMemberDiff then
						if not showedHeader and char.LastCheck then
							self:Print(format("|cffF6ADC6[%s]|r - |cffADFF2F[%s]|r", char.LastCheck, date("%Y.%m.%d %H:%M:%S")))
							showedHeader = true; char.LastCheck = nil
						end
						print(format("|cff%s|Hplayer:%s|h[%s]|h|r %s |cffF6ADC6%s|r - |cffADFF2F%s|r (+|cff71D5FF%s|r)", S.classCache[englishClass], name, name, LEVEL, realm[name][1], level, level-realm[name][1]))
					end
					-- don't got time & date
					realm[name][level] = false
				end
			end
			realm[name] = realm[name] or {}
			realm[name][1] = level
		end
		showedDiffs = true -- can't test this. hope it works and a bunny doesn't die
	end
end

function RSD:ChatGuild(name, level, class, rank, zone, realtime)
	local args = args
	args.level = level
	args["level-"] = level - 1
	args["level#"] = S.maxlevel
	args["level%"] = S.maxlevel - level
	args.name = name
	args.class = class
	args.rank = rank
	args.zone = zone or ""
	args.realtime = self:Time(realtime)
	args.rt = "{rt"..random(8).."}"
	
	local msg = profile.GuildRandom and profile.GuildMsg[random(profile.NumRandomGuild)] or profile.GuildMsg[1]
	return self:ReplaceArgs(msg, args)
end

	---------------
	--- Friends ---
	---------------

local friend = {}

function RSD:FRIENDLIST_UPDATE(event)
	if time() > (cd.friend or 0) then
		cd.friend = time() + 1
		local chan = FRIENDS_WOW_NAME_COLOR_CODE..FRIEND.."|r"
		
		for i = 1, select(2, GetNumFriends()) do
			local name, level, class = GetFriendInfo(i)
			if name then -- name is sometimes nil
				if friend[name] and level > friend[name] then
					args.icon = S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1)
					args.chan = chan
					args.name = format("|cff%s|Hplayer:%s|h%s|h|r", S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], name, name)
					args.level = "|cffADFF2F"..level.."|r"
					self:Output(profile.ShowMsg, args)
				end
				friend[name] = level
			end
		end
	end
end

	---------------
	--- Real ID ---
	---------------

local realid = {}

function RSD:BN_FRIEND_INFO_CHANGED(event)
	if time() > (cd.realid or 0) then
		cd.realid = time() + 1
		local chan = FRIENDS_BNET_NAME_COLOR_CODE..BATTLENET_FRIEND.."|r"
		
		for i = 1, select(2, BNGetNumFriends()) do
			local presenceId, firstname, surname, someToonName, toonID = BNGetFriendInfo(i)
			local _, toonName, client, realm, _, _, race, class, _, _, level = BNGetToonInfo(presenceId)
			
			-- avoid misrecognizing characters that share the same name, but are from different servers
			realid[realm] = realid[realm] or {}
			local bnet = realid[realm]
			
			if client == BNET_CLIENT_WOW then
				level = tonumber(level) -- why is level a string type
				if toonName and bnet[toonName] and bnet[toonName] > 0 and level and level > bnet[toonName] then
					args.icon = S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1)
					
					args.chan = chan
					
					-- "|Kg49|k00000000|k": f BNplayer; g firstname; s surname
					local fixedLink = firstname:gsub("g", "f")
					local fullName = firstname.." "..surname
					-- the "BNplayer" hyperlink might maybe taint whatever it calls on right-click
					args.name = format("|cff%s|HBNplayer:%s:%s|h%s|r |cff%s%s|h|r", "82C5FF", fixedLink, presenceId, fullName, S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], toonName)
					
					args.level = "|cffADFF2F"..level.."|r"
					
					self:Output(profile.ShowMsg, args)
				end
				bnet[toonName] = level
			end
		end
	end
end
