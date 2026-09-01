-- installs lsp servers
local mason = {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = { "ktlint" },
  },
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
  config = function()
    vim.lsp.config("csharp_ls", {
      cmd_env = {
        DOTNET_ROOT = "/opt/homebrew/opt/dotnet/libexec",
        PATH = "/opt/homebrew/opt/dotnet/bin:" .. vim.env.PATH,
      },
    })
    vim.lsp.enable("csharp_ls")
  end,
}
