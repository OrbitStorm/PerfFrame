-- =========================================
-- PerfFrame Options Panel
-- =========================================
local addonVersion = "v2.2"

-- -------------------------------------------------
-- Helpers
-- -------------------------------------------------
local spacing = 20

-- Slider value highlight colors (use text defaults at runtime; gold matches label tone)
local VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B = 1, 0.82, 0
local function ShowTooltip(tooltip, frame, offsetX, offsetY)
    if not tooltip or not frame then return end
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(frame, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT", offsetX or 0, offsetY or 0)
    GameTooltip:SetText(tooltip[1], 1, 1, 1)
    for i = 2, #tooltip do
        GameTooltip:AddLine(tooltip[i], 1, 0.82, 0, true)
    end
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

local function AttachTooltip(tooltip, frame, offsetX, offsetY)
    if not frame or not tooltip then return end
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function() ShowTooltip(tooltip, frame, offsetX, offsetY) end)
    frame:SetScript("OnLeave", HideTooltip)
end

local function CreateOptionsTitle(parent, text, previousSibling)
    local titleFrame = CreateFrame("Frame", nil, parent)
    local optionsTitle = titleFrame:CreateFontString(nil, "Artwork", "GameFontHighlightHuge")
    optionsTitle:SetText(text)
    optionsTitle:SetPoint("TOPLEFT", 0, 0)
    local underline = titleFrame:CreateTexture()
    underline:SetAtlas("Options_HorizontalDivider", true)
    underline:SetPoint("BOTTOMLEFT", 0, 12)
    if (previousSibling) then
        titleFrame:SetPoint("LEFT")
        titleFrame:SetPoint("RIGHT")
        titleFrame:SetPoint("TOP", previousSibling, "BOTTOM", 0, -spacing)
    else
        titleFrame:SetPoint("TOPLEFT", 0, -spacing)
        titleFrame:SetPoint("RIGHT")
    end
    titleFrame:SetHeight(optionsTitle:GetStringHeight() + 20)
    return titleFrame
end

local function RefreshPerfFrameText()
    if PerfFrame_RefreshDisplay then PerfFrame_RefreshDisplay() end
end

local function ApplyFontScale(scale)
    scale = tonumber(scale) or 1
    if scale < 0.5 then scale = 0.5 end
    if scale > 2 then scale = 2 end
    PerfFrameDB.fontScale = scale
    -- Keep fontSize in sync for backwards compatibility
    PerfFrameDB.fontSize = math.floor((12 * scale) + 0.5)

    if PerfFrame and PerfFrame.text and PerfFrame.text.GetFont then
        local font, _, flags = PerfFrame.text:GetFont()
        PerfFrame.text:SetFont(font, PerfFrameDB.fontSize, flags)
    end
    RefreshPerfFrameText()
end

local function GetFontScale()
    if PerfFrameDB.fontScale then return PerfFrameDB.fontScale end
    if PerfFrameDB.fontSize then return (PerfFrameDB.fontSize / 12) end
    return 1
end


local function ApplyBackgroundOpacity(value)
    value = tonumber(value) or 0
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    PerfFrameDB.backgroundOpacity = value
    if PerfFrame_SetBackgroundOpacity then
        PerfFrame_SetBackgroundOpacity(value)
    elseif PerfFrame and PerfFrame.bg then
        local a = value / 100
        if a <= 0 then
            PerfFrame.bg:Hide()
        else
            PerfFrame.bg:Show()
            PerfFrame.bg:SetAlpha(a)
        end
    end
end

local function GetBackgroundOpacity()
    return tonumber(PerfFrameDB.backgroundOpacity) or 0
end


local function SkinMinimalCheckbox(cb)
    -- Avoid SetCheckedAtlas (not available on all clients). Use checked texture atlas instead.
    cb:SetNormalAtlas("checkbox-minimal", true)
    cb:SetPushedAtlas("checkbox-minimal", true)
    cb:SetHighlightAtlas("checkbox-minimal-highlight")

    if not cb:GetCheckedTexture() then
        cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    end
    local checked = cb:GetCheckedTexture()
    if checked and checked.SetAtlas then
        checked:SetAtlas("checkbox-minimal-checkmark", true)
    end
