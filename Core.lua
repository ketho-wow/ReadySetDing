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

local profile, member, char

local time = time
S.lastPlayed = time()
S.totalTPM, S.curTPM = 0, 0
local curTPM2, totalTPM2

local pairs, ipairs = pairs, ipairs
local format, gsub = format, gsub

local IsInGuild = IsInGuild

	---------------------------
	--- Ace3 Initialization ---
	---------------------------

local appKey = {
	"ReadySetDing_Main",
	"ReadySetDing_Advanced",
}

local appValue = {
	ReadySetDing_Main = options.args.main,
	ReadySetDing_Advanced = options.args.advanced,
	ReadySetDing_Data = options.args.data,
}

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
	
	-- setup profiles now, self reminder: requires db to be already defined
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local profiles = options.args.profiles
	profiles.order = 6
	profiles.name = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:-2:-1"..S.crop.."|t "..profiles.name
	tinsert(appKey, "ReadySetDing_Profiles")
	appValue.ReadySetDing_Profiles = profiles
	
	for _, v in ipairs(appKey) do
		ACR:RegisterOptionsTable(v, appValue[v])
		ACD:AddToBlizOptions(v, appValue[v].name, NAME)
	end
	
	----------------------
	--- Slash Commands ---
	----------------------
	
	for _, v in ipairs({"rsd", "readyset", "readysetding"}) do
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
	
	self.db.global.member = setmetatable(self.db.global.member or {}, {__index = function(t, k)
			local v = {}
			rawset(t, k, v)
			return v
		end
	})
	member = self.db.global.member 
	
	-- character specific
	char.timeAFK = char.timeAFK or 0
	char.totalAFK = char.totalAFK or 0
	char.death = char.death or 0
	
	-- level 1 init
	if player.level == 1 then
		char.DateStampList[1] = char.DateStampList[1] or date("%Y.%m.%d %H:%M:%S")
		char.UnixTimeList[1] = char.UnixTimeList[1] or time()
	end
	
	-- v1.16: remove pre-connected realms guild member data
	wipe(self.db.realm)
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
	S.filterPlayed = true
	
	-- support [Class Colors] by Phanx
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback("WipeCache", self)
	end
	
	--------------
	--- Timers ---
	--------------
	
	-- standalone OnUpdate is more stable than AceTimer on client startup imho
	f:SetScript("OnUpdate", f.WaitPlayed)
	
	self:ScheduleRepeatingTimer(function()
		-- the returns of UnitLevel() aren't yet updated on UNIT_LEVEL
		if profile.ShowGroup then
			self:UNIT_LEVEL()
		end
		if profile.ShowGuild and IsInGuild() then
			GuildRoster() -- fires GUILD_ROSTER_UPDATE
		end
		-- FRIENDLIST_UPDATE doesn't fire on actual friend levelups
		-- the returns of GetFriendInfo() only get updated when FRIENDLIST_UPDATE fires
		if profile.ShowFriend then
			ShowFriends() -- fires FRIENDLIST_UPDATE
			-- BN_FRIEND_INFO_CHANGED doesn't fire on login; but it does on actual levelups; just to be sure
			self:BN_FRIEND_INFO_CHANGED()
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

function RSD:RefreshDB()
	-- table shortcuts
	profile = self.db.profile
	char = self.db.char
	
	-- update table references in other files
	for i = 1, 2 do
		self["RefreshDB"..i](self)
	end
	
	-- init random messages
	self["SetupRandomDing"](self, profile["NumRandomDing"])
	
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
	S.filterPlayed = true
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
		
		-- Language
		local _, langId
		if profile.Language == 2 then
			_, langId = GetLanguageByIndex(random(GetNumLanguages()))
		elseif profile.Language > 2 then
			_, langId = GetLanguageByIndex(profile.Language-2)
		end
		
		local text = self:ChatDing(levelTime)
		
		-- Party/Raid Announce
		if profile.ChatGroup then
			local isBattleground = select(2, IsInInstance()) == "pvp"
			local chan = (IsPartyLFG() or isBattleground) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "SAY"
			-- send in two messages
			if strlen(text) > 255 then
				SendChatMessage(strsub(text, 1, 255), chan, langId)
				SendChatMessage(strsub(text, 256), chan, langId)
			else
				SendChatMessage(text, chan, langId)
			end
		end
		
		-- Guild Announce
		if profile.ChatGuild and IsInGuild() then
			SendChatMessage(text, "GUILD", langId)
		end
		
		-- Screenshot
		if profile.Screenshot then
			self:ScheduleTimer(function()
				Screenshot()
			end, 1)
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
	args.zone = GetRealZoneText() or GetSubZoneText() or ZONE
	
	-- fallback to default in case of blank (nil) random message
	local msg = profile.DingRandom and profile.DingMsg[random(profile.NumRandomDing)] or profile.DingMsg[1]
	return self:ReplaceArgs(msg, args)
end

	-------------
	--- Group ---
	-------------

local group = {}

function RSD:UNIT_LEVEL()
	if not profile.ShowGroup then return end
	
	local isRaid = IsInRaid()
	local isParty = IsInGroup()
	
	local numGroup = isRaid and GetNumGroupMembers() or isParty and GetNumSubgroupMembers() or 0
	local groupType = isRaid and "raid" or isParty and "party"
	local chan = isRaid and "|cffFF7F00"..RAID.."|r" or isParty and "|cffA8A8FF"..PARTY.."|r"
	
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
				
				self:ShowLevelup(profile.ShowMsg, args)
			end
			group[guid] = level
		end
	end
end

	-------------
	--- Guild ---
	-------------

-- before secondGRU show anything as guild diff
-- after secondGRU show realtime (around +20 sec earliest)
local firstGRU, secondGRU, showedHeader

-- now this is an even bigger mess than before ._.
function RSD:GUILD_ROSTER_UPDATE(event)
	if not profile.ShowGuild then return end
	
	if not (time() > (cd.guild or 0)) then return end
	cd.guild = time() + 10
	
	local chan = "|cff40FF40"..GUILD.."|r"
	
	for i = 1, GetNumGuildMembers() do
		local fullName, rank, _, level, class, zone, _, _, _, _, englishClass = GetGuildRosterInfo(i)
		local charName, charRealm = strmatch(fullName or "", "(.+)%-(.+)") -- is this different on non-connected realms?..
		
		if charName and charRealm then -- sanity checks
			local p = member[charRealm][charName]
			
			-- sanity checks everywhere~
			if p and #p > 0 and level > p[1] and charName ~= player.name then
				if secondGRU then
					local realtime = 0
					if level-1 ~= 1 and p[level-1] then
						realtime = time() - p[level-1][1]
					end
					
					-- args for ShowGuild specifically
					args.icon = S.GetClassIcon(englishClass, 1, 1)
					args.chan = chan
					args.name = format("|cff%s|Hplayer:%s|h%s|h|r", S.classCache[englishClass], fullName, charName)
					args.level = "|cffADFF2F"..level.."|r"
					args.zone = zone
					args.realtime = realtime
					
					if profile.ShowGuild then
						self:ShowLevelup(profile.ShowMsg, args)
					end
					
					-- save time & date
					p[level] = {time(), date("%Y.%m.%d %H:%M:%S")}
				else
					-- level changed while user was offline
					if profile.GuildMemberChangelog then
						if not showedHeader and char.LastCheck then
							self:Print(format("|cffF6ADC6[%s]|r - |cffADFF2F[%s]|r", char.LastCheck, date("%Y.%m.%d %H:%M:%S")))
							showedHeader = true; char.LastCheck = nil
						end
						print(format("|cff%s|Hplayer:%s|h[%s]|h|r %s |cffF6ADC6%s|r - |cffADFF2F%s|r (+|cff71D5FF%s|r)",
							S.classCache[englishClass], fullName, charName, LEVEL, p[1], level, level-p[1]))
					end
					-- don't got time & date
					p[level] = false
				end
			end
			
			-- dont save already maxed characters
			if level ~= S.maxlevel or (p and #p > 0) then
				member[charRealm][charName] = member[charRealm][charName] or {}
				member[charRealm][charName][1] = level
			end
		end
	end
	
	-- even more awful delaying
	-- a lot of bunnies were sacrificed for this
	if firstGRU then secondGRU = true end
	firstGRU = true
end

	---------------
	--- Friends ---
	---------------

local friend = {}

function RSD:FRIENDLIST_UPDATE(event)
	if not profile.ShowFriend then return end
	
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
					self:ShowLevelup(profile.ShowMsg, args)
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

function RSD:BN_FRIEND_INFO_CHANGED()
	if not profile.ShowFriend then return end
	
	if time() > (cd.realid or 0) then
		cd.realid = time() + 1
		local chan = FRIENDS_BNET_NAME_COLOR_CODE..BATTLENET_FRIEND.."|r"
		
		for i = 1, select(2, BNGetNumFriends()) do
			local presenceID, presenceName = BNGetFriendInfo(i)
			
			-- ToDo: add support for multiple online toons / BNGetFriendToonInfo
			local _, toonName, client, realm, _, _, race, class, _, _, level = BNGetGameAccountInfo(presenceID)
			if not realm then return end -- sanity check (reported by featalene-Curse)
			
			-- avoid misrecognizing characters that share the same name, but are from different servers
			realid[realm] = realid[realm] or {}
			local bnet = realid[realm]
			
			if client == BNET_CLIENT_WOW then
				level = tonumber(level) -- why is level a string type
				if toonName and bnet[toonName] and bnet[toonName] > 0 and level and level > bnet[toonName] then
					args.icon = S.GetClassIcon(S.revLOCALIZED_CLASS_NAMES[class], 1, 1)
					
					args.chan = chan
					
					-- "|Kg49|k00000000|k": f BNplayer; g firstname; s surname; default f in 5.0.4
					-- the "BNplayer" hyperlink might maybe taint whatever it calls on right-click
					args.name = format("|cff%s|HBNplayer:%s:%s|h%s|r |cff%s%s|h|r", "82C5FF", presenceName, presenceID, presenceName, S.classCache[S.revLOCALIZED_CLASS_NAMES[class]], toonName)
					
					args.level = "|cffADFF2F"..level.."|r"
					
					self:ShowLevelup(profile.ShowMsg, args)
				end
				bnet[toonName] = level
			end
		end
	end
end
	----------------
	--- AFK Time ---
	----------------

local afk

local function LeaveAFK()
	char.timeAFK = char.timeAFK + (time() - afk)
	char.totalAFK = char.totalAFK + (time() - afk)
end

local MARKED_AFK_MESSAGE = gsub(MARKED_AFK_MESSAGE, "%%s", ".+")

function RSD:CHAT_MSG_SYSTEM(event, msg)
	-- entering afk
	if msg == MARKED_AFK or strfind(msg, MARKED_AFK_MESSAGE) then
		afk = time()
	-- leaving afk
	elseif msg == CLEARED_AFK and afk then
		LeaveAFK()
	end
end

function RSD:PLAYER_LEAVING_WORLD(event)
	-- logging out while afk
	if UnitIsAFK("player") and afk then
		LeaveAFK()
	end
	
	-- time/date at logout for showing levelDiffs
	char.LastCheck = date("%Y.%m.%d %H:%M:%S")
end

	--------------
	--- Deaths ---
	--------------

function RSD:PLAYER_DEAD(event)
	char.death = char.death + 1
end
