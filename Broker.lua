local NAME, S = ...
local RSD = ReadySetDing
local ACD = LibStub("AceConfigDialog-3.0")

local time = time
local floor = floor
local format = format

local L = S.L
local player = S.player

	------------
	--- Time ---
	------------

local function MilitaryTime(v)
	local sec = floor(v) % 60
	local minute = floor(v/60) % 60
	local hour = floor(v/3600) % 24
	local day = floor(v/86400)
	
	if v >= 86400 then
		return format("%d:%02.f:%02.f:%02.f", day, hour, minute, sec)
	elseif v >= 3600 then
		return format("%02.f:%02.f:%02.f", hour, minute, sec)
	else
		return format("%02.f:%02.f", minute, sec)
	end
end

local TIME_PLAYED_LEVEL2 = gsub(TIME_PLAYED_LEVEL, "%%s", "")
local TIME_PLAYED_TOTAL2 = gsub(TIME_PLAYED_TOTAL, "%%s", "")

	------------------
	--- Experience ---
	------------------

local function PlayerXP()
	local curxp = UnitXP("player")
	local maxxp = UnitXPMax("player")
	return format("|cffFFFFFF%d|r / |cff71D5FF%d|r = |cffFFFFFF%.1f%%|r", curxp, maxxp, curxp/maxxp * 100)
end

local function RestedXP()
	local restedxp = GetXPExhaustion()
	local maxxp = UnitXPMax("player")
	return format("|cffF6ADC6+%d|r / |cff71D5FF%d|r = |cffF6ADC6+%.1f%%|r", restedxp, maxxp, restedxp/maxxp * 100)
end

	---------------------
	--- LibDataBroker ---
	---------------------

local dataobject = {
	type = player.level < player.maxlevel and "data source" or "launcher",
	icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
	OnClick = function(clickedframe, button)
		if IsModifierKeyDown() then
			RSD:SlashCommand(RSD:IsEnabled() and "0" or "1")
		else
			ACD[ACD.OpenFrames.ReadySetDing_Parent and "Close" or "Open"](ACD, "ReadySetDing_Parent")
		end
	end,
	OnTooltipShow = function(tt)
		tt:AddLine("|cffADFF2F"..NAME.."|r")
		
		tt:AddDoubleLine("|cffFFFFFF"..EXPERIENCE_COLON.."|r", PlayerXP())
		if GetXPExhaustion() then
			tt:AddDoubleLine("|cffF6ADC6"..select(2, GetRestState())..":|r", RestedXP())
		end
		
		tt:AddDoubleLine(TIME_PLAYED_LEVEL2, format("|cffADFF2F"..TIME_DAYHOURMINUTESECOND.."|r", unpack( {ChatFrame_TimeBreakDown(S.curTPM + time() - S.lastPlayed)} )))
		tt:AddDoubleLine(TIME_PLAYED_TOTAL2, format("|cff71D5FF"..TIME_DAYHOURMINUTESECOND.."|r", unpack( {ChatFrame_TimeBreakDown(S.totalTPM + time() - S.lastPlayed)} )))
		
		tt:AddLine(L.BROKER_CLICK)
		tt:AddLine(L.BROKER_SHIFT_CLICK)
	end,
}

	------------
	--- Text ---
	------------

-- Ticket #21: ChocolateBar might request the dataobject a tad too early, use placeholder number instead of string
local percent = 0

local function DataText()
	dataobject.text = format("%s - |cffFFFFFF%.1f%%|r", MilitaryTime(S.curTPM + time() - S.lastPlayed), percent)
end

	------------------
	--- Percentage ---
	------------------

local function OnEvent(self, event, ...)
	percent = UnitXP("player") / UnitXPMax("player") * 100
	DataText() -- don't wait for timer to update
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:SetScript("OnEvent", OnEvent)

	-------------
	--- Timer ---
	-------------

if player.level < player.maxlevel then
	RSD:ScheduleRepeatingTimer(DataText, 1)
else
	dataobject.text = NAME
end

LibStub("LibDataBroker-1.1"):NewDataObject(NAME, dataobject)
