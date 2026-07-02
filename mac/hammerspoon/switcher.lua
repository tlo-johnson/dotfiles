local projects = require("projects")
local tabs     = require("tabs")

hs.hotkey.bind({}, "F18", projects.show)
hs.hotkey.bind({}, "F19", tabs.showTabChooser)
