local utils    = require("utils")
local projects = require("projects")
local tabs     = require("tabs")

local switcher = utils.createModal("F18", "Projects / Tabs")

switcher:bind({}, "p", function()
  switcher:exit()
  projects.show()
end)

switcher:bind({}, ".", function()
  switcher:exit()
  tabs.showTabChooser()
end)

return switcher
