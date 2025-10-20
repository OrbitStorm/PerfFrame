# PerfFrame

PerfFrame is a lightweight addon that keeps your FPS and latency visible at all times. It provides a simple, movable display for performance stats, so you don’t need to hover over the default UI to check your frame rate or connection.

Inspired by [Pytilix’s](https://www.curseforge.com/members/pytilix/projects) [FPS-MS-Tracker](https://www.curseforge.com/wow/addons/fps-ms-tracker), PerfFrame has been fully rewritten with persistent settings, accessibility options, quality-of-life updates, and an in-game configuration panel.

### Features
* Real-time FPS and latency tracking
* Optional clock and mail indicators
* Optional tooltip showing addon memory and network stats
* Adjustable text scale for better readability
* Movable frame with saved position between sessions
* Slash commands for quick adjustments (/perf)
* Interface Options panel for easy configuration
* Lightweight and unobtrusive design


### Accessibility

PerfFrame includes multiple text-scale options to improve visibility on any display. Whether you play on a laptop or a high-resolution monitor, your performance data remains clear and easy to read. Choose from three options: Normal (100%), Bigger (125%), and Biggest (150%).

### Installation
* Extract the PerfFrame folder into:
  World of Warcraft/_retail_/Interface/AddOns/
* Enable PerfFrame in the AddOns menu.
* Type /perf help in-game for a list of available commands.

### Moving PerfFrame
Hold ALT + left-click and drag. It's that simple!

### Slash Commands /perf or /PerfFrame
* /perf help - prints a list of available commands
* /perf reset - resets the panel to the default position
* /perf show fps - shows just FPS on the panel
* /perf show ms - shows just latency (MS) on the panel
* /perf show both - shows FPS and MS (default)
* /perf text [normal|bigger|biggest] - adjusts text scaling from 100% to 125% and 150%
* /perf tooltip on/off - toggle's the optional addon and network stats tooltip on hover
* /perf clock on/off/12h/24h - toggles the optional clock display on the panel on or off, as well as toggles between 12h and 24h formats
* /perf mail on/off - togglesd an optional mail icon on the display for unread mail

PerfFrame also has a fully functional settings page available through Options → Addons → PerfFrame
