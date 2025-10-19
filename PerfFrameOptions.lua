-- =========================================
-- PerfFrame Options Panel
-- =========================================
local addonVersion = "v1.0"

local panel = CreateFrame("Frame")
panel.name = "PerfFrame" -- side panel name

-- Helper to create a named checkbox
local function newCheckbox(idSuffix, label, dbKey, parent, description)
    local name = "PerfFrameOptionsCheck_"..idSuffix
    local check = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    check.label = _G[name.."Text"]
    check.label:SetText(label)
    if description then
        check.tooltipText = description
        check.tooltipRequirement = description
    end
    check:SetScript("OnClick", function(self)
        PerfFrameDB[dbKey] = self:GetChecked()
        if dbKey == "showTooltip" then
            if PerfFrameDB.showTooltip then
                PerfFrame:SetScript("OnEnter", setupTooltip)
            else
                PerfFrame:SetScript("OnEnter", nil)
                GameTooltip:Hide()
            end
        end
    end)
    check:SetChecked(PerfFrameDB[dbKey])
    return check
end

-- Ensure mail is off by default if nil
if PerfFrameDB.showMail == nil then
    PerfFrameDB.showMail = false
end

-- Ensure FPS/MS defaults if nil
if PerfFrameDB.showFPS == nil then PerfFrameDB.showFPS = true end
if PerfFrameDB.showMS == nil then PerfFrameDB.showMS = true end

panel:SetScript("OnShow", function(self)
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("PerfFrame") -- top of panel

    -- FPS checkbox
    local fpsCB = newCheckbox("FPS", "Show FPS", "showFPS", panel, "Toggle FPS display")
    fpsCB:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)
fpsCB:SetScript("OnClick", function(self)
    PerfFrameDB.showFPS = self:GetChecked()
    showMode = (PerfFrameDB.showFPS and PerfFrameDB.showMS) and "both"
              or (PerfFrameDB.showFPS and not PerfFrameDB.showMS) and "fps"
              or (not PerfFrameDB.showFPS and PerfFrameDB.showMS) and "ms"
              or "none"
end)

    -- MS checkbox
    local msCB = newCheckbox("MS", "Show MS", "showMS", panel, "Toggle latency display")
    msCB:SetPoint("TOPLEFT", fpsCB, "BOTTOMLEFT", 0, -8)
    msCB:SetScript("OnClick", function(self)
    PerfFrameDB.showMS = self:GetChecked()
    showMode = (PerfFrameDB.showFPS and PerfFrameDB.showMS) and "both"
              or (PerfFrameDB.showFPS and not PerfFrameDB.showMS) and "fps"
              or (not PerfFrameDB.showFPS and PerfFrameDB.showMS) and "ms"
              or "none"
end)

    -- Tooltip checkbox
    local tooltipCB = newCheckbox("Tooltip", "Show Tooltip", "showTooltip", panel, "Show AddOn memory/latency tooltip")
    tooltipCB:SetPoint("TOPLEFT", msCB, "BOTTOMLEFT", 0, -8)

    -- Clock checkbox
    local clockCB = newCheckbox("Clock", "Show Clock", "showClock", panel, "Show clock in frame")
    clockCB:SetPoint("TOPLEFT", tooltipCB, "BOTTOMLEFT", 0, -8)

    -- Mail checkbox
    local mailCB = newCheckbox("Mail", "Show Mail", "showMail", panel, "Show new mail icon in frame")
    mailCB:SetPoint("TOPLEFT", clockCB, "BOTTOMLEFT", 0, -8)

    -- Text Scale dropdown
    local textScaleDropdown = CreateFrame("Frame", "PerfFrameTextScaleDropdown", panel, "UIDropDownMenuTemplate")
    textScaleDropdown:SetPoint("TOPLEFT", mailCB, "BOTTOMLEFT", -15, -10) -- aligned vertically
    UIDropDownMenu_SetWidth(textScaleDropdown, 120)
    UIDropDownMenu_SetText(textScaleDropdown, "Display Scale")

    UIDropDownMenu_Initialize(textScaleDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        local scales = { "Normal", "Bigger", "Biggest" }
        for _, scale in ipairs(scales) do
            info.text = scale
            info.checked = (PerfFrameDB.textScale and PerfFrameDB.textScale:lower() == scale:lower())
            info.func = function()
                PerfFrameDB.textScale = scale:lower()
                PerfFrameTextScale = scale:lower()
                UIDropDownMenu_SetText(textScaleDropdown, "Display Scale")
                if PerfFrame.text and PerfFrame.text.SetFont then
                    local font, _, flags = PerfFrame.text:GetFont()
                    local baseSize = 12
                    local multiplier = 1
                    if scale:lower() == "bigger" then multiplier = 1.25
                    elseif scale:lower() == "biggest" then multiplier = 1.5 end
                    PerfFrame.text:SetFont(font, baseSize*multiplier, flags)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Version display at bottom
    local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOMLEFT", 16, 16)
    versionText:SetText("Version: "..addonVersion)
end)

-- Register panel with WoW's Interface Options
if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
else
    local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end