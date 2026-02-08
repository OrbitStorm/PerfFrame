local addonName, ns = ...

-- =========================================
-- PerfFrame Formatted Tokens (avoids translation errors)
-- Keep color codes out of locale strings; inject via %s placeholders.
-- =========================================

ns.PF = ns.PF or {}
local PF = ns.PF

PF.TIP         = PF.TIP         or "|cFFFF0000TIP:|r"
PF.CMD_PF      = PF.CMD_PF      or "|cffffd200/pf|r"
PF.CMD_PF_HELP = PF.CMD_PF_HELP or "|cffffd200/pf help|r"
PF.CMD_PF_RESET= PF.CMD_PF_RESET or "|cffffd200/pf reset|r"

PF.ALT_DRAG    = PF.ALT_DRAG    or "|cffffd200ALT + Drag|r"
PF.SHIFT       = PF.SHIFT       or "|cffffd200Shift|r"

PF.ADDON       = PF.ADDON       or "|cFFFFFFFFPerfFrame|r"
PF.AUTHOR      = PF.AUTHOR      or "|cFFFFFFFFSawfty|r"
PF.TOMCAT      = PF.TOMCAT      or "|cFF8C1010TomCat|r"
PF.TAGLINE     = PF.TAGLINE     or "|cFFD8B36Aso you can blame lag with confidence.|r"