end

-- -------------------------------------------------
-- Options Canvas
-- -------------------------------------------------
local Home = CreateFrame("Frame")
Home:Hide()


Home:SetScript("OnHide", function(self)
    if self._headerMask and SettingsPanel and SettingsPanel.Bg and SettingsPanel.Bg.TopSection then
        SettingsPanel.Bg.TopSection:RemoveMaskTexture(self._headerMask)
    end
    -- Ensure slider value colors never get "stuck" when the panel hides mid-hover
    if self._fontValueText and self._fontValueNormal then
        local c = self._fontValueNormal
        self._fontValueText:SetTextColor(c[1], c[2], c[3])
    end
    if self._bgValueText and self._bgValueNormal then
        local c = self._bgValueNormal
        self._bgValueText:SetTextColor(c[1], c[2], c[3])
    end

end)

Home:SetScript("OnShow", function(self)
    if self._built then
        -- Refresh dynamic states
        if self._disableCB then
            self._disableCB:SetChecked(PerfFrameDB.disabled and true or false)
        end
        if self._frameInfoPopout then
            local showFPS = PerfFrameDB.showFPS and true or false
            local showMS  = PerfFrameDB.showMS and true or false
            local v = (showFPS and showMS) and "ALL" or (showFPS and "FPS") or (showMS and "MS") or "ALL"
            self._frameInfoPopout:SetSelectedValue(v)
        end
        if self._combatPopout then
            local v = PerfFrameDB.combatMode or "ALWAYS"
            self._combatPopout:SetSelectedValue(v)
        end
        if self._extraInfoPopout then
            local showClock = PerfFrameDB.showClock and true or false
            local showMail  = PerfFrameDB.showMail and true or false
            local v = (showClock and showMail) and "ALL" or (showClock and "CLOCK") or (showMail and "MAIL") or "OFF"
            self._extraInfoPopout:SetSelectedValue(v)
        end
        if self._addonMemCB then
            self._addonMemCB:SetChecked(PerfFrameDB.showAddonMemory and true or false)
        end
        if self._useCustomCB then
            PerfFrameCharDB = PerfFrameCharDB or {}
            self._useCustomCB:SetChecked(PerfFrameCharDB.useCustomPosition and true or false)
        end
        if self._fontScaleSlider then
            self._fontScaleSlider:Init(GetFontScale(), 0.5, 2, 100)

            if self._fontScaleSlider.Slider and self._fontScaleOnValueChanged then
                self._fontScaleSlider.Slider:SetScript("OnValueChanged", self._fontScaleOnValueChanged)
            end
            if self._fontValueText and self._fontValueNormal then
                local c = self._fontValueNormal
                self._fontValueText:SetTextColor(c[1], c[2], c[3])
            end
        end
        if self._bgOpacitySlider then
            self._bgOpacitySlider:Init(GetBackgroundOpacity(), 0, 100, 100)

            if self._bgOpacitySlider.Slider and self._bgOpacityOnValueChanged then
                self._bgOpacitySlider.Slider:SetScript("OnValueChanged", self._bgOpacityOnValueChanged)
            end
            if self._bgValueText and self._bgValueNormal then
                local c = self._bgValueNormal
                self._bgValueText:SetTextColor(c[1], c[2], c[3])
            end
        end
        return
    end
    self._built = true
    -- header banner
    local header = CreateFrame("Frame", nil, self)

    do
        local boundingBox = CreateFrame("Frame", nil, self)
        header = boundingBox

        local background = CreateFrame("Frame", nil, boundingBox)
        background:SetAllPoints()
        background:SetFrameStrata("LOW")

        local colorBar = background:CreateTexture(nil, "BACKGROUND")
        -- neutral gray
        local a = 0.95
        local r, g, b = 0.18 / a, 0.18 / a, 0.18 / a
        colorBar:SetColorTexture(r, g, b, a)
        colorBar:SetAllPoints()

        local mask = background:CreateMaskTexture()
        mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOWHITE", "CLAMPTOWHITE", "TRILINEAR")
        mask:SetAllPoints()
        self._headerMask = mask

        local logo = boundingBox:CreateTexture(nil, "ARTWORK")
        logo:SetTexture("Interface\\AddOns\\PerfFrame\\icon-nobg.tga", "CLAMP", "CLAMP", "TRILINEAR")
        -- keep the logo inside banner bounds
        logo:SetPoint("TOPRIGHT", -12, -4)
        logo:SetSize(54, 54)
        if logo.AddMaskTexture then
            logo:AddMaskTexture(mask)
        end

        local title = boundingBox:CreateFontString(nil, "ARTWORK", "Game36Font_Shadow2")
        title:SetTextColor(GameFontNormal:GetTextColor())
        title:SetText("PerfFrame")
        title:SetPoint("BOTTOMLEFT", 29, 16)

        local version = boundingBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        version:SetText(string.format("Version %s", addonVersion))
        version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 7, 2)

        local divider = boundingBox:CreateTexture()
        divider:SetAtlas("Options_HorizontalDivider", true)
        divider:SetPoint("TOP", 0, -59)

        boundingBox:ClearAllPoints()
        boundingBox:SetPoint("TOPLEFT", self, "TOPLEFT", -14, 10)
        boundingBox:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 3, -50)
        boundingBox:Show()

        if SettingsPanel and SettingsPanel.Bg and SettingsPanel.Bg.TopSection then
            SettingsPanel.Bg.TopSection:AddMaskTexture(mask)
        end
    end

    -- Content area (scrollable)

    local scrollFrame = CreateFrame("Frame", nil, self, "WowScrollBox")
    scrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -36, 10)

    local scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 16, -6)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 16, 7)

    local boundingBox = CreateFrame("Frame", nil, scrollFrame)
    boundingBox:SetPoint("TOPLEFT")
    boundingBox:SetPoint("RIGHT")
    boundingBox:SetHeight(30)
    boundingBox.scrollable = true

    local view = CreateScrollBoxLinearView()
    ScrollUtil.InitScrollBoxWithScrollBar(scrollFrame, scrollBar, view)

    local contents = CreateFrame("Frame", nil, boundingBox)
    contents:SetSize(1, 1)
    contents:ClearAllPoints()
    contents:SetPoint("TOPLEFT")
    contents:SetPoint("RIGHT")

    -- Helper to force a consistent scroll range once the full UI is built.
    local function UpdateScrollRange(lastFrame)
        if not lastFrame or not lastFrame.GetBottom then return end
        local top = contents:GetTop()
        local bottom = lastFrame:GetBottom()
        if top and bottom then
            local h = (top - bottom) + 20
            if h < 1 then h = 1 end
            contents:SetHeight(h)
            boundingBox:SetHeight(h)
            scrollFrame:FullUpdate(true)
            scrollFrame:ScrollToBegin()
        end
    end
    self._UpdatePerfFrameScrollRange = UpdateScrollRange

    local configurationTitle = CreateOptionsTitle(contents, "Settings", nil)
    local configurationFrame = CreateFrame("Frame", nil, contents, "ResizeLayoutFrame")
    configurationFrame:SetPoint("LEFT")
    configurationFrame:SetPoint("RIGHT")
    configurationFrame:SetPoint("TOP", configurationTitle, "BOTTOM", 0, 0)
    -- TIP line
    local tipFrame = CreateFrame("Frame", nil, configurationFrame)
    tipFrame:SetPoint("TOPLEFT")
    tipFrame:SetPoint("RIGHT")
    tipFrame:SetHeight(14)
    tipFrame.Label = tipFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tipFrame.Label:SetJustifyH("LEFT")
    tipFrame.Label:SetPoint("LEFT", 16, 0)
    tipFrame.Label:SetText("|cFFFF0000TIP:|r You can access these settings quickly by using the |cffffd200/pf|r command.")


