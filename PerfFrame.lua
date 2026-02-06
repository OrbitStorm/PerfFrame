-- =========================================
-- PerfFrame v2.3.0
-- =========================================

-- Initialize SavedVariables
if type(PerfFrameDB) ~= "table" then PerfFrameDB = nil end
PerfFrameDB = PerfFrameDB or {
    showTooltip = true,
    fontSize = 12,
    hideUntilHover = false,
    disabled = false,
    backgroundOpacity = 0,
    combatMode = "ALWAYS",
    showAddonMemory = false,
	showFPS = true,
    showMS = true,

    addonMemoryListMode = "TOP5",

    textColorMode = "CLASS", -- "CLASS" | "CUSTOM_BOTH" | "CUSTOM_SPLIT"
    customTextColor = { r = 1, g = 1, b = 1 },
    customFPSColor  = { r = 1, g = 1, b = 1 },
    customMSColor   = { r = 1, g = 1, b = 1 },

    framePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
}

-- Initialize per-character SavedVariables (position override)
if type(PerfFrameCharDB) ~= "table" then PerfFrameCharDB = nil end
PerfFrameCharDB = PerfFrameCharDB or {
    useCustomPosition = false,
    framePos = nil
}

-- Ensure per-character defaults
if PerfFrameCharDB.useCustomPosition == nil then PerfFrameCharDB.useCustomPosition = false end
if PerfFrameCharDB.framePos ~= nil and type(PerfFrameCharDB.framePos) ~= "table" then PerfFrameCharDB.framePos = nil end


-- Ensure framePos exists (older DB migrations)
if type(PerfFrameDB.framePos) ~= "table" then
    PerfFrameDB.framePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
end

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
    -- Remove legacy key once migrated
    PerfFrameDB.textScale = nil
end

-- Drop legacy fontScale (fontSize is now the single source of truth)
if PerfFrameDB.fontScale ~= nil then
    PerfFrameDB.fontScale = nil
end


-- Ensure new defaults
if PerfFrameDB.disabled == nil then PerfFrameDB.disabled = false end
if PerfFrameDB.backgroundOpacity == nil then PerfFrameDB.backgroundOpacity = 0 end
if not PerfFrameDB.combatMode then PerfFrameDB.combatMode = "ALWAYS" end


-- Ensure missing defaults from older versions
if PerfFrameDB.showTooltip == nil then PerfFrameDB.showTooltip = true end
if PerfFrameDB.hideUntilHover == nil then PerfFrameDB.hideUntilHover = false end
if PerfFrameDB.showAddonMemory == nil then PerfFrameDB.showAddonMemory = false end
-- AddOn Memory list mode (defaults to Top 5 for first-time installs).
-- Also guard against unexpected/invalid values (e.g. ""), which would otherwise fall back to Top 10.
do
    local m = PerfFrameDB.addonMemoryListMode
    if m ~= "TOP5" and m ~= "TOP10" and m ~= "TOP20" and m ~= "ALL" then
        PerfFrameDB.addonMemoryListMode = "TOP5"
    end
end

-- Text color defaults / upgrade guards
do
    local m = PerfFrameDB.textColorMode
    if m ~= "CLASS" and m ~= "CUSTOM_BOTH" and m ~= "CUSTOM_SPLIT" then
        PerfFrameDB.textColorMode = "CLASS"
    end

    local function normalizeColor(t)
        if type(t) ~= "table" then return { r = 1, g = 1, b = 1 } end
        local r = tonumber(t.r); local g = tonumber(t.g); local b = tonumber(t.b)
        if r == nil or g == nil or b == nil then return { r = 1, g = 1, b = 1 } end
        if r < 0 then r = 0 elseif r > 1 then r = 1 end
        if g < 0 then g = 0 elseif g > 1 then g = 1 end
        if b < 0 then b = 0 elseif b > 1 then b = 1 end
        return { r = r, g = g, b = b }
    end

    PerfFrameDB.customTextColor = normalizeColor(PerfFrameDB.customTextColor)
    PerfFrameDB.customFPSColor  = normalizeColor(PerfFrameDB.customFPSColor)
    PerfFrameDB.customMSColor   = normalizeColor(PerfFrameDB.customMSColor)
