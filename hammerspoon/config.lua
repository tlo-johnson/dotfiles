local utils = require("utils")

local configModal = hs.hotkey.modal.new({}, "F16")

function configModal:entered()
  utils.showAlert("Config")
end

function configModal:exited()
  utils.hideAlert()
end

configModal:bind({}, "z", function()
  configModal:exit()
  hs.reload()
end)

configModal:bind({}, "escape", function()
  configModal:exit()
end)
