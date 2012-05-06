local NAME, S = ...
local RSD = ReadySetDing
local ACD = LibStub("AceConfigDialog-3.0")

local L = S.L
local player = S.player

	---------------------
	--- LibDataBroker ---
	---------------------

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

local TIME_PLAYED_LEVEL2 = gsub(TIME_PLAYED_LEVEL, "%%s", "")
local TIME_PLAYED_TOTAL2 = gsub(TIME_PLAYED_TOTAL, "%%s", "")

local dataobject = {
	type = player.level < player.maxlevel and "data source" or "launcher",
	icon = "Interface\\AddOns\\ReadySetDing\\Images\\Windows7_Logo",
	OnClick = function(clickedframe, button)
		if IsModifierKeyDown() then
			RSD:SlashCommand(RSD:IsEnabled() and "0" or "1")
		else
			if ACD.OpenFrames.ReadySetDing_Parent then
				ACD:Close("ReadySetDing_Parent")
			else
				ACD:Open("ReadySetDing_Parent")
			end
			
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

if player.level < player.maxlevel then
	RSD:ScheduleRepeatingTimer(function()
		dataobject.text = MilitaryTime(S.curTPM + time() - S.lastPlayed)
	end, 1)
else
	dataobject.text = NAME
end

LibStub("LibDataBroker-1.1"):NewDataObject(NAME, dataobject)
