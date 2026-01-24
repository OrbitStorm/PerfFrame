-- =========================================
-- PerfFrame v2.2
-- created by Sawfty
-- inspired by Pytilix's FPS-MS-Tracker
-- =========================================

-- Initialize SavedVariables
PerfFrameDB = PerfFrameDB or {
    showTooltip = true,
    fontSize = 12,
    fontScale = 1,
    showClock = false,
    clockFormat = "12h",
    showMail = false,
    hideUntilHover = false,
    disabled = false,
    backgroundOpacity = 0,
    combatMode = "ALWAYS",
    showAddonMemory = false,
	showFPS = true,
    showMS = true,
    framePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
}

-- Initialize per-character SavedVariables (position override)
PerfFrameCharDB = PerfFrameCharDB or {
    useCustomPosition = false,
    framePos = nil
}

-- Ensure v1.0 users have a valid position structure
if not PerfFrameDB.framePos.relativePoint then
    PerfFrameDB.framePos.relativePoint = PerfFrameDB.framePos.point or "CENTER"
end
if not PerfFrameDB.framePos.relativeTo or type(PerfFrameDB.framePos.relativeTo) ~= "string" then
    PerfFrameDB.framePos.relativeTo = "UIParent"
end


-- Ensure fontSize default/migration
if not PerfFrameDB.fontSize then
    local ts = PerfFrameDB.textScale or "normal"
    if ts == "bigger" then
        PerfFrameDB.fontSize = 15
    elseif ts == "biggest" then
        PerfFrameDB.fontSize = 18
    else
        PerfFrameDB.fontSize = 12
    end
end

-- Ensure clockFormat defaults to 12h if nil
if not PerfFrameDB.clockFormat then
    PerfFrameDB.clockFormat = "12h"
end

-- Ensure new defaults
if PerfFrameDB.disabled == nil then PerfFrameDB.disabled = false end
if PerfFrameDB.backgroundOpacity == nil then PerfFrameDB.backgroundOpacity = 0 end
if not PerfFrameDB.combatMode then PerfFrameDB.combatMode = "ALWAYS" end

-- Create main frame
PerfFrame = CreateFrame("Frame", "PerfFrame", UIParent)
PerfFrame:EnableMouse(true)


-- =========================================
-- Visibility / Enable state helpers
-- =========================================
local function PerfFrame_IsInCombat()
    return (InCombatLockdown and InCombatLockdown()) or UnitAffectingCombat("player")
end

function PerfFrame_UpdateVisibility()
    if not PerfFrame then return end

    if PerfFrameDB and PerfFrameDB.disabled then
        PerfFrame:Hide()
        return
    end

    local mode = (PerfFrameDB and PerfFrameDB.combatMode) or "ALWAYS"
    if mode == "IN_COMBAT" then
        if PerfFrame_IsInCombat() then
            PerfFrame:Show()
        else
            PerfFrame:Hide()
        end
    elseif mode == "OUT_OF_COMBAT" then
        if PerfFrame_IsInCombat() then
            PerfFrame:Hide()
        else
            PerfFrame:Show()
        end
    else
        PerfFrame:Show()
    end
end

function PerfFrame_SetDisabled(disabled)
    PerfFrameDB.disabled = disabled and true or false
    PerfFrame_UpdateVisibility()

    -- Stop OnUpdate work while disabled to avoid wasted cycles
    if PerfFrameDB.disabled then
        if PerfFrame._onUpdateFunc then
            PerfFrame._savedOnUpdate = PerfFrame._onUpdateFunc
        end
        PerfFrame:SetScript("OnUpdate", nil)
    else
        if PerfFrame._savedOnUpdate then
            PerfFrame:SetScript("OnUpdate", PerfFrame._savedOnUpdate)
        end
    end
end

function PerfFrame_SetBackgroundOpacity(value)
    value = tonumber(value) or 0
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    PerfFrameDB.backgroundOpacity = value

    if PerfFrame and PerfFrame.bg then
        local a = value / 100
        if a <= 0 then
            PerfFrame.bg:Hide()
        else
            PerfFrame.bg:Show()
            PerfFrame.bg:SetAlpha(a)
        end
    end
end

function PerfFrame_SetCombatMode(mode)
    PerfFrameDB.combatMode = mode or "ALWAYS"
    PerfFrame_UpdateVisibility()