-- Row builder
local function CreateRow(parent, anchorFrame, labelText)
    local row = CreateFrame("Frame", nil, parent)
    if anchorFrame then
        row:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -8)
    else
        row:SetPoint("TOPLEFT", tipFrame, "BOTTOMLEFT", 16, -8)
    end
    row:SetPoint("RIGHT")
    row:SetHeight(30)
    row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.Label:SetJustifyH("LEFT")
    row.Label:SetPoint("LEFT", 32, 0)
    row.Label:SetText(labelText)
    return row
end

-- -----------------------------------------
-- 1) Disable PerfFrame
-- -----------------------------------------
local disableRow = CreateRow(configurationFrame, nil, "Disable PerfFrame")
local disableCB = CreateFrame("CheckButton", nil, disableRow, "UICheckButtonTemplate")
disableCB:SetSize(30, 29)
disableCB:SetPoint("LEFT", 230, 0)
SkinMinimalCheckbox(disableCB)
disableCB:SetScript("OnClick", function(btn)
    local checked = btn:GetChecked() and true or false
    PerfFrameDB.disabled = checked
    if PerfFrame_SetDisabled then
        PerfFrame_SetDisabled(checked)
    elseif PerfFrame_UpdateVisibility then
        PerfFrame_UpdateVisibility()
    elseif PerfFrame then
        if checked then PerfFrame:Hide() else PerfFrame:Show() end
    end
end)
disableCB:SetChecked(PerfFrameDB.disabled and true or false)
self._disableCB = disableCB
AttachTooltip({
    "Disable PerfFrame",
    "Hides the PerfFrame display.",
}, disableRow.Label)

