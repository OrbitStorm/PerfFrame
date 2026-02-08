-- =========================================
-- PerfFrame Localization (enUS base)
-- =========================================
local _, ns = ...
ns.L = ns.L or {}
local L = ns.L

-- Missing keys will fall back to the token name.
setmetatable(L, { __index = function(t, k) return k end })

-- Slash Commands
L.CMD_LIST_HEADER = "%s commands:"
L.CMD_OPEN_SETTINGS = "%s - Open settings panel"
L.CMD_RESET = "%s - Reset frame position"
L.ERR_FRAME_NOT_LOADED = "PerfFrame: frame not loaded yet."
L.ERR_OPEN_SETTINGS_FALLBACK = "PerfFrame: Open Settings -> AddOns -> PerfFrame"
L.ERR_UNKNOWN_COMMAND = "PerfFrame: unknown command. Type %s"
L.MSG_RESET_CENTER = "PerfFrame position reset to center."

-- Tooltip
L.TT_ADDON_MEMORY_TITLE = "AddOn Memory"
L.TT_ERR_TOOLTIP = "Tooltip error: %s"
L.TT_HOLD_SHIFT = "Hold Shift to show all."
L.TT_REPOSITION_HINT = "Hold %s to reposition."
L.TT_SETTINGS_HINT = "Type %s for settings."
L.TT_SHOWING_ALL = "Showing all %d addons."
L.TT_SHOWING_ALL_SHIFT = "Showing all %d addons (Shift)."
L.TT_SHOWING_ALL_TOP = "Showing all %d addons (Top %d)."
L.TT_SHOWING_TOP_OF = "Showing top %d of %d addons."
L.TT_TOTAL_ADDONS = "Total AddOns"

-- Options Panel
L.DD_ALL = "All"
L.DD_COMBAT_ALWAYS = "Always Show"
L.DD_COMBAT_IN_COMBAT = "Show Only in Combat"
L.DD_COMBAT_OUT_COMBAT = "Hide When in Combat"
L.DD_FRAMEINFO_ALL = "Show All"
L.DD_FRAMEINFO_FPS = "Show FPS Only"
L.DD_FRAMEINFO_MS = "Show MS Only"
L.DD_TEXTCOLORS_CLASS = "Class Colors"
L.DD_TEXTCOLORS_ONE = "Custom: One Color"
L.DD_TEXTCOLORS_SPLIT = "Custom: Separate (FPS/MS)"
L.DD_TOP10 = "Top 10"
L.DD_TOP20 = "Top 20"
L.DD_TOP5 = "Top 5"
L.OPT_ADDONMEMLIST_DESC1 = "Choose how many entries are shown in the AddOn memory tooltip list."
L.OPT_ADDONMEMLIST_DESC2 = "If your installed AddOn count is below the selected limit, all entries will be shown."
L.OPT_ADDONMEMLIST_DESC3 = "Hold Shift while hovering to show all entries."
L.OPT_ADDONMEMLIST_TITLE = "AddOn Memory List"
L.OPT_ADDONMEM_DESC = "When enabled, the tooltip will include an AddOn memory usage list."
L.OPT_ADDONMEM_TITLE = "Show Addon Memory"
L.OPT_BGOPACITY_DESC1 = "Adds a background behind the text and controls its transparency."
L.OPT_BGOPACITY_DESC2 = "0 = no background, 100 = solid."
L.OPT_BGOPACITY_TITLE = "Background Opacity"
L.OPT_COMBAT_DESC = "Controls when the frame is visible based on combat state."
L.OPT_COMBAT_TITLE = "Combat Toggle"
L.OPT_CUSTOMPOS_DESC = "When enabled, the frame position becomes specific to this character."
L.OPT_CUSTOMPOS_TITLE = "Use Custom Frame Position"
L.OPT_DISABLE_DESC = "Hides the PerfFrame display."
L.OPT_DISABLE_TITLE = "Disable PerfFrame"
L.OPT_FONTSCALE_DESC = "Adjust the size of the text in the frame."
L.OPT_FONTSCALE_TITLE = "Font Scale"
L.OPT_FPSCOLOR_DESC = "Used when Text Colors is set to Custom: Separate (FPS/MS)."
L.OPT_FPSCOLOR_TITLE = "FPS Color"
L.OPT_FRAMEINFO_DESC = "Choose what to show inside the frame (FPS, MS, or both)."
L.OPT_FRAMEINFO_TITLE = "Frame Information"
L.OPT_HEADER_CREDITS = "Credits"
L.OPT_HEADER_SETTINGS = "Settings"
L.OPT_HOVER_DESC = "When enabled, the frame is hidden until you hover your mouse over it."
L.OPT_HOVER_TITLE = "Hide Until Mouseover"
L.OPT_MSCOLOR_DESC = "Used when Text Colors is set to Custom: Separate (FPS/MS)."
L.OPT_MSCOLOR_TITLE = "MS Color"
L.OPT_RESET_CONFIRM = "Reset PerfFrame position to the default center location?"
L.OPT_RESET_DESC = "Resets the frame position to the default center point."
L.OPT_RESET_TITLE = "Reset Position"
L.OPT_TEXTCOLORS_DESC1 = "Choose how FPS/MS text is colored."
L.OPT_TEXTCOLORS_DESC2 = "Class Colors uses your class color (default)."
L.OPT_TEXTCOLORS_TITLE = "Text Colors"
L.OPT_TEXTCOLOR_DESC = "Used when Text Colors is set to Custom: One Color."
L.OPT_TEXTCOLOR_TITLE = "Text Color"
L.OPT_TIP_ACCESS = "%s You can access these settings quickly by using the %s command."
L.OPT_VERSION_FMT = "Version %s"

-- Misc
L.CREDITS_TEXT = [[%s is a lightweight frame that displays your FPS and latency,

     %s

Created by %s. Inspired by FPS-MS-Tracker.

Special thanks to %s for inspiration on the settings panel layout.]]
L.ERR_OPEN_SETTINGS_FALLBACK = "PerfFrame: Open Settings -> AddOns -> PerfFrame"
L.OPT_VERSION_FMT = "Version %s"
