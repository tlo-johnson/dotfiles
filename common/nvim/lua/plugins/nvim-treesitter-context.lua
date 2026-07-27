return {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    max_lines = 3,
    trim_scope = "outer",
  },
  config = function(_, opts)
    require("treesitter-context").setup(opts)

    -- Keep the sticky context line transparent, matching the rest of the UI.
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "TreesitterContextBottom", { bg = "NONE", underline = true })
        vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = "NONE" })
      end,
    })
    vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "TreesitterContextBottom", { bg = "NONE", underline = true })
    vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = "NONE" })
  end,
}