-- -----------------------------------------
-- 2) Frame Information
-- -----------------------------------------
local frameInfoRow = CreateRow(configurationFrame, disableRow, "Frame Information")

local function GetFrameInfoValue()
    local showFPS = PerfFrameDB.showFPS and true or false
    local showMS  = PerfFrameDB.showMS and true or false
    if showFPS and showMS then return "ALL" end
    if showFPS then return "FPS" end
    if showMS then return "MS" end
    return "ALL"
end

local frameInfoPopout
frameInfoPopout = PerfFrameTemplates.CreatePFPopout(
    frameInfoRow,
    {
        { label = "Show All",      value = "ALL", selected = GetFrameInfoValue() == "ALL" },
        { label = "Show FPS Only", value = "FPS", selected = GetFrameInfoValue() == "FPS" },
        { label = "Show MS Only",  value = "MS",  selected = GetFrameInfoValue() == "MS"  },
    },
    function()
        local v = frameInfoPopout.selected.value
        if v == "FPS" then
            PerfFrameDB.showFPS = true
            PerfFrameDB.showMS  = false
        elseif v == "MS" then
            PerfFrameDB.showFPS = false
            PerfFrameDB.showMS  = true
        else
            PerfFrameDB.showFPS = true
            PerfFrameDB.showMS  = true
        end
        RefreshPerfFrameText()
        if PerfFrameCharDB and PerfFrameCharDB.useCustomPosition and PerfFrame_ApplySavedPosition then
            PerfFrame_ApplySavedPosition()
        end
    end
)
frameInfoPopout:SetPoint("LEFT", 230, 0)
if frameInfoPopout.Popout and frameInfoPopout.Popout.Layout then frameInfoPopout.Popout:Layout() end
self._frameInfoPopout = frameInfoPopout
AttachTooltip({
    "Frame Information",
    "Choose what to show inside the frame (FPS, MS, or both).",
}, frameInfoRow.Label)

function frameInfoPopout:SetSelectedValue(val)
    for idx, e in ipairs(self.entries or {}) do
        if e.value == val then
            self:Select(idx)
            break
        end
    end
end

-- -----------------------------------------
-- 3) Frame Extra Info
-- -----------------------------------------
local extraInfoRow = CreateRow(configurationFrame, frameInfoRow, "Frame Extra Info")

