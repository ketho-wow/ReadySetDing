local NAME, S = ...
local RSD = ReadySetDing

local player = S.player
local legend = S.legend
local cd = S.cd
local args = S.args

local profile, realm, char

function RSD:RefreshDB3()
	profile = self.db.profile
	realm = self.db.realm
	char = self.db.char
end

local time = time
local random = random

local AchievementBlacklist = {
-- General
	[522] = true, -- [Somebody Likes Me]
	[545] = true, -- [Shave and a Haircut]
	[546] = true, -- [Safe Deposit]
	[557] = true, -- [Superior]
	[558] = true, -- [Greedy]
	[556] = true, -- [Epic]
	[621] = true, -- [Represent]
	[964] = true, -- [Going Down?]
	[1017] = true, -- [Can I Keep Him?]
	[2716] = true, -- [Dual Talent Specialization]
-- Profession
	[116] = true, -- [Professional Journeyman]
	[731] = true, -- [Professional Expert]
	[732] = true, -- [Professional Artisan]
	[733] = true, -- [Professional Master]
	[734] = true, -- [Professional Grand Master]
-- Fishing
	[153] = true, -- [The Old Gnome and the Sea]
	[1556] = true, -- [25 Fish]
	[1557] = true, -- [50 Fish]
	[1558] = true, -- [100 Fish]
-- Riding
	[891] = true, -- [Giddy Up!]
	[889] = true, -- [Fast and Furious]
-- PvP
	[223] = true, -- [The Sickly Gazelle]
	[227] = true, -- [Damage Control]
	[229] = true, -- [The Grim Reaper]
	[245] = true, -- [That Takes Class]
	[246] = true, -- [Know Thy Enemy] (A)
	[247] = true, -- [Make Love, Not Warcraft]
	[700] = true, -- [Freedom of the Horde]
	[701] = true, -- [Freedom of the Alliance]
	[1005] = true, -- [Know Thy Enemy] (H)
	[1157] = true, -- [Duel-icious]

	[238] = true, -- [An Honorable Kill]
	[513] = true, -- [100 Honorable Kills]
	[515] = true, -- [500 Honorable Kills]
	[516] = true, -- [1000 Honorable Kills]

	[154] = true, -- [Arathi Basin Victory]
	[166] = true, -- [Warsong Gulch Victory]
	[208] = true, -- [Eye of the Storm Victory]
	[218] = true, -- [Alterac Valley Victory]
	[1308] = true, -- [Strand of the Ancients Victory]
	[1717] = true, -- [Wintergrasp Victory]
	[3776] = true, -- [Isle of Conquest Victory]
	[5245] = true, -- [Battle for Gilneas Victory]
	[5412] = true, -- [Tol Barad Victory]
-- Quests
	[503] = true, -- [50 Quests Completed]
	[504] = true, -- [100 Quests Completed]
	[973] = true, -- [5 Daily Quests Complete]
	[974] = true, -- [50 Daily Quests Complete]
	[4956] = true, -- [5 Dungeon Quests Completed]
	[4957] = true, -- [20 Dungeon Quests Completed]

	[561] = true, -- [D.E.H.T.A's Little P.I.T.A.]
	[547] = true, -- [Veteran of the Wrathgate]
	[938] = true, -- [The Snows of Northrend]
	[939] = true, -- [Hills Like White Elekk]
	[940] = true, -- [The Green Hills of Stranglethorn]
	[1576] = true, -- [Of Blood and Anguish]
	[4959] = true, -- [Beware of the 'Unbeatable?' Pterodactyl]
	[4960] = true, -- [Round Three. Fight!]
	[4961] = true, -- [In a Thousand Years Even You Might be Worth Something]
	[5318] = true, -- [20,000 Leagues Under the Sea]
	[5451] = true, -- [Consumed by Nightmare]

	[4896] = true, -- [Arathi Highlands Quests]
	[4925] = true, -- [Ashenvale Quests] (A)
	[4976] = true, -- [Ashenvale Quests] (H)
	[4927] = true, -- [Azshara Quests] (H only)
	[4900] = true, -- [Badlands Quests]
	[4909] = true, -- [Blasted Lands Quests]
	[4926] = true, -- [Bloodmyst Isle Quests] (A only)
	[4901] = true, -- [Burning Steppes Quests]
	[4905] = true, -- [Cape of Stranglethorn Quests]
	[4928] = true, -- [Darkshore Quests]
	[4930] = true, -- [Desolace Quests]
	[4907] = true, -- [Duskwood Quests] (A only)
	[4929] = true, -- [Dustwallow Marsh Quests] (H only)
	[4892] = true, -- [Eastern Plaguelands Quests]
	[4931] = true, -- [Felwood Quests]
	[4932] = true, -- [Feralas Quests] (A)
	[4979] = true, -- [Feralas Quests] (H)
	[4908] = true, -- [Ghostlands Quests] (H only)
	[4895] = true, -- [Hillsbrad Foothills Quests] (H only)
	[4897] = true, -- [Hinterlands Quests]
	[4899] = true, -- [Loch Modan Quests] (A only)
	[4933] = true, -- [Northern Barrens Quests] (H only)
	[4906] = true, -- [Northern Stranglethorn Quests]
	[4902] = true, -- [Redridge Mountains Quests] (A only)
	[4910] = true, -- [Searing Gorge Quests]
	[4934] = true, -- [Silithus Quests]
	[4984] = true, -- [Silverpine Forest Quests] (H only)
	[4937] = true, -- [Southern Barrens Quests] (A)
	[4981] = true, -- [Southern Barrens Quests] (H)
	[4936] = true, -- [Stonetalon Mountains Quests] (A)
	[4980] = true, -- [Stonetalon Mountains Quests] (H)
	[4904] = true, -- [Swamp of Sorrows Quests]
	[4935] = true, -- [Tanaris Quests]
	[4938] = true, -- [Thousand Needles Quests]
	[4939] = true, -- [Un'Goro Crater Quests]
	[4903] = true, -- [Westfall Quests] (A only)
	[4898] = true, -- [Wetlands Quests] (A only)
	[4940] = true, -- [Winterspring Quests]
-- Dungeons
	[632] = true, -- [Blackfathom Deeps]
	[642] = true, -- [Blackrock Depths]
	[628] = true, -- [Deadmines]
	[634] = true, -- [Gnomeregan]
	[644] = true, -- [King of Dire Maul]
	[643] = true, -- [Lower Blackrock Spire]
	[640] = true, -- [Maraudon]
	[629] = true, -- [Ragefire Chasm]
	[636] = true, -- [Razorfen Downs]
	[635] = true, -- [Razorfen Kraul]
	[637] = true, -- [Scarlet Monastery]
	[645] = true, -- [Scholomance]
	[631] = true, -- [Shadowfang Keep]
	[633] = true, -- [Stormwind Stockade]
	[646] = true, -- [Stratholme]
	[641] = true, -- [Sunken Temple]
	[638] = true, -- [Uldaman]
	[1307] = true, -- [Upper Blackrock Spire]
	[630] = true, -- [Wailing Caverns]
	[639] = true, -- [Zul'Farrak]

	[666] = true, -- [Auchenai Crypts]
	[647] = true, -- [Hellfire Ramparts]
	[661] = true, -- [Magister's Terrace]
	[651] = true, -- [Mana-Tombs]
	[655] = true, -- [Opening of the Dark Portal]
	[653] = true, -- [Sethekk Halls]
	[654] = true, -- [Shadow Labyrinth]
	[660] = true, -- [The Arcatraz]
	[648] = true, -- [The Blood Furnace]
	[659] = true, -- [The Botanica]
	[652] = true, -- [The Escape From Durnholde]
	[658] = true, -- [The Mechanar]
	[657] = true, -- [The Shattered Halls]
	[649] = true, -- [The Slave Pens]
	[656] = true, -- [The Steamvault]
	[650] = true, -- [Underbog]

	[481] = true, -- [Ahn'kahet: The Old Kingdom]
	[480] = true, -- [Azjol-Nerub]
	[482] = true, -- [Drak'Tharon Keep]
	[484] = true, -- [Gundrak]
	[486] = true, -- [Halls of Lightning]
	[485] = true, -- [Halls of Stone]
	[479] = true, -- [The Culling of Stratholme]
	[4516] = true, -- [The Forge of Souls]
	[4518] = true, -- [The Halls of Reflection]
	[478] = true, -- [The Nexus]
	[487] = true, -- [The Oculus]
	[4517] = true, -- [The Pit of Saron]
	[483] = true, -- [The Violet Hold]
	[4296] = true, -- [Trial of the Champion] (A)
	[3778] = true, -- [Trial of the Champion] (H)
	[477] = true, -- [Utgarde Keep]
	[488] = true, -- [Utgarde Pinnacle]

	[4833] = true, -- [Blackrock Caverns]
	[4840] = true, -- [Grim Batol]
	[4841] = true, -- [Halls of Origination]
	[4848] = true, -- [Lost City of the Tol'vir]
	[4846] = true, -- [The Stonecore]
	[4847] = true, -- [The Vortex Pinnacle]
	[4839] = true, -- [Throne of the Tides]

-- Exploration
	[761] = true, -- [Explore Arathi Highlands]
	[845] = true, -- [Explore Ashenvale]
	[852] = true, -- [Explore Azshara]
	[860] = true, -- [Explore Azuremyst Isle]
	[765] = true, -- [Explore Badlands]
	[865] = true, -- [Explore Blade's Edge Mountains]
	[766] = true, -- [Explore Blasted Lands]
	[861] = true, -- [Explore Bloodmyst Isle]
	[1264] = true, -- [Explore Borean Tundra]
	[775] = true, -- [Explore Burning Steppes]
	[1457] = true, -- [Explore Crystalsong Forest]
	[844] = true, -- [Explore Darkshore]
	[777] = true, -- [Explore Deadwind Pass]
	[4864] = true, -- [Explore Deepholm]
	[848] = true, -- [Explore Desolace]
	[1265] = true, -- [Explore Dragonblight]
	[627] = true, -- [Explore Dun Morogh]
	[728] = true, -- [Explore Durotar]
	[778] = true, -- [Explore Duskwood]
	[850] = true, -- [Explore Dustwallow Marsh]
	[771] = true, -- [Explore Eastern Plaguelands]
	[726] = true, -- [Explore Elwynn Forest]
	[859] = true, -- [Explore Eversong Woods]
	[853] = true, -- [Explore Felwood]
	[849] = true, -- [Explore Feralas]
	[858] = true, -- [Explore Ghostlands]
	[1266] = true, -- [Explore Grizzly Hills]
	[862] = true, -- [Explore Hellfire Peninsula]
	[772] = true, -- [Explore Hillsbrad Foothills]
	[1263] = true, -- [Explore Howling Fjord]
	[4863] = true, -- [Explore Hyjal]
	[1270] = true, -- [Explore Icecrown]
	[868] = true, -- [Explore Isle of Quel'Danas]
	[779] = true, -- [Explore Loch Modan]
	[855] = true, -- [Explore Moonglade]
	[736] = true, -- [Explore Mulgore]
	[866] = true, -- [Explore Nagrand]
	[843] = true, -- [Explore Netherstorm]
	[750] = true, -- [Explore Northern Barrens]
	[781] = true, -- [Explore Northern Stranglethorn]
	[780] = true, -- [Explore Redridge Mountains]
	[774] = true, -- [Explore Searing Gorge]
	[864] = true, -- [Explore Shadowmoon Valley]
	[1268] = true, -- [Explore Sholazar Basin]
	[856] = true, -- [Explore Silithus]
	[769] = true, -- [Explore Silverpine Forest]
	[4996] = true, -- [Explore Southern Barrens]
	[847] = true, -- [Explore Stonetalon Mountains]
	[1269] = true, -- [Explore Storm Peaks]
	[782] = true, -- [Explore Swamp of Sorrows]
	[851] = true, -- [Explore Tanaris]
	[842] = true, -- [Explore Teldrassil]
	[867] = true, -- [Explore Terokkar Forest]
	[4995] = true, -- [Explore the Cape of Stranglethorn]
	[773] = true, -- [Explore The Hinterlands]
	[846] = true, -- [Explore Thousand Needles]
	[768] = true, -- [Explore Tirisfal Glades]
	[4866] = true, -- [Explore Twilight Highlands]
	[4865] = true, -- [Explore Uldum]
	[854] = true, -- [Explore Un'Goro Crater]
	[4825] = true, -- [Explore Vashj'ir]
	[770] = true, -- [Explore Western Plaguelands]
	[802] = true, -- [Explore Westfall]
	[841] = true, -- [Explore Wetlands]
	[857] = true, -- [Explore Winterspring]
	[863] = true, -- [Explore Zangarmarsh]
	[1267] = true, -- [Explore Zul'Drak]
}

	------------------
	--- Auto Gratz ---
	------------------

function RSD:CHAT_MSG(event, msg, name)
	local throttle, chan
	
	if event == "CHAT_MSG_PARTY" then
		throttle, chan = cd.gzParty, "PARTY"
	elseif event == "CHAT_MSG_GUILD" then
		throttle, chan = cd.gzGuild, "GUILD"
	end
	
	if profile.AutoGratz and name ~= player.name and strfind(msg:lower(), "ding") and strlen(msg) <= 10 and time() > (throttle or 0) then
		cd.gzParty = time() + profile.GratzCooldown		
		self:AutoGratz(chan, name)
	end
end

function RSD:CHAT_MSG_GUILD_ACHIEVEMENT(event, msg, name)
	-- don't gratz if player is afk
	if profile.GratzAFK and UnitIsAFK("player") then return end
	
	if profile.AutoGratz and name ~= player.name and time() > (cd.gzGuild or 0) then
		if (not profile.AnyAchiev and strfind(msg, LEVEL)) or profile.gzGuild then
			if ((profile.FilterAchiev and not AchievementBlacklist[tonumber(msg:match("achievement:(%d+)"))]) or not profile.FilterAchiev) then
				cd.gzGuild = time() + profile.GratzCooldown
				self:AutoGratz("GUILD", name)
			end
		end
	end
end

function RSD:AutoGratz(chan, name)
	local args = args
	args.name = (random(2) == 1) and name or name:lower()
	args.gz = legend.gz[random(#legend.gz)]
	args.emot = legend.emot[random(#legend.emot)]
	args.rt = "{rt"..random(8).."}"
	
	local msg = profile.GratzRandom and profile.GratzMsg[random(profile.NumRandomGratz)] or profile.GratzMsg[1]
	msg = self:ReplaceArgs(msg, args)
	
	self:ScheduleTimer(function()
		SendChatMessage(msg, chan)
	end, (profile.GratzDelay == 0) and random(30, 200) / 10 or profile.GratzDelay)
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
	if msg == MARKED_AFK or strfind(msg, MARKED_AFK_MESSAGE) then
		afk = time()
	elseif msg == CLEARED_AFK and afk then
		LeaveAFK()
	end
end

function RSD:PLAYER_LEAVING_WORLD(event)
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