end

-- Movable configuration
local movable = true
local frame_anchor = "TOP" -- Not currently used for dynamic positioning
-- Visibility and display state
--local showTooltip = PerfFrameDB.showTooltip


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


-- Mode key for per-mode position storage (ALL / FPS / MS)
function PerfFrame_GetModeKey()
    local showFPS = PerfFrameDB and PerfFrameDB.showFPS
    local showMS  = PerfFrameDB and PerfFrameDB.showMS
    if showFPS and showMS then return "ALL" end
    if showFPS then return "FPS" end
    if showMS then return "MS" end
    return "ALL"
end

-- =========================================
-- Frame positioning
-- =========================================
-- Select active position source (global by default, per-character override when enabled)
local function PerfFrame_GetActivePosition()
    local modeKey = PerfFrame_GetModeKey and PerfFrame_GetModeKey() or "ALL"

    if PerfFrameCharDB and PerfFrameCharDB.useCustomPosition then
        if PerfFrameCharDB.framePosByMode and PerfFrameCharDB.framePosByMode[modeKey] then
            return PerfFrameCharDB.framePosByMode[modeKey]
        end
        if PerfFrameCharDB.framePos then
            return PerfFrameCharDB.framePos
        end
    end

    return PerfFrameDB.framePos
end

-- Apply saved position (called during load/login to survive disable/enable)
function PerfFrame_ApplySavedPosition()
    local pos = PerfFrame_GetActivePosition() or PerfFrameDB.framePos
    if not pos then return end

    -- Ensure structure is valid
    if not pos.relativePoint then
        pos.relativePoint = pos.point or "CENTER"
    end
    if not pos.relativeTo or type(pos.relativeTo) ~= "string" then
        pos.relativeTo = "UIParent"
    end

    PerfFrame:ClearAllPoints()
    -- Prevent layout cache from fighting SavedVariables
    if PerfFrame.SetUserPlaced then
        PerfFrame:SetUserPlaced(false)
    end
    PerfFrame:SetPoint(
        pos.point or "CENTER",
        _G[pos.relativeTo] or UIParent,
        pos.relativePoint or pos.point or "CENTER",
        pos.x or 0,
        pos.y or 0
    )
end

local function PerfFrame_SaveCurrentPosition()
    local p, rt, rp, x, y = PerfFrame:GetPoint()
    local pos = {
        point = p,
        relativeTo = (rt and rt.GetName and rt:GetName()) or "UIParent",
        relativePoint = rp or p,
        x = x,
        y = y
    }

    if PerfFrameCharDB and PerfFrameCharDB.useCustomPosition then
        local modeKey = PerfFrame_GetModeKey and PerfFrame_GetModeKey() or "ALL"
        PerfFrameCharDB.framePosByMode = PerfFrameCharDB.framePosByMode or {}
        PerfFrameCharDB.framePosByMode[modeKey] = pos
        PerfFrameCharDB.framePos = pos
    else
        PerfFrameDB.framePos = pos
    end
end

if movable then
    PerfFrame:SetClampedToScreen(true)
    PerfFrame:SetMovable(true)

    -- Position is applied later (ADDON_LOADED/PLAYER_LOGIN) to survive disable/enable

    PerfFrame:SetScript("OnMouseDown", function(self)
        if IsAltKeyDown() then self:StartMoving() end
    end)

    PerfFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        PerfFrame_SaveCurrentPosition()
    end)
else
    PerfFrame:ClearAllPoints()
    PerfFrame:SetPoint("LEFT", WorldFrame, "BOTTOMLEFT", 0, 10)
end

-- Apply saved position during load/login (survives disable/enable)
local PFPos = CreateFrame("Frame")
PFPos:RegisterEvent("ADDON_LOADED")
PFPos:RegisterEvent("PLAYER_LOGIN")
PFPos:RegisterEvent("PLAYER_ENTERING_WORLD")
PFPos:RegisterEvent("PLAYER_LOGOUT")
PFPos:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 ~= "PerfFrame" then return end

    if event == "PLAYER_LOGOUT" then
        -- Save a final position snapshot
        PerfFrame_SaveCurrentPosition()
        return
    end

    -- If custom position was just enabled but no custom pos exists yet, initialize from global
    if PerfFrameCharDB and PerfFrameCharDB.useCustomPosition and not PerfFrameCharDB.framePos then
        local g = PerfFrameDB.framePos
        if g then
            PerfFrameCharDB.framePos = {
                point = g.point,
                relativeTo = g.relativeTo,
                relativePoint = g.relativePoint,
                x = g.x,
                y = g.y
            }
        end
    end

    PerfFrame_ApplySavedPosition()