local function GetExtraInfoValue()
    local showClock = PerfFrameDB.showClock and true or false
    local showMail  = PerfFrameDB.showMail and true or false
    if showClock and showMail then return "ALL" end
    if showMail then return "MAIL" end
    if showClock then return "CLOCK" end
    return "OFF"
end

local extraInfoPopout
extraInfoPopout = PerfFrameTemplates.CreatePFPopout(
    extraInfoRow,
    {
        { label = "OFF",        value = "OFF",   selected = GetExtraInfoValue() == "OFF" },
        { label = "Show All",   value = "ALL",   selected = GetExtraInfoValue() == "ALL" },
        { label = "Show Mail",  value = "MAIL",  selected = GetExtraInfoValue() == "MAIL" },
        { label = "Show Clock", value = "CLOCK", selected = GetExtraInfoValue() == "CLOCK" },
    },
    function()
        local v = extraInfoPopout.selected.value
        if v == "OFF" then
            PerfFrameDB.showClock = false
            PerfFrameDB.showMail  = false
        elseif v == "MAIL" then
            PerfFrameDB.showClock = false
            PerfFrameDB.showMail  = true
        elseif v == "CLOCK" then
            PerfFrameDB.showClock = true
            PerfFrameDB.showMail  = false
        else
            PerfFrameDB.showClock = true
            PerfFrameDB.showMail  = true
        end
        RefreshPerfFrameText()
    end
)
extraInfoPopout:SetPoint("LEFT", 230, 0)
if extraInfoPopout.Popout and extraInfoPopout.Popout.Layout then extraInfoPopout.Popout:Layout() end
self._extraInfoPopout = extraInfoPopout
AttachTooltip({
    "Frame Extra Info",
    "Controls the clock and mail indicators displayed next to the FPS/MS text.",
}, extraInfoRow.Label)

function extraInfoPopout:SetSelectedValue(val)
    for idx, e in ipairs(self.entries or {}) do
        if e.value == val then
            self:Select(idx)
            break
        end
    end
end

-- -----------------------------------------
-- 4) Combat Toggle
-- -----------------------------------------
local combatRow = CreateRow(configurationFrame, extraInfoRow, "Combat Toggle")

local function GetCombatModeValue()
    return PerfFrameDB.combatMode or "ALWAYS"
end

local combatPopout
combatPopout = PerfFrameTemplates.CreatePFPopout(
    combatRow,
    {
        { label = "Always Show",         value = "ALWAYS",        selected = GetCombatModeValue() == "ALWAYS" },
        { label = "Show Only in Combat", value = "IN_COMBAT",     selected = GetCombatModeValue() == "IN_COMBAT" },
        { label = "Hide When in Combat", value = "OUT_OF_COMBAT", selected = GetCombatModeValue() == "OUT_OF_COMBAT" },
    },
    function()
        local v = combatPopout.selected.value
        PerfFrameDB.combatMode = v
        if PerfFrame_SetCombatMode then
            PerfFrame_SetCombatMode(v)
        elseif PerfFrame_UpdateVisibility then
            PerfFrame_UpdateVisibility()
        end
    end
)
combatPopout:SetPoint("LEFT", 230, 0)
if combatPopout.Popout and combatPopout.Popout.Layout then combatPopout.Popout:Layout() end
self._combatPopout = combatPopout
AttachTooltip({
    "Combat Toggle",
    "Controls when the frame is visible based on combat state.",
}, combatRow.Label)

function combatPopout:SetSelectedValue(val)
    for idx, e in ipairs(self.entries or {}) do
        if e.value == val then
            self:Select(idx)
            break
        end
    end
end

