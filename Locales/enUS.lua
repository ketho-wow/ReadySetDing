local L = LibStub("AceLocale-3.0"):NewLocale("ReadySetDing", "enUS", true)
if not L then return end

-- Main
L["Screenshot"] = true
L["Auto Gratz"] = true
L["Guild Members"] = GUILD.." "..MEMBERS
L["Stats"] = true
L["Profiles"] = true

-- Parameters
L["Previous Level"] = PREVIOUS.." "..LEVEL
L["New Level"] = NEW.." "..LEVEL
L["Remaining Levels"] = true
L["Max Level"] = "Max "..LEVEL
L["Level Time"] = LEVEL.." Time"
L["Total Time"] = true
L["Real Time"] = true
L["Level Speed"] = LEVEL.." "..SPEED
L["Average Level Speed"] = "Average "..LEVEL.." "..SPEED
L["Difference"] = true
L["AFK Time"] = true
L["Total AFK Time"] = true
L["Total Kills"] = "Total "..KILLS
L["Total Deaths"] = "Total "..DEATHS

-- Rest
L["[No Data]"] = true
L["Total"] = true
L["Delay"] = true
L["Cooldown"] = true
L["Activity"] = true

L["Ding! Level [LEVEL] in [TIME]"] = true