-- Combat visibility handler (Always/Only in combat/Hide in combat)
local PFVis = CreateFrame("Frame")
PFVis:RegisterEvent("PLAYER_REGEN_DISABLED")
PFVis:RegisterEvent("PLAYER_REGEN_ENABLED")
PFVis:RegisterEvent("PLAYER_ENTERING_WORLD")
PFVis:SetScript("OnEvent", function()
    if PerfFrame_UpdateVisibility then
        PerfFrame_UpdateVisibility()
    end
    if PerfFrameDB and PerfFrameDB.disabled then
        PerfFrame_SetDisabled(true)
    end
end)
end)

-- =========================================
-- Slash command handler
-- =========================================
SLASH_PERFFRAME1 = "/pf"
SLASH_PERFFRAME2 = "/pframe"
SLASH_PERFFRAME3 = "/perfframe"
SlashCmdList["PERFFRAME"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "" then
        PerfFrame_OpenOptions()
        return
    end

    if msg == "help" then
        print("|cffffd200PerfFrame|r commands:")
        print("|cffffd200/pf|r - Open settings panel")
        print("|cffffd200/pf reset|r - Reset frame position")
        return
    end

    if msg == "reset" then
        if not PerfFrame then
            print("PerfFrame: frame not loaded yet.")
            return
        end

        PerfFrame:ClearAllPoints()
        local def = { point="CENTER", relativeTo="UIParent", relativePoint="CENTER", x=0, y=0 }

        if PerfFrameCharDB and PerfFrameCharDB.useCustomPosition then
            -- if player is using toon specific positions, reset the current too
            if PerfFrame_GetModeKey then
                local modeKey = PerfFrame_GetModeKey() or "ALL"
                PerfFrameCharDB.framePosByMode = PerfFrameCharDB.framePosByMode or {}
                PerfFrameCharDB.framePosByMode[modeKey] = def
            end
            PerfFrameCharDB.framePos = def
        else
            PerfFrameDB.framePos = def
        end

        if PerfFrame_ApplySavedPosition then
            PerfFrame_ApplySavedPosition()
        else
            PerfFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end

        print("PerfFrame position reset to center.")
        return
    end

    print("PerfFrame: unknown command. Type |cffffd200/pf help|r")
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
    local fontSize = (PerfFrameDB.fontSize or 12)

    -- Determine color
    local color
    if not customColor then
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

    local function getFPS() return "|c00ffffff"..floor(GetFramerate()).."|r fps" end
    local function getLatencyRaw() return select(3, GetNetStats()) end
    local function getLatencyWorldRaw() return select(4, GetNetStats()) end
    local function getLatency() return "|c00ffffff"..getLatencyRaw().."|r ms" end
    local function getLatencyWorld() return "|c00ffffff"..getLatencyWorldRaw().."|r ms" end


    local function getTimePlain()
        local hour, min = tonumber(date("%H")), tonumber(date("%M"))
        if PerfFrameDB.clockFormat == "12h" then
            local ampm = hour >= 12 and "PM" or "AM"
            hour = hour % 12
            if hour == 0 then hour = 12 end
            return string.format("%02d:%02d %s", hour, min, ampm)
        else
            return string.format("%02d:%02d", hour, min)
        end
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
    -- External refresh helper (used by options UI)
    -- =========================================
    function PerfFrame_RefreshDisplay()
        if not PerfFrame or not PerfFrame.text then return end
        local mode = GetShowMode()
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
        PerfFrame:SetWidth(PerfFrame.text:GetStringWidth() + 12)
        PerfFrame:SetHeight(PerfFrame.text:GetStringHeight() + 8)
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

        -- Default visibility
        if PerfFrameDB.hideUntilHover then
            PerfFrame:SetAlpha(0)
        else
            PerfFrame:SetAlpha(1)
        end

        -- Bind hover handlers if either tooltip or hide-until-hover is enabled
        if PerfFrameDB.showTooltip or PerfFrameDB.hideUntilHover then
            PerfFrame:SetScript("OnEnter", function(self)
                if PerfFrameDB.hideUntilHover then
                    self:SetAlpha(1)
                end

                if not PerfFrameDB.showTooltip then
                    return
                end

                local success, err = pcall(function()
                    GameTooltip:ClearLines()
                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")

                    GameTooltip:AddLine("PerfFrame", color.r, color.g, color.b)
                    GameTooltip:AddLine("Hold |cffffd200ALT + Drag|r to reposition.", 1, 1, 1)
                    GameTooltip:AddLine("Type |cffffd200/pf|r for settings.", 1, 1, 1)

                    if PerfFrameDB.showClock then
                        GameTooltip:AddDoubleLine("Time", getTimePlain(), 1, 1, 1, 1, 1, 1)
                    end
                    if PerfFrameDB.showMail then
                        GameTooltip:AddDoubleLine("Mail", HasNewMail() and "New mail" or "No mail", 1, 1, 1, 1, 1, 1)
                    end

                    if PerfFrameDB.showAddonMemory then
                        local blizz = collectgarbage("count")
                        local addons, entry, memory, total, nr = {}, nil, nil, 0, 0
                        UpdateAddOnMemoryUsage()
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("AddOns", color.r, color.g, color.b)

                        for i = 1, safe_GetNumAddOns() do
                            memory = safe_GetAddOnMemoryUsage(i)
                            if memory and memory > 0 then
                                entry = { name = safe_GetAddOnInfo(i), memory = memory }
                                table.insert(addons, entry)
                                total = total + memory
                            end
                        end

                        table.sort(addons, function(a, b) return a.memory > b.memory end)
                        for _, entry in pairs(addons) do
                            if nr < addonList then
                                GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1, 1, 1, RGBGradient(entry.memory / 800))
                                nr = nr + 1
                            end
                        end

                        GameTooltip:AddLine(" ")
                        GameTooltip:AddDoubleLine("Total", memFormat(total), 1, 1, 1, RGBGradient(total / (1024 * 10)))
                        GameTooltip:AddDoubleLine("Total+Blizzard", memFormat(blizz), 1, 1, 1, RGBGradient(blizz / (1024 * 10)))
                    end
                end)

                -- Added safety handling for tooltip errors
                if not success then
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine("Tooltip error: " .. tostring(err), 1, 0, 0)
                end

                GameTooltip:Show()
            end)

            PerfFrame:SetScript("OnLeave", function(self)
                if PerfFrameDB.showTooltip then
                    GameTooltip:Hide()
                end
                if PerfFrameDB.hideUntilHover then
                    self:SetAlpha(0)
                end
            end)
        end
    end

    -- Initial tooltip setup
    setupTooltip()

    