-- -----------------------------------------
-- 5) Show Addon Memory
-- -----------------------------------------
local addonMemRow = CreateRow(configurationFrame, combatRow, "Show Addon Memory")
local addonMemCB = CreateFrame("CheckButton", nil, addonMemRow, "UICheckButtonTemplate")
addonMemCB:SetSize(30, 29)
addonMemCB:SetPoint("LEFT", 230, 0)
SkinMinimalCheckbox(addonMemCB)
addonMemCB:SetScript("OnClick", function(btn)
    PerfFrameDB.showAddonMemory = btn:GetChecked() and true or false
    if PerfFrame_RefreshDisplay then PerfFrame_RefreshDisplay() end
end)
addonMemCB:SetChecked(PerfFrameDB.showAddonMemory and true or false)
self._addonMemCB = addonMemCB
AttachTooltip({
    "Show Addon Memory",
    "When enabled, the tooltip will include an AddOn memory usage list.",
}, addonMemRow.Label)

-- -----------------------------------------
-- 6) Use Custom Frame Position
-- (active mode, this character)
-- -----------------------------------------
local customPosRow = CreateRow(configurationFrame, addonMemRow, "Use Custom Frame Position")
local useCustomCB = CreateFrame("CheckButton", nil, customPosRow, "UICheckButtonTemplate")
useCustomCB:SetSize(30, 29)
useCustomCB:SetPoint("LEFT", 230, 0)
SkinMinimalCheckbox(useCustomCB)
useCustomCB:SetScript("OnClick", function(btn)
    PerfFrameCharDB = PerfFrameCharDB or {}
    local checked = btn:GetChecked() and true or false
    PerfFrameCharDB.useCustomPosition = checked

    if checked then
        local modeKey = (PerfFrame_GetModeKey and PerfFrame_GetModeKey()) or "ALL"
        PerfFrameCharDB.framePosByMode = PerfFrameCharDB.framePosByMode or {}

        if not PerfFrameCharDB.framePosByMode[modeKey] then
            PerfFrameDB.framePos = PerfFrameDB.framePos or { point="CENTER", relativeTo="UIParent", relativePoint="CENTER", x=0, y=0 }
            local src = PerfFrameDB.framePos
            PerfFrameCharDB.framePosByMode[modeKey] = {
                point = src.point,
                relativeTo = src.relativeTo,
                relativePoint = src.relativePoint,
                x = src.x,
                y = src.y,
            }
        end

        -- Legacy field
        PerfFrameCharDB.framePos = PerfFrameCharDB.framePosByMode[modeKey]
    end

    if PerfFrame_ApplySavedPosition then
        PerfFrame_ApplySavedPosition()
    end
end)
PerfFrameCharDB = PerfFrameCharDB or {}
useCustomCB:SetChecked(PerfFrameCharDB.useCustomPosition and true or false)
self._useCustomCB = useCustomCB
AttachTooltip({
    "Use Custom Frame Position",
    "When enabled, the frame position becomes specific to this character.",
}, customPosRow.Label)

-- -----------------------------------------
-- 7) Font Scale
-- -----------------------------------------
local fontScaleRow = CreateRow(configurationFrame, customPosRow, "Font Scale")
local fontScaleSlider = CreateFrame("Frame", nil, fontScaleRow, "MinimalSliderWithSteppersTemplate")
fontScaleSlider:Init(GetFontScale(), 0.5, 2, 100)
fontScaleSlider:SetPoint("LEFT", 230, 0)

local fontValue = fontScaleRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
fontValue:SetPoint("LEFT", fontScaleSlider, "RIGHT", 10, 0)
fontValue:SetText(tostring(PerfFrameDB.fontSize or math.floor((12 * GetFontScale()) + 0.5)))

-- Value highlight + behavior re-attach support
self._fontValueText = fontValue
do
    local nr, ng, nb = fontValue:GetTextColor()
    self._fontValueNormal = { nr, ng, nb }

    fontScaleSlider:HookScript("OnEnter", function()
        fontValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
    end)
    fontScaleSlider:HookScript("OnLeave", function()
        fontValue:SetTextColor(nr, ng, nb)
    end)

    if fontScaleSlider.Slider and fontScaleSlider.Slider.HookScript then
        fontScaleSlider.Slider:HookScript("OnMouseDown", function()
            fontValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
        end)
        fontScaleSlider.Slider:HookScript("OnMouseUp", function()
            fontValue:SetTextColor(nr, ng, nb)
        end)
    end
