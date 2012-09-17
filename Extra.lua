local NAME, S = ...
local RSD = ReadySetDing

local char

function RSD:RefreshDB3()
	char = self.db.char
end

local time = time

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
