-- =========================================
-- PerfFrame v1.0
-- inspired by Pytilix's FPS-MS-Tracker
-- =========================================

-- Initialize SavedVariables
PerfFrameDB = PerfFrameDB or {
    showTooltip = false,
    textScale = "normal",
    showClock = false,
    clockFormat = "12h",
    showMail = false,
	showFPS = true,
    showMS = true,
    framePos = { point = "BOTTOMRIGHT", relativeTo = "UIParent", x = -315, y = 5 }
}

-- Ensure clockFormat defaults to 12h if nil
if not PerfFrameDB.clockFormat then
    PerfFrameDB.clockFormat = "12h"
end

-- Create main frame
PerfFrame = CreateFrame("Frame", "PerfFrame", UIParent)
PerfFrame:EnableMouse(true)

-- Movable configuration
local movable = true
local frame_anchor = "TOP" -- Not currently used for dynamic positioning

if movable then
    PerfFrame:SetClampedToScreen(true)
    PerfFrame:SetMovable(true)
    PerfFrame:SetUserPlaced(true)
    -- Restore saved position
    local pos = PerfFrameDB.framePos
    PerfFrame:ClearAllPoints()
    PerfFrame:SetPoint(pos.point, pos.relativeTo, pos.x, pos.y)
    PerfFrame:SetScript("OnMouseDown", function(self)
        if IsAltKeyDown() then self:StartMoving() end
    end)
    PerfFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local p, rt, _, x, y = self:GetPoint()
        PerfFrameDB.framePos = { point = p, relativeTo = rt:GetName(), x = x, y = y }
    end)
else
    PerfFrame:ClearAllPoints()
    PerfFrame:SetPoint("LEFT", WorldFrame, "BOTTOMLEFT", 0, 10)
end

-- Visibility and display state
--local showTooltip = PerfFrameDB.showTooltip
PerfFrameTextScale = PerfFrameDB.textScale

-- Text scale multiplier
local function GetTextScaleMultiplier()
    if PerfFrameTextScale == "bigger" then
        return 1.25
    elseif PerfFrameTextScale == "biggest" then
        return 1.5
    else
        return 1
    end
end

local function GetShowMode()
    if PerfFrameDB.showFPS and PerfFrameDB.showMS then
        return "both"
    elseif PerfFrameDB.showFPS then
        return "fps"
    elseif PerfFrameDB.showMS then
        return "ms"
    else
        -- fallback to both if somehow neither is true
        PerfFrameDB.showFPS = true
        PerfFrameDB.showMS = true
        return "both"
    end
end