end


--local smallLabel = fontScaleRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
--smallLabel:SetPoint("BOTTOMLEFT", fontScaleSlider.Slider, "BOTTOMLEFT", 0, -2)
--smallLabel:SetTextColor(1, 1, 1, 1)
--smallLabel:SetText("Small")

--local largeLabel = fontScaleRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
--largeLabel:SetPoint("BOTTOMRIGHT", fontScaleSlider.Slider, "BOTTOMRIGHT", 0, -2)
--largeLabel:SetTextColor(1, 1, 1, 1)
--largeLabel:SetText("Large")

local function PerfFrame_FontScale_OnValueChanged(_, value)
    ApplyFontScale(value)
    fontValue:SetText(tostring(PerfFrameDB.fontSize or math.floor((12 * (PerfFrameDB.fontScale or 1)) + 0.5)))
end
fontScaleSlider.Slider:SetScript("OnValueChanged", PerfFrame_FontScale_OnValueChanged)
self._fontScaleOnValueChanged = PerfFrame_FontScale_OnValueChanged

self._fontScaleSlider = fontScaleSlider
AttachTooltip({
    "Font Scale",
    "Adjust the size of the text in the frame.",
}, fontScaleRow.Label)

-- -----------------------------------------
-- 8) Background Opacity
-- -----------------------------------------
local bgOpacityRow = CreateRow(configurationFrame, fontScaleRow, "Background Opacity")
local bgOpacitySlider = CreateFrame("Frame", nil, bgOpacityRow, "MinimalSliderWithSteppersTemplate")
bgOpacitySlider:Init(GetBackgroundOpacity(), 0, 100, 100)
bgOpacitySlider:SetPoint("LEFT", 230, 0)

local bgValue = bgOpacityRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bgValue:SetPoint("LEFT", bgOpacitySlider, "RIGHT", 10, 0)
bgValue:SetText(tostring(GetBackgroundOpacity()))

-- Value highlight + behavior re-attach support
self._bgValueText = bgValue
do
    local nr, ng, nb = bgValue:GetTextColor()
    self._bgValueNormal = { nr, ng, nb }

    bgOpacitySlider:HookScript("OnEnter", function()
        bgValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
    end)
    bgOpacitySlider:HookScript("OnLeave", function()
        bgValue:SetTextColor(nr, ng, nb)
    end)

    if bgOpacitySlider.Slider and bgOpacitySlider.Slider.HookScript then
        bgOpacitySlider.Slider:HookScript("OnMouseDown", function()
            bgValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
        end)
        bgOpacitySlider.Slider:HookScript("OnMouseUp", function()
            bgValue:SetTextColor(nr, ng, nb)
        end)
    end
end


--local zeroLabel = bgOpacityRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
--zeroLabel:SetPoint("BOTTOMLEFT", bgOpacitySlider.Slider, "BOTTOMLEFT", 0, -2)
--zeroLabel:SetTextColor(1, 1, 1, 1)
--zeroLabel:SetText("0")

--local hundredLabel = bgOpacityRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
--hundredLabel:SetPoint("BOTTOMRIGHT", bgOpacitySlider.Slider, "BOTTOMRIGHT", 0, -2)
--hundredLabel:SetTextColor(1, 1, 1, 1)
--hundredLabel:SetText("100")

local function PerfFrame_BgOpacity_OnValueChanged(_, value)
    value = math.floor((tonumber(value) or 0) + 0.5)
    ApplyBackgroundOpacity(value)
    bgValue:SetText(tostring(value))
end
bgOpacitySlider.Slider:SetScript("OnValueChanged", PerfFrame_BgOpacity_OnValueChanged)
self._bgOpacityOnValueChanged = PerfFrame_BgOpacity_OnValueChanged

