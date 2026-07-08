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
    vim.api.nvim_create_user_command("LspRestart", function(opts)
      local name = opts.args ~= "" and opts.args or nil
      local clients = name and vim.lsp.get_clients({ name = name }) or vim.lsp.get_clients()

      for _, client in ipairs(clients) do
        client.stop()
      end

      vim.defer_fn(function()
        vim.cmd("edit")
      end, 200)
    end, {
      nargs = "?",
      complete = function()
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients()) do
          table.insert(names, client.name)
        end
        return names
      end,
    })
  end,
}