-- =========================================
-- Slash command handler
-- =========================================
SLASH_PERFFRAME1 = "/perf"
SlashCmdList["PERFFRAME"] = function(msg)

    msg = msg:lower()
    if msg == "reset" then
        PerfFrame:ClearAllPoints()
        local default = PerfFrameDB.framePos
        PerfFrame:SetPoint(default.point, default.relativeTo, default.x, default.y)
        print("PerfFrame position reset to default.")
    elseif msg == "show fps" then
        PerfFrameDB.showFPS = true
        PerfFrameDB.showMS = false
        print("PerfFrame: showing FPS only.")
    elseif msg == "show ms" then
        PerfFrameDB.showFPS = false
        PerfFrameDB.showMS = true
        print("PerfFrame: showing MS only.")
    elseif msg == "show both" then
        PerfFrameDB.showFPS = true
        PerfFrameDB.showMS = true
        print("PerfFrame: showing both FPS and MS.")
    elseif msg:find("text") then
        local scale = msg:match("text%s+(%a+)")
        if scale == "normal" or scale == "bigger" or scale == "biggest" then
            PerfFrameTextScale = scale
            PerfFrameDB.textScale = scale
            if PerfFrame.text and PerfFrame.text.SetFont then
                local font, _, flags = PerfFrame.text:GetFont()
                local baseSize = 12
                local scaleMult = GetTextScaleMultiplier()
                PerfFrame.text:SetFont(font, baseSize * scaleMult, flags)
                print("PerfFrame text size set to " .. scale .. ".")
            end
        else
            print("Usage: /PerfFrame text normal | bigger | biggest")
        end
    elseif msg:find("tooltip") then
        local toggle = msg:match("tooltip%s*(%a*)")
        if toggle == "on" then
            PerfFrameDB.showTooltip = true
            print("PerfFrame tooltip enabled.")
        elseif toggle == "off" then
            PerfFrameDB.showTooltip = false
            print("PerfFrame tooltip disabled.")
        else
            PerfFrameDB.showTooltip = not PerfFrameDB.showTooltip
            print("PerfFrame tooltip " .. (PerfFrameDB.showTooltip and "enabled" or "disabled") .. ".")
        end
        showTooltip = PerfFrameDB.showTooltip
        setupTooltip()
    elseif msg:find("clock") then
    local toggle = msg:match("^clock%s*(%w+)$")
        if toggle == "on" then
            PerfFrameDB.showClock = true
            print("PerfFrame clock display enabled.")
        elseif toggle == "off" then
            PerfFrameDB.showClock = false
            print("PerfFrame clock display disabled.")
        elseif toggle == "12h" then
            PerfFrameDB.clockFormat = "12h"
            PerfFrameDB.showClock = true
            print("PerfFrame clock format set to 12h.")
        elseif toggle == "24h" then
            PerfFrameDB.clockFormat = "24h"
            PerfFrameDB.showClock = true
            print("PerfFrame clock format set to 24h.")
	    elseif toggle == nil then
        	-- only toggle display if no argument provided
            PerfFrameDB.showClock = not PerfFrameDB.showClock
            print("PerfFrame clock display " .. (PerfFrameDB.showClock and "enabled" or "disabled") .. ".")
        end
    elseif msg:find("mail") then
        local toggle = msg:match("mail%s*(%a*)")
        if toggle == "on" then
            PerfFrameDB.showMail = true
            print("PerfFrame mail display enabled.")
        elseif toggle == "off" then
            PerfFrameDB.showMail = false
            print("PerfFrame mail display disabled.")
        else
            PerfFrameDB.showMail = not PerfFrameDB.showMail
            print("PerfFrame mail display " .. (PerfFrameDB.showMail and "enabled" or "disabled") .. ".")
        end
    elseif msg == "help" then
        print("Available commands for PerfFrame:")
        print("/PerfFrame reset - Resets frame position")
        print("/PerfFrame show fps - Show only FPS")
        print("/PerfFrame show ms - Show only MS")
        print("/PerfFrame show both - Show FPS and MS")
        print("/PerfFrame text [normal|bigger|biggest] - Adjust text size")
        print("/PerfFrame tooltip on/off - Toggle tooltip")
        print("/PerfFrame clock on/off/12h/24h - Toggle clock display and set format")
        print("/PerfFrame mail on/off - Toggle mail display")
    else
        print("Usage:")
        print("/PerfFrame reset - Reset frame position")
        print("/PerfFrame show fps - Show only FPS")
        print("/PerfFrame show ms - Show only MS")
        print("/PerfFrame show both - Show FPS and MS")
        print("/PerfFrame text [normal|bigger|biggest] - Adjust text size")
        print("/PerfFrame tooltip on/off - Toggle tooltip")
        print("/PerfFrame clock on/off/12h/24h - Toggle clock display and set format")
        print("/PerfFrame mail on/off - Toggle mail display")
    end
end

