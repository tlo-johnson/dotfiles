return {
  "saghen/blink.cmp",
  version = "*",
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    appearance = {
      use_nvim_cmp_as_default = false,
      nerd_font_variant = "mono",
    },
    completion = {
      menu = {
        auto_show = false,
      },
      accept = {
        auto_brackets = { enabled = true }, -- auto-insert () after function/method
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      ghost_text = { enabled = false }, -- set true if you want ghost text
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    keymap = {
      preset = "enter", -- Enter to confirm
      ["<C-p>"] = { "show" },
    },
  },
}
