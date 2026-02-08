-- =========================================
-- PerfFrame Options Panel
-- =========================================
local addonName, ns = ...
local L =
    (ns and ns.L) or
    setmetatable(
        {},
        {__index = function(t, k)
                return k
            end}
    )
local PF = ns.PF

local addonVersion =
    (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")) or
    (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or
    "unknown"

-- Helpers
local spacing = 20

-- Slider value highlight colors (use text defaults at runtime; gold matches label tone)
local VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B = 1, 0.82, 0
local function ShowTooltip(tooltip, frame, offsetX, offsetY)
    if not tooltip or not frame then
        return
    end
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
    if not frame or not tooltip then
        return
    end
    frame:EnableMouse(true)
    frame:SetScript(
        "OnEnter",
        function()
            ShowTooltip(tooltip, frame, offsetX, offsetY)
        end
    )
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
    if PerfFrame_RefreshDisplay then
        PerfFrame_RefreshDisplay()
    end
end

local function ApplyFontScale(scale)
    scale = tonumber(scale) or 1
    if scale < 0.5 then
        scale = 0.5
    end
    if scale > 2 then
        scale = 2
    end
    PerfFrameDB.fontSize = math.floor((12 * scale) + 0.5)
    PerfFrameDB.fontScale = nil

    if PerfFrame and PerfFrame.text and PerfFrame.text.GetFont then
        local font, _, flags = PerfFrame.text:GetFont()
        PerfFrame.text:SetFont(font, PerfFrameDB.fontSize, flags)
    end
    RefreshPerfFrameText()
end

local function GetFontScale()
    if PerfFrameDB.fontSize then
        return (PerfFrameDB.fontSize / 12)
    end
    return 1
end

local function ApplyBackgroundOpacity(value)
    value = tonumber(value) or 0
    if value < 0 then
        value = 0
    end
    if value > 100 then
        value = 100
    end
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

local function CreateColorSwatchButton(parentRow, getColorFunc, setColorFunc)
    local btn = CreateFrame("Button", nil, parentRow)
    btn:SetSize(22, 22)
    btn:SetPoint("LEFT", 230, 0)

    -- True-color fill with a subtle border (no dark overlay on the fill)
    btn.outline = btn:CreateTexture(nil, "BORDER")
    btn.outline:SetAllPoints()
    btn.outline:SetColorTexture(0, 0, 0, 0.9)

    btn.fill = btn:CreateTexture(nil, "ARTWORK")
    btn.fill:SetPoint("TOPLEFT", 1, -1)
    btn.fill:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.fill:SetColorTexture(1, 1, 1, 1)

    local function Clamp01(x)
        x = tonumber(x) or 0
        if x < 0 then
            return 0
        end
        if x > 1 then
            return 1
        end
        return x
    end

    local function UpdateSwatch()
        local c = getColorFunc()
        if type(c) == "table" then
            local r, g, b = Clamp01(c.r), Clamp01(c.g), Clamp01(c.b)
            btn.fill:SetColorTexture(r, g, b, 1)
        end
    end

    local function OpenPicker()
        -- Ensure the Blizzard color picker UI is available
        if not ColorPickerFrame then
            if C_AddOns and C_AddOns.LoadAddOn then
                pcall(C_AddOns.LoadAddOn, "Blizzard_ColorPicker")
            else
                pcall(LoadAddOn, "Blizzard_ColorPicker")
            end
        end
        if not ColorPickerFrame then
            return
        end

        local c = getColorFunc()
        local r, g, b = 1, 1, 1
        if type(c) == "table" then
            r, g, b = Clamp01(c.r), Clamp01(c.g), Clamp01(c.b)
        end

        local prev = {r = r, g = g, b = b}

        local function ApplyColor(nr, ng, nb)
            setColorFunc(Clamp01(nr), Clamp01(ng), Clamp01(nb))
            UpdateSwatch()
            if PerfFrame_UpdateTextColor then
                PerfFrame_UpdateTextColor()
            elseif PerfFrame_UpdateText then
                PerfFrame_UpdateText()
            end
        end

        if ColorPickerFrame.SetupColorPickerAndShow then
            local info = {
                r = r,
                g = g,
                b = b,
                hasOpacity = false,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    ApplyColor(nr, ng, nb)
                end,
                cancelFunc = function()
                    ApplyColor(prev.r, prev.g, prev.b)
                end
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            ColorPickerFrame.func = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                ApplyColor(nr, ng, nb)
            end
            ColorPickerFrame.cancelFunc = function()
                ApplyColor(prev.r, prev.g, prev.b)
            end
            if ColorPickerFrame.SetColorRGB then
                ColorPickerFrame:SetColorRGB(r, g, b)
            end
            ColorPickerFrame:Show()
        end
    end

    btn:SetScript("OnClick", OpenPicker)
    btn.UpdateSwatch = UpdateSwatch
    UpdateSwatch()

    return btn
end

-- =========================================
-- Options Canvas
-- =========================================
local Home = CreateFrame("Frame")
Home:Hide()

Home:SetScript(
    "OnHide",
    function(self)
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
    end
)

Home:SetScript(
    "OnShow",
    function(self)
        if self._built then
            -- Refresh dynamic states
            if self._disableCB then
                self._disableCB:SetChecked(PerfFrameDB.disabled and true or false)
            end
            if self._frameInfoPopout then
                local showFPS = PerfFrameDB.showFPS and true or false
                local showMS = PerfFrameDB.showMS and true or false
                local v = (showFPS and showMS) and "ALL" or (showFPS and "FPS") or (showMS and "MS") or "ALL"
                self._frameInfoPopout:SetSelectedValue(v)
            end
            if self._combatPopout then
                local v = PerfFrameDB.combatMode or "ALWAYS"
                self._combatPopout:SetSelectedValue(v)
            end
            if self._hideUntilHoverCB then
                self._hideUntilHoverCB:SetChecked(PerfFrameDB.hideUntilHover and true or false)
            end
            if self._addonMemCB then
                self._addonMemCB:SetChecked(PerfFrameDB.showAddonMemory and true or false)
            end
            if self._addonMemListPopout then
                local v = PerfFrameDB.addonMemoryListMode or "TOP5"
                self._addonMemListPopout:SetSelectedValue(v)
            end

            if self._textColorModePopout then
                local v = PerfFrameDB.textColorMode or "CLASS"
                self._textColorModePopout:SetSelectedValue(v)
            end
            if self._UpdateTextColorControls then
                self:_UpdateTextColorControls()
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
            logo:SetTexture("Interface\\AddOns\\PerfFrame\\assets\\icon64.tga", "CLAMP", "CLAMP", "TRILINEAR")
            -- keep the logo inside banner bounds
            logo:SetPoint("TOPRIGHT", -12, -4)
            logo:SetSize(54, 54)
            if logo.AddMaskTexture then
                logo:AddMaskTexture(mask)
            end

            local titleTemplate = _G["Game36Font_Shadow2"] and "Game36Font_Shadow2" or "GameFontNormalLarge"
            local title = boundingBox:CreateFontString(nil, "ARTWORK", titleTemplate)
            title:SetTextColor(GameFontNormal:GetTextColor())
            local PF_BRAND_TITLE = "|cffF59A23Perf|cff3FC7FFFrame|r"
            title:SetText(PF_BRAND_TITLE)
            title:SetPoint("BOTTOMLEFT", 29, 16)

            local version = boundingBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            version:SetText(string.format(L.OPT_VERSION_FMT, addonVersion))
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

        -- Helper to force a consistent scroll range once the full UI is built
        local function UpdateScrollRange(lastFrame)
            if not lastFrame or not lastFrame.GetBottom then
                return
            end
            local top = contents:GetTop()
            local bottom = lastFrame:GetBottom()
            if top and bottom then
                local h = (top - bottom) + 20
                if h < 1 then
                    h = 1
                end
                contents:SetHeight(h)
                boundingBox:SetHeight(h)
                scrollFrame:FullUpdate(true)
                scrollFrame:ScrollToBegin()
            end
        end
        self._UpdatePerfFrameScrollRange = UpdateScrollRange

        local configurationTitle = CreateOptionsTitle(contents, L.OPT_HEADER_SETTINGS, nil)
        local configurationFrame = CreateFrame("Frame", nil, contents, "ResizeLayoutFrame")
        configurationFrame:SetPoint("LEFT")
        configurationFrame:SetPoint("RIGHT")
        configurationFrame:SetPoint("TOP", configurationTitle, "BOTTOM", 0, 0)
        -- add a tip for users
        local tipFrame = CreateFrame("Frame", nil, configurationFrame)
        tipFrame:SetPoint("TOPLEFT")
        tipFrame:SetPoint("RIGHT")
        tipFrame:SetHeight(14)
        tipFrame.Label = tipFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tipFrame.Label:SetJustifyH("LEFT")
        tipFrame.Label:SetPoint("LEFT", 16, 0)
        tipFrame.Label:SetText(string.format(L.OPT_TIP_ACCESS, PF.TIP, PF.CMD_PF))

        -- row builder
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

        -- =========================================
        -- PerfFrame Visibility
        -- =========================================
        local disableRow = CreateRow(configurationFrame, nil, L.OPT_DISABLE_TITLE)
        local disableCB = CreateFrame("CheckButton", nil, disableRow, "UICheckButtonTemplate")
        disableCB:SetSize(30, 29)
        disableCB:SetPoint("LEFT", 230, 0)
        SkinMinimalCheckbox(disableCB)
        disableCB:SetScript(
            "OnClick",
            function(btn)
                local checked = btn:GetChecked() and true or false
                PerfFrameDB.disabled = checked
                if PerfFrame_SetDisabled then
                    PerfFrame_SetDisabled(checked)
                elseif PerfFrame_UpdateVisibility then
                    PerfFrame_UpdateVisibility()
                elseif PerfFrame then
                    if checked then
                        PerfFrame:Hide()
                    else
                        PerfFrame:Show()
                    end
                end
            end
        )
        disableCB:SetChecked(PerfFrameDB.disabled and true or false)
        self._disableCB = disableCB
        AttachTooltip(
            {
                L.OPT_DISABLE_TITLE,
                L.OPT_DISABLE_DESC
            },
            disableRow.Label
        )

        -- =========================================
        -- Frame Information
        -- =========================================
        local frameInfoRow = CreateRow(configurationFrame, disableRow, L.OPT_FRAMEINFO_TITLE)

        local function GetFrameInfoValue()
            local showFPS = PerfFrameDB.showFPS and true or false
            local showMS = PerfFrameDB.showMS and true or false
            if showFPS and showMS then
                return "ALL"
            end
            if showFPS then
                return "FPS"
            end
            if showMS then
                return "MS"
            end
            return "ALL"
        end

        local frameInfoPopout
        frameInfoPopout =
            PerfFrameTemplates.CreatePFPopout(
            frameInfoRow,
            {
                {label = L.DD_FRAMEINFO_ALL, value = "ALL", selected = GetFrameInfoValue() == "ALL"},
                {label = L.DD_FRAMEINFO_FPS, value = "FPS", selected = GetFrameInfoValue() == "FPS"},
                {label = L.DD_FRAMEINFO_MS, value = "MS", selected = GetFrameInfoValue() == "MS"}
            },
            function()
                local v = frameInfoPopout.selected.value
                if v == "FPS" then
                    PerfFrameDB.showFPS = true
                    PerfFrameDB.showMS = false
                elseif v == "MS" then
                    PerfFrameDB.showFPS = false
                    PerfFrameDB.showMS = true
                else
                    PerfFrameDB.showFPS = true
                    PerfFrameDB.showMS = true
                end
                RefreshPerfFrameText()
                if PerfFrameCharDB and PerfFrameCharDB.useCustomPosition and PerfFrame_ApplySavedPosition then
                    PerfFrame_ApplySavedPosition()
                end
            end
        )
        frameInfoPopout:SetPoint("LEFT", 230, 0)
        if frameInfoPopout.Popout and frameInfoPopout.Popout.Layout then
            frameInfoPopout.Popout:Layout()
        end
        self._frameInfoPopout = frameInfoPopout
        AttachTooltip(
            {
                L.OPT_FRAMEINFO_TITLE,
                L.OPT_FRAMEINFO_DESC
            },
            frameInfoRow.Label
        )

        function frameInfoPopout:SetSelectedValue(val)
            for idx, e in ipairs(self.entries or {}) do
                if e.value == val then
                    self:Select(idx)
                    break
                end
            end
        end

        -- =========================================
        -- Combat Toggles
        -- =========================================
        local combatRow = CreateRow(configurationFrame, frameInfoRow, L.OPT_COMBAT_TITLE)

        local function GetCombatModeValue()
            return PerfFrameDB.combatMode or "ALWAYS"
        end

        local combatPopout
        combatPopout =
            PerfFrameTemplates.CreatePFPopout(
            combatRow,
            {
                {label = L.DD_COMBAT_ALWAYS, value = "ALWAYS", selected = GetCombatModeValue() == "ALWAYS"},
                {label = L.DD_COMBAT_IN_COMBAT, value = "IN_COMBAT", selected = GetCombatModeValue() == "IN_COMBAT"},
                {
                    label = L.DD_COMBAT_OUT_COMBAT,
                    value = "OUT_OF_COMBAT",
                    selected = GetCombatModeValue() == "OUT_OF_COMBAT"
                }
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
        if combatPopout.Popout and combatPopout.Popout.Layout then
            combatPopout.Popout:Layout()
        end
        self._combatPopout = combatPopout
        AttachTooltip(
            {
                L.OPT_COMBAT_TITLE,
                L.OPT_COMBAT_DESC
            },
            combatRow.Label
        )

        function combatPopout:SetSelectedValue(val)
            for idx, e in ipairs(self.entries or {}) do
                if e.value == val then
                    self:Select(idx)
                    break
                end
            end
        end

        -- =========================================
        -- Hide Until Mouseover
        -- =========================================
        local hoverRow = CreateRow(configurationFrame, combatRow, L.OPT_HOVER_TITLE)
        local hoverCB = CreateFrame("CheckButton", nil, hoverRow, "UICheckButtonTemplate")
        hoverCB:SetSize(30, 29)
        hoverCB:SetPoint("LEFT", 230, 0)
        SkinMinimalCheckbox(hoverCB)
        hoverCB:SetScript(
            "OnClick",
            function(btn)
                PerfFrameDB.hideUntilHover = btn:GetChecked() and true or false
                if setupTooltip then
                    setupTooltip()
                end
            end
        )
        hoverCB:SetChecked(PerfFrameDB.hideUntilHover and true or false)
        self._hideUntilHoverCB = hoverCB
        AttachTooltip(
            {
                L.OPT_HOVER_TITLE,
                L.OPT_HOVER_DESC
            },
            hoverRow.Label
        )

        -- =========================================
        -- Show Addon Memory
        -- =========================================
        local addonMemRow = CreateRow(configurationFrame, hoverRow, L.OPT_ADDONMEM_TITLE)
        local addonMemCB = CreateFrame("CheckButton", nil, addonMemRow, "UICheckButtonTemplate")
        addonMemCB:SetSize(30, 29)
        addonMemCB:SetPoint("LEFT", 230, 0)
        SkinMinimalCheckbox(addonMemCB)
        addonMemCB:SetScript(
            "OnClick",
            function(btn)
                PerfFrameDB.showAddonMemory = btn:GetChecked() and true or false
                if PerfFrame_RefreshDisplay then
                    PerfFrame_RefreshDisplay()
                end
            end
        )
        addonMemCB:SetChecked(PerfFrameDB.showAddonMemory and true or false)
        self._addonMemCB = addonMemCB
        AttachTooltip(
            {
                L.OPT_ADDONMEM_TITLE,
                L.OPT_ADDONMEM_DESC
            },
            addonMemRow.Label
        )

        -- =========================================
        -- AddOn Memory List
        -- =========================================
        local addonMemListRow = CreateRow(configurationFrame, addonMemRow, L.OPT_ADDONMEMLIST_TITLE)

        local function GetAddonMemListValue()
            local v = PerfFrameDB.addonMemoryListMode or "TOP5"
            if v == "TOP5" or v == "TOP10" or v == "TOP20" or v == "ALL" then
                return v
            end
            return "TOP5"
        end

        local addonMemListPopout
        addonMemListPopout =
            PerfFrameTemplates.CreatePFPopout(
            addonMemListRow,
            {
                {label = L.DD_TOP5, value = "TOP5", selected = GetAddonMemListValue() == "TOP5"},
                {label = L.DD_TOP10, value = "TOP10", selected = GetAddonMemListValue() == "TOP10"},
                {label = L.DD_TOP20, value = "TOP20", selected = GetAddonMemListValue() == "TOP20"},
                {label = L.DD_ALL, value = "ALL", selected = GetAddonMemListValue() == "ALL"}
            },
            function()
                local v = addonMemListPopout.selected.value
                PerfFrameDB.addonMemoryListMode = v
                if PerfFrame_RefreshDisplay then
                    PerfFrame_RefreshDisplay()
                end
            end
        )
        addonMemListPopout:SetPoint("LEFT", 230, 0)
        if addonMemListPopout.Popout and addonMemListPopout.Popout.Layout then
            addonMemListPopout.Popout:Layout()
        end
        self._addonMemListPopout = addonMemListPopout
        AttachTooltip(
            {
                L.OPT_ADDONMEMLIST_TITLE,
                L.OPT_ADDONMEMLIST_DESC1,
                L.OPT_ADDONMEMLIST_DESC2,
                L.OPT_ADDONMEMLIST_DESC3
            },
            addonMemListRow.Label
        )

        -- =========================================
        -- Font Scaling
        -- =========================================
        local fontScaleRow = CreateRow(configurationFrame, addonMemListRow, L.OPT_FONTSCALE_TITLE)
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
            self._fontValueNormal = {nr, ng, nb}

            fontScaleSlider:HookScript(
                "OnEnter",
                function()
                    fontValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
                end
            )
            fontScaleSlider:HookScript(
                "OnLeave",
                function()
                    fontValue:SetTextColor(nr, ng, nb)
                end
            )

            if fontScaleSlider.Slider and fontScaleSlider.Slider.HookScript then
                fontScaleSlider.Slider:HookScript(
                    "OnMouseDown",
                    function()
                        fontValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
                    end
                )
                fontScaleSlider.Slider:HookScript(
                    "OnMouseUp",
                    function()
                        fontValue:SetTextColor(nr, ng, nb)
                    end
                )
            end
        end

        local function PerfFrame_FontScale_OnValueChanged(_, value)
            ApplyFontScale(value)
            fontValue:SetText(tostring(PerfFrameDB.fontSize or math.floor((12 * GetFontScale()) + 0.5)))
        end
        fontScaleSlider.Slider:SetScript("OnValueChanged", PerfFrame_FontScale_OnValueChanged)
        self._fontScaleOnValueChanged = PerfFrame_FontScale_OnValueChanged

        self._fontScaleSlider = fontScaleSlider
        AttachTooltip(
            {
                L.OPT_FONTSCALE_TITLE,
                L.OPT_FONTSCALE_DESC
            },
            fontScaleRow.Label
        )

        -- =========================================
        -- Background Opacity
        -- =========================================
        local bgOpacityRow = CreateRow(configurationFrame, fontScaleRow, L.OPT_BGOPACITY_TITLE)
        self._bgOpacityRow = bgOpacityRow
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
            self._bgValueNormal = {nr, ng, nb}

            bgOpacitySlider:HookScript(
                "OnEnter",
                function()
                    bgValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
                end
            )
            bgOpacitySlider:HookScript(
                "OnLeave",
                function()
                    bgValue:SetTextColor(nr, ng, nb)
                end
            )

            if bgOpacitySlider.Slider and bgOpacitySlider.Slider.HookScript then
                bgOpacitySlider.Slider:HookScript(
                    "OnMouseDown",
                    function()
                        bgValue:SetTextColor(VALUE_GOLD_R, VALUE_GOLD_G, VALUE_GOLD_B)
                    end
                )
                bgOpacitySlider.Slider:HookScript(
                    "OnMouseUp",
                    function()
                        bgValue:SetTextColor(nr, ng, nb)
                    end
                )
            end
        end

        local function PerfFrame_BgOpacity_OnValueChanged(_, value)
            value = math.floor((tonumber(value) or 0) + 0.5)
            ApplyBackgroundOpacity(value)
            bgValue:SetText(tostring(value))
        end
        bgOpacitySlider.Slider:SetScript("OnValueChanged", PerfFrame_BgOpacity_OnValueChanged)
        self._bgOpacityOnValueChanged = PerfFrame_BgOpacity_OnValueChanged

        self._bgOpacitySlider = bgOpacitySlider
        AttachTooltip(
            {
                L.OPT_BGOPACITY_TITLE,
                L.OPT_BGOPACITY_DESC1,
                L.OPT_BGOPACITY_DESC2
            },
            bgOpacityRow.Label
        )

        -- =========================================
        -- Text Colors
        -- =========================================
        local textColorsRow = CreateRow(configurationFrame, bgOpacityRow, L.OPT_TEXTCOLORS_TITLE)

        local function GetTextColorModeValue()
            local v = PerfFrameDB.textColorMode or "CLASS"
            if v == "CLASS" or v == "CUSTOM_BOTH" or v == "CUSTOM_SPLIT" then
                return v
            end
            return "CLASS"
        end

        local textColorModePopout
        textColorModePopout =
            PerfFrameTemplates.CreatePFPopout(
            textColorsRow,
            {
                {label = L.DD_TEXTCOLORS_CLASS, value = "CLASS", selected = GetTextColorModeValue() == "CLASS"},
                {
                    label = L.DD_TEXTCOLORS_ONE,
                    value = "CUSTOM_BOTH",
                    selected = GetTextColorModeValue() == "CUSTOM_BOTH"
                },
                {
                    label = L.DD_TEXTCOLORS_SPLIT,
                    value = "CUSTOM_SPLIT",
                    selected = GetTextColorModeValue() == "CUSTOM_SPLIT"
                }
            },
            function()
                local v = textColorModePopout.selected and textColorModePopout.selected.value or "CLASS"
                PerfFrameDB.textColorMode = v
                if PerfFrame_RefreshDisplay then
                    PerfFrame_RefreshDisplay()
                end
                if Home and Home._UpdateTextColorControls then
                    Home:_UpdateTextColorControls()
                end
            end
        )
        textColorModePopout:SetPoint("LEFT", 230, 0)
        self._textColorModePopout = textColorModePopout

        AttachTooltip(
            {
                L.OPT_TEXTCOLORS_TITLE,
                L.OPT_TEXTCOLORS_DESC1,
                L.OPT_TEXTCOLORS_DESC2
            },
            textColorsRow.Label
        )

        -- Custom: One Color
        local oneColorRow = CreateRow(configurationFrame, textColorsRow, L.OPT_TEXTCOLOR_TITLE)
        local oneColorBtn =
            CreateColorSwatchButton(
            oneColorRow,
            function()
                return PerfFrameDB.customTextColor
            end,
            function(r, g, b)
                PerfFrameDB.customTextColor = {r = r, g = g, b = b}
            end
        )
        self._oneColorBtn = oneColorBtn
        self._oneColorRow = oneColorRow
        AttachTooltip(
            {
                L.OPT_TEXTCOLOR_TITLE,
                L.OPT_TEXTCOLOR_DESC
            },
            oneColorRow.Label
        )

        -- Custom: Separate Colors
        local fpsColorRow = CreateRow(configurationFrame, oneColorRow, L.OPT_FPSCOLOR_TITLE)
        local fpsColorBtn =
            CreateColorSwatchButton(
            fpsColorRow,
            function()
                return PerfFrameDB.customFPSColor
            end,
            function(r, g, b)
                PerfFrameDB.customFPSColor = {r = r, g = g, b = b}
            end
        )
        self._fpsColorBtn = fpsColorBtn
        self._fpsColorRow = fpsColorRow
        AttachTooltip(
            {
                L.OPT_FPSCOLOR_TITLE,
                L.OPT_FPSCOLOR_DESC
            },
            fpsColorRow.Label
        )

        local msColorRow = CreateRow(configurationFrame, fpsColorRow, L.OPT_MSCOLOR_TITLE)
        local msColorBtn =
            CreateColorSwatchButton(
            msColorRow,
            function()
                return PerfFrameDB.customMSColor
            end,
            function(r, g, b)
                PerfFrameDB.customMSColor = {r = r, g = g, b = b}
            end
        )
        self._msColorBtn = msColorBtn
        self._msColorRow = msColorRow
        AttachTooltip(
            {
                L.OPT_MSCOLOR_TITLE,
                L.OPT_MSCOLOR_DESC
            },
            msColorRow.Label
        )

        -- enable/disable the relevant swatches without reflowing layout
        function Home:_UpdateTextColorControls()
            local mode = GetTextColorModeValue()

            -- show/hide rows based on selection
            if self._oneColorRow then
                self._oneColorRow:SetShown(mode == "CUSTOM_BOTH")
            end
            if self._fpsColorRow then
                self._fpsColorRow:SetShown(mode == "CUSTOM_SPLIT")
            end
            if self._msColorRow then
                self._msColorRow:SetShown(mode == "CUSTOM_SPLIT")
            end

            -- re-anchor the optional rows so spacing stays correct
            if self._oneColorRow then
                self._oneColorRow:ClearAllPoints()
                self._oneColorRow:SetPoint("TOPLEFT", textColorsRow, "BOTTOMLEFT", 0, -8)
                self._oneColorRow:SetPoint("RIGHT")
            end
            if self._fpsColorRow then
                self._fpsColorRow:ClearAllPoints()
                self._fpsColorRow:SetPoint("TOPLEFT", textColorsRow, "BOTTOMLEFT", 0, -8)
                self._fpsColorRow:SetPoint("RIGHT")
            end
            if self._msColorRow then
                self._msColorRow:ClearAllPoints()
                self._msColorRow:SetPoint("TOPLEFT", self._fpsColorRow, "BOTTOMLEFT", 0, -8)
                self._msColorRow:SetPoint("RIGHT")
            end

            -- re-anchor rows that follow Text Colors to the last visible row in the Text Colors block
            local lastRow = textColorsRow
            if mode == "CUSTOM_BOTH" and self._oneColorRow then
                lastRow = self._oneColorRow
            elseif mode == "CUSTOM_SPLIT" and self._msColorRow then
                lastRow = self._msColorRow
            end

            if self._customPosRow then
                self._customPosRow:ClearAllPoints()
                self._customPosRow:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -8)
                self._customPosRow:SetPoint("RIGHT")
            end

            -- enable/disable the relevant swatches again
            local function SetBtnEnabled(btn, enabled)
                if not btn then
                    return
                end
                if enabled then
                    btn:Enable()
                else
                    btn:Disable()
                end
                local a = enabled and 1 or 0.35
                btn:SetAlpha(a)
            end

            SetBtnEnabled(self._oneColorBtn, mode == "CUSTOM_BOTH")
            SetBtnEnabled(self._fpsColorBtn, mode == "CUSTOM_SPLIT")
            SetBtnEnabled(self._msColorBtn, mode == "CUSTOM_SPLIT")

            if self._oneColorBtn and self._oneColorBtn.UpdateSwatch then
                self._oneColorBtn:UpdateSwatch()
            end
            if self._fpsColorBtn and self._fpsColorBtn.UpdateSwatch then
                self._fpsColorBtn:UpdateSwatch()
            end
            if self._msColorBtn and self._msColorBtn.UpdateSwatch then
                self._msColorBtn:UpdateSwatch()
            end
        end

        local customPosRow = CreateRow(configurationFrame, textColorsRow, L.OPT_CUSTOMPOS_TITLE)
        self._customPosRow = customPosRow
        local useCustomCB = CreateFrame("CheckButton", nil, customPosRow, "UICheckButtonTemplate")
        useCustomCB:SetSize(30, 29)
        useCustomCB:SetPoint("LEFT", 230, 0)
        SkinMinimalCheckbox(useCustomCB)
        useCustomCB:SetScript(
            "OnClick",
            function(btn)
                PerfFrameCharDB = PerfFrameCharDB or {}
                local checked = btn:GetChecked() and true or false
                PerfFrameCharDB.useCustomPosition = checked

                if checked then
                    local modeKey = (PerfFrame_GetModeKey and PerfFrame_GetModeKey()) or "ALL"
                    PerfFrameCharDB.framePosByMode = PerfFrameCharDB.framePosByMode or {}

                    if not PerfFrameCharDB.framePosByMode[modeKey] then
                        PerfFrameDB.framePos =
                            PerfFrameDB.framePos or
                            {point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0}
                        local src = PerfFrameDB.framePos
                        PerfFrameCharDB.framePosByMode[modeKey] = {
                            point = src.point,
                            relativeTo = src.relativeTo,
                            relativePoint = src.relativePoint,
                            x = src.x,
                            y = src.y
                        }
                    end

                    -- legacy field
                    PerfFrameCharDB.framePos = PerfFrameCharDB.framePosByMode[modeKey]
                end

                if PerfFrame_ApplySavedPosition then
                    PerfFrame_ApplySavedPosition()
                end
            end
        )
        PerfFrameCharDB = PerfFrameCharDB or {}
        useCustomCB:SetChecked(PerfFrameCharDB.useCustomPosition and true or false)
        self._useCustomCB = useCustomCB
        AttachTooltip(
            {
                L.OPT_CUSTOMPOS_TITLE,
                L.OPT_CUSTOMPOS_DESC
            },
            customPosRow.Label
        )

        -- =========================================
        -- Reset Frame Position
        -- =========================================
        local resetRow = CreateRow(configurationFrame, customPosRow, L.OPT_RESET_TITLE)
        resetRow:SetHeight(resetRow:GetHeight() + 10) -- add a buffer to avoid encroaching on the slider
        local resetBtn = CreateFrame("Button", nil, resetRow, "UIPanelButtonTemplate")
        resetBtn:SetPoint("LEFT", 230, 0)
        resetBtn:SetSize(200, 26)
        resetBtn:SetText(L.OPT_RESET_TITLE)

        if not StaticPopupDialogs["PERFFRAME_RESET_POSITION"] then
            StaticPopupDialogs["PERFFRAME_RESET_POSITION"] = {
                text = L.OPT_RESET_CONFIRM,
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    local def = {point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0}
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
                preferredIndex = 3
            }
        end

        resetBtn:SetScript(
            "OnClick",
            function()
                StaticPopup_Show("PERFFRAME_RESET_POSITION")
            end
        )

        AttachTooltip(
            {
                L.OPT_RESET_TITLE,
                L.OPT_RESET_DESC
            },
            resetRow.Label
        )

        -- ensure Text Colors conditional rows are laid out correctly on first open/reload
        if self._UpdateTextColorControls then
            self:_UpdateTextColorControls()
        end

        -- =========================================
        -- Credits
        -- =========================================
        local creditsTitle = CreateOptionsTitle(contents, L.OPT_HEADER_CREDITS, resetRow)
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
        creditsText:SetText(string.format(L.CREDITS_TEXT, PF.ADDON .. PF.RESET, PF.TAGLINE, PF.AUTHOR, PF.TOMCAT))
    end
)

-- =========================================
-- Settings Registration
-- =========================================
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
        print(L.ERR_OPEN_SETTINGS_FALLBACK)
    end
end