self._bgOpacitySlider = bgOpacitySlider
AttachTooltip({
    "Background Opacity",
    "Adds a background behind the text and controls its transparency.",
    "0 = no background, 100 = solid.",
}, bgOpacityRow.Label)

-- -----------------------------------------
-- 9) Reset Frame Position
-- -----------------------------------------
local resetRow = CreateRow(configurationFrame, bgOpacityRow, "Reset Position")
resetRow:SetHeight(resetRow:GetHeight() + 10) -- add a buffer to avoid encroaching on the slider
local resetBtn = CreateFrame("Button", nil, resetRow, "UIPanelButtonTemplate")
resetBtn:SetPoint("LEFT", 230, 0)
resetBtn:SetSize(200, 26)
resetBtn:SetText("Reset Position")

if not StaticPopupDialogs["PERFFRAME_RESET_POSITION"] then
    StaticPopupDialogs["PERFFRAME_RESET_POSITION"] = {
        text = "Reset PerfFrame position to the default center location?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            local def = { point="CENTER", relativeTo="UIParent", relativePoint="CENTER", x=0, y=0 }
            PerfFrameCharDB = PerfFrameCharDB or {}
            if PerfFrameCharDB.useCustomPosition then
                local modeKey = (PerfFrame_GetModeKey and PerfFrame_GetModeKey()) or "ALL"
                PerfFrameCharDB.framePosByMode = PerfFrameCharDB.framePosByMode or {}
                PerfFrameCharDB.framePosByMode[modeKey] = def
                PerfFrameCharDB.framePos = def
            else
                PerfFrameDB.framePos = def
            end

            if PerfFrame_ApplySavedPosition then
                PerfFrame_ApplySavedPosition()
            elseif PerfFrame then
                PerfFrame:ClearAllPoints()
                PerfFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

resetBtn:SetScript("OnClick", function()
    StaticPopup_Show("PERFFRAME_RESET_POSITION")
end)

AttachTooltip({
    "Reset Position",
    "Resets the frame position to the default center point.",
}, resetRow.Label)

-- -----------------------------------------
-- Credits
-- -----------------------------------------
local creditsTitle = CreateOptionsTitle(contents, "Credits", resetRow)
local creditsFrame = CreateFrame("Frame", nil, contents, "ResizeLayoutFrame")
creditsFrame:SetPoint("LEFT")
creditsFrame:SetPoint("RIGHT")
creditsFrame:SetPoint("TOP", creditsTitle, "BOTTOM", 0, 0)
creditsFrame:SetHeight(120)

-- prevent intermittent no-scroll
if self._UpdatePerfFrameScrollRange then
    self._UpdatePerfFrameScrollRange(creditsFrame)
end

local creditsText = creditsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
creditsText:SetJustifyH("LEFT")
creditsText:SetPoint("TOPLEFT", 16, -8)
creditsText:SetPoint("RIGHT", -16, 0)
creditsText:SetText(
    "|cFFFFFFFFPerfFrame|r is a small, customizable and movable frame for FPS, latency, and more.\n\n" ..
    "Created by |cFFFFFFFFSawfty|r. Inspired by Pytilix's FPS-MS-Tracker.\n\n" ..
    "Thanks to TomCat for UI inspiration."
)

end)

-- -------------------------------------------------
-- Settings Registration
-- -------------------------------------------------
local function RegisterPanel(p)
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(p)
    else
        local category = Settings.RegisterCanvasLayoutCategory(p, p.name)
        Settings.RegisterAddOnCategory(category)
        p._settingsCategory = category
    end
end

Home.name = "PerfFrame"
RegisterPanel(Home)

function PerfFrame_OpenOptions()
    if Settings and Settings.OpenToCategory and Home._settingsCategory then
        Settings.OpenToCategory(Home._settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(Home)
        InterfaceOptionsFrame_OpenToCategory(Home)
    else
        -- Last-resort fallback: just show a message
        print("PerfFrame: Open Settings -> AddOns -> PerfFrame")
    end
end