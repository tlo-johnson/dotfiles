-- installs lsp servers
local mason = {
  "mason-org/mason.nvim",
  opts = { },
}

-- makes nvim-lspconfig aware of installed lsp servers
local masonLspConfig = {
  "mason-org/mason-lspconfig.nvim",
  opts = {
      ensure_installed = { "lua_ls" },
  },
  dependencies = mason,
}

-- integrates buffers with lsp servers
return {
  "neovim/nvim-lspconfig",
  dependencies = masonLspConfig,
}