-- =========================================
-- Frame setup on login
-- =========================================
local CF = CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)

    -- Basic font setup
    local FONT = STANDARD_TEXT_FONT
    local addonList = 50
    local font = FONT
    local baseFontSize = 12
    local fontFlag = "THINOUTLINE"
    local textAlign = "CENTER"
    local customColor = true
    local useShadow = false

    local fontSize = baseFontSize * GetTextScaleMultiplier()

    -- Determine color
    local color
    if customColor == false then
        color = { r = 1, g = 1, b = 1 }
    else
        local _, class = UnitClass("player")
        color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
    end

    -- Gradient for memory usage
    local gradientColor = { 0,1,0, 1,1,0, 1,0,0 }

    local function RGBGradient(num)
        local perc = math.min(num,1)
        local r1,g1,b1,r2,g2,b2,r3,g3,b3 = unpack(gradientColor)
        if perc < 0.5 then
            return r1+(r2-r1)*(perc*2), g1+(g2-g1)*(perc*2), b1+(b2-b1)*(perc*2)
        else
            local p = (perc-0.5)*2
            return r2+(r3-r2)*p, g2+(g3-g2)*p, b2+(b3-b2)*p
        end
    end

    local function memFormat(number)
        if number > 1024 then
            return string.format("%.2f mb", number/1024)
        else
            return string.format("%.1f kb", floor(number))
        end
    end

    local function getFPS()
        return "|c00ffffff"..floor(GetFramerate()).."|r fps"
    end

    local function getLatencyRaw()
        return select(3, GetNetStats())
    end

    local function getLatencyWorldRaw()
        return select(4, GetNetStats())
    end

    local function getLatency()
        return "|c00ffffff"..getLatencyRaw().."|r ms"
    end

    local function getLatencyWorld()
        return "|c00ffffff"..getLatencyWorldRaw().."|r ms"
    end

    local function getTime()
        if PerfFrameDB.showClock then
            local hour, min = tonumber(date("%H")), tonumber(date("%M"))
            local formattedTime
            if PerfFrameDB.clockFormat == "12h" then
                local ampm = hour >= 12 and "PM" or "AM"
                hour = hour % 12
                if hour == 0 then hour = 12 end
                formattedTime = string.format("%02d:%02d %s", hour, min, ampm)
            else
                formattedTime = string.format("%02d:%02d", hour, min)
            end
        return "|TInterface\\Icons\\INV_Misc_PocketWatch_01.blp:14:14|t " .. formattedTime
        end
        return ""
    end

    local function getMail()
    if PerfFrameDB.showMail and HasNewMail() then
        return " |TInterface\\Minimap\\TRACKING\\Mailbox.blp:14:14|t"
    end
        return ""
    end


    -- =========================================
    -- Tooltip setup
    -- =========================================
    local safe_GetNumAddOns = C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
    local safe_GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    local safe_GetAddOnMemoryUsage = C_AddOns and C_AddOns.GetAddOnMemoryUsage or GetAddOnMemoryUsage

    function setupTooltip()
        PerfFrame:SetScript("OnEnter", nil)
        PerfFrame:SetScript("OnLeave", nil)
        if PerfFrameDB.showTooltip then
            PerfFrame:SetScript("OnEnter", function(self)
                local success, err = pcall(function()
                    GameTooltip:ClearLines()
                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
                    local blizz = collectgarbage("count")
                    local addons, entry, memory, total, nr = {}, nil, nil, 0, 0
                    UpdateAddOnMemoryUsage()
                    GameTooltip:AddLine("AddOns", color.r, color.g, color.b)
                    for i = 1, safe_GetNumAddOns() do
                        memory = safe_GetAddOnMemoryUsage(i)
                        if memory > 0 then
                            entry = { name = safe_GetAddOnInfo(i), memory = memory }
                            table.insert(addons, entry)
                            total = total + memory
                        end
                    end
                    table.sort(addons, function(a,b) return a.memory>b.memory end)
                    for _,entry in pairs(addons) do
                        if nr < addonList then
                            GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1,1,1, RGBGradient(entry.memory/800))
                            nr = nr + 1
                        end
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine("Total", memFormat(total),1,1,1, RGBGradient(total/(1024*10)))
                    GameTooltip:AddDoubleLine("Total+Blizzard", memFormat(blizz),1,1,1, RGBGradient(blizz/(1024*10)))
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Network", color.r, color.g, color.b)
                    GameTooltip:AddDoubleLine("Local", getLatencyRaw().." ms",1,1,1, RGBGradient(getLatencyRaw()/100))
                    GameTooltip:AddDoubleLine("World", getLatencyWorldRaw().." ms",1,1,1, RGBGradient(getLatencyWorldRaw()/100))
                end)
                if not success then
                    GameTooltip:AddLine("Tooltip error: "..err,1,0,0)
                end
                GameTooltip:Show()
            end)
            PerfFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
    end

    -- Initial tooltip setup
    setupTooltip()

    -- =========================================
    -- Font string
    -- =========================================
    PerfFrame.text = PerfFrame:CreateFontString(nil, "BACKGROUND")
    PerfFrame.text:SetPoint(textAlign, PerfFrame)
    PerfFrame.text:SetFont(font, fontSize, fontFlag)
    if useShadow then
        PerfFrame.text:SetShadowOffset(1,-1)
        PerfFrame.text:SetShadowColor(0,0,0)
    end
    PerfFrame.text:SetTextColor(color.r, color.g, color.b)

    -- =========================================
    -- OnUpdate handler
    -- =========================================
    local lastUpdate = 0
    PerfFrame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate > 1 then
            lastUpdate = 0
            local mode = GetShowMode()  -- use the dynamic mode
            local text = ""
            if mode == "fps" then
                text = getFPS()
            elseif mode == "ms" then
                text = getLatency()
            else
                text = getFPS().." "..getLatency()
            end
            if PerfFrameDB.showClock then text = text.." "..getTime() end
            if PerfFrameDB.showMail then text = text.." "..getMail() end
            PerfFrame.text:SetText(text)
            self:SetWidth(PerfFrame.text:GetStringWidth())
            self:SetHeight(PerfFrame.text:GetStringHeight())
        end
    end)

end)