-- =========================================
-- Background (optional, opacity slider)
-- =========================================
if not PerfFrame.bg then
    PerfFrame.bg = PerfFrame:CreateTexture(nil, "BACKGROUND")
    PerfFrame.bg:SetColorTexture(0, 0, 0, 1)
    PerfFrame.bg:SetPoint("TOPLEFT", PerfFrame, "TOPLEFT", -6, 4)
    PerfFrame.bg:SetPoint("BOTTOMRIGHT", PerfFrame, "BOTTOMRIGHT", 6, -4)
end
PerfFrame_SetBackgroundOpacity(PerfFrameDB.backgroundOpacity or 0)
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
    local function OnUpdateFunc(self, elapsed)
        if PerfFrameDB and PerfFrameDB.disabled then
            return
        end

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
            self:SetWidth(PerfFrame.text:GetStringWidth() + 12)
            self:SetHeight(PerfFrame.text:GetStringHeight() + 8)
        end
    end
    PerfFrame._onUpdateFunc = OnUpdateFunc
    PerfFrame._savedOnUpdate = OnUpdateFunc
    PerfFrame:SetScript("OnUpdate", OnUpdateFunc)

    -- Apply initial visibility/enable state (supports Disable + combat modes)
    if PerfFrame_UpdateVisibility then
        PerfFrame_UpdateVisibility()
    end
    if PerfFrameDB and PerfFrameDB.disabled then
        PerfFrame_SetDisabled(true)
    end
end)