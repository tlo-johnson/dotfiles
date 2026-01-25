return {
  "stevearc/conform.nvim",
  opts = {
    -- format_on_save = {
    --   timeout_ms = 500,
    --   async = false,           -- not recommended to change
    --   quiet = false,           -- not recommended to change
    --   lsp_format = "fallback", -- not recommended to change
    -- },
    formatters_by_ft = {
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    }
  }
}
