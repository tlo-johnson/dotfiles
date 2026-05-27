local utils = require("utils")

local configModal = utils.createModal("F16", "Config")

configModal:bind({}, "z", function()
  configModal:exit()
  hs.reload()
end)