end

if PerfFrameDB.showFPS == nil then PerfFrameDB.showFPS = true end
if PerfFrameDB.showMS == nil then PerfFrameDB.showMS = true end
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
PFPos:RegisterEvent("MODIFIER_STATE_CHANGED")
PFPos:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 ~= "PerfFrame" then return end

    if event == "PLAYER_LOGOUT" then
        -- Save a final position snapshot
        PerfFrame_SaveCurrentPosition()
        return
    end
    if event == "MODIFIER_STATE_CHANGED" then
        if PerfFrame and PerfFrame._pfTooltipActive and GameTooltip:IsOwned(PerfFrame) and PerfFrame._showTooltipFunc then
            PerfFrame._showTooltipFunc(PerfFrame)
        end
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
    local fontFlag = "THINOUTLINE"
    local textAlign = "CENTER"
    local customColor = true
    local useShadow = false
    local fontSize = (PerfFrameDB.fontSize or 12)

    -- Determine colors
    local classColor
    if not customColor then
        classColor = { r = 1, g = 1, b = 1 }
    else
        local _, class = UnitClass("player")
        classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
    end

    local function ColorCodeFromRGB(r, g, b)
        r = tonumber(r) or 1; g = tonumber(g) or 1; b = tonumber(b) or 1
        if r < 0 then r = 0 elseif r > 1 then r = 1 end
        if g < 0 then g = 0 elseif g > 1 then g = 1 end
        if b < 0 then b = 0 elseif b > 1 then b = 1 end
        return string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
    end

    local function GetTextColorTables()
        local mode = PerfFrameDB.textColorMode or "CLASS"

	        -- The user's request is to color the *labels* ("fps" / "ms"), not the values.
	        -- Keep the base string color white, and apply color codes only to the labels.
	        if mode == "CUSTOM_BOTH" then
	            local c = PerfFrameDB.customTextColor or classColor
	            return { r = 1, g = 1, b = 1 }, c, c -- base white, fps label, ms label
	        elseif mode == "CUSTOM_SPLIT" then
	            local fpsC = PerfFrameDB.customFPSColor or classColor
	            local msC  = PerfFrameDB.customMSColor or classColor
	            return { r = 1, g = 1, b = 1 }, fpsC, msC -- base white, split label colors
	        else
	            return { r = 1, g = 1, b = 1 }, classColor, classColor
	        end
    end

    -- Tooltip header color stays class-based for consistency
    local color = classColor
    -- Memory usage color and formatting helpers
    local function HeatColor(pct)
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end

        if pct < 0.5 then
            local t = pct * 2
            return t, 1, 0
        else
            local t = (pct - 0.5) * 2
            return 1, 1 - t, 0
        end
    end

    local function formatKB(kb)
        if kb >= 1024 then
            return string.format("%.2f mb", kb / 1024)
        end
        return string.format("%.1f kb", floor(kb))
    end

    
    local function MemoryColor(kb, maxKB)
        -- Hybrid scaling:
        -- If the largest addon is 20 MB or more, use absolute thresholds for readability.
        -- Otherwise, use a relative gradient so small addon setups still show contrast.
        if maxKB and maxKB >= (20 * 1024) then
            local mb = kb / 1024
            if mb < 5 then
                return 0, 1, 0
            elseif mb < 20 then
                return 1, 1, 0
            elseif mb < 100 then
                return 1, 0.65, 0
            else
                return 1, 0, 0
            end
        end

        if not maxKB or maxKB <= 0 then
            return 1, 1, 1
        end

        return HeatColor(kb / maxKB)
    end

	local function getFPS()
	        local _, fpsC = GetTextColorTables()
	        local cc = ColorCodeFromRGB(fpsC.r, fpsC.g, fpsC.b)
	        return floor(GetFramerate()).." "..cc.."FPS|r"
	    end
    local function getLatencyRaw() return select(3, GetNetStats()) end
	    local function getLatency()
	        local _, _, msC = GetTextColorTables()
	        local cc = ColorCodeFromRGB(msC.r, msC.g, msC.b)
	        return getLatencyRaw().." "..cc.."MS|r"
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
        local baseC = select(1, GetTextColorTables())
        PerfFrame.text:SetTextColor(baseC.r, baseC.g, baseC.b)
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
            local PF_BRAND_TITLE = "|cffF59A23Perf|cff3FC7FFFrame|r"
            local function BuildTooltip(owner)
                local success, err = pcall(function()
                    GameTooltip:ClearLines()
                    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")

                    GameTooltip:AddLine(PF_BRAND_TITLE)
                    GameTooltip:AddLine("Hold |cffffd200ALT + Drag|r to reposition.", 1, 1, 1)
                    GameTooltip:AddLine("Type |cffffd200/pf|r for settings.", 1, 1, 1)

                    if PerfFrameDB.showAddonMemory then
                        local entries, total = {}, 0

                        UpdateAddOnMemoryUsage()
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("AddOn Memory", color.r, color.g, color.b)

                        for i = 1, safe_GetNumAddOns() do
                            local kb = safe_GetAddOnMemoryUsage(i)
                            if kb and kb > 0 then
                                local name = safe_GetAddOnInfo(i)
                                entries[#entries + 1] = { name = name, kb = kb }
                                total = total + kb
                            end
                        end

                        table.sort(entries, function(a, b) return a.kb > b.kb end)

                        local totalEntries = #entries
                        local maxKB = entries[1] and entries[1].kb or 0

                        local mode = PerfFrameDB.addonMemoryListMode or "TOP5"
                        local baseLimit
                        if mode == "ALL" then
                            baseLimit = totalEntries
                        elseif mode == "TOP5" then
                            baseLimit = 5
                        elseif mode == "TOP20" then
                            baseLimit = 20
                        else
                            baseLimit = 10
                        end

                        local shiftAll = IsShiftKeyDown() and true or false
                        local limit = shiftAll and totalEntries or baseLimit
                        local showing = math.min(limit, totalEntries)

                        for i = 1, showing do
                            local entry = entries[i]
                            local r, g, b = MemoryColor(entry.kb, maxKB)
                            GameTooltip:AddDoubleLine(entry.name, formatKB(entry.kb), 1, 1, 1, r, g, b)
                        end

                        GameTooltip:AddLine(" ")

                        -- Footer clarifies what is shown
                        if totalEntries > 0 then
                            local showingLine
                            local hintLine

                            if shiftAll and mode ~= "ALL" and totalEntries > baseLimit then
                                showingLine = string.format("Showing all %d addons (Shift).", totalEntries)
                            elseif mode == "ALL" or totalEntries <= baseLimit then
                                if mode == "ALL" then
                                    showingLine = string.format("Showing all %d addons.", totalEntries)
                                else
                                    showingLine = string.format("Showing all %d addons (Top %d).", totalEntries, baseLimit)
                                end
                            else
                                showingLine = string.format("Showing top %d of %d addons.", baseLimit, totalEntries)
                                hintLine = "Hold Shift to show all."
                            end

                            GameTooltip:AddLine(showingLine, 0.7, 0.7, 0.7)
                            if hintLine then
                                GameTooltip:AddLine(hintLine, 0.7, 0.7, 0.7)
                            end
                        end

                        GameTooltip:AddLine(" ")
                        local tr, tg, tb = MemoryColor(total, maxKB)
                        GameTooltip:AddDoubleLine("Total AddOns", formatKB(total), 1, 1, 1, tr, tg, tb)
                    end
                end)

                if not success then
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine("Tooltip error: " .. tostring(err), 1, 0, 0)
                end

                GameTooltip:Show()
            end

            PerfFrame._showTooltipFunc = BuildTooltip

            PerfFrame:SetScript("OnEnter", function(self)
                if PerfFrameDB.hideUntilHover then
                    self:SetAlpha(1)
                end

                if not PerfFrameDB.showTooltip then
                    return
                end

                PerfFrame._pfTooltipActive = true
                BuildTooltip(self)
            end)
            PerfFrame:SetScript("OnLeave", function(self)
                PerfFrame._pfTooltipActive = false
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
    local baseC = select(1, GetTextColorTables())
    PerfFrame.text:SetTextColor(baseC.r, baseC.g, baseC.b)

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
