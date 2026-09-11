-- checkout https://www.lazyvim.org/extras/editor/telescope for inspiration

return {
  'nvim-telescope/telescope.nvim',
  -- tag = 'v0.1.9',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope-ui-select.nvim' },
  keys = {
    { "<leader>e", "<cmd>Telescope find_files<cr>",  desc = "Telescope find files" },
    { '<leader>g', "<cmd>Telescope live_grep<cr>",   { desc = 'Telescope live grep' } },
    { '<leader>/', "<cmd>Telescope grep_string<cr>", { desc = 'Telescope grep string' } },
    { '<leader>b', "<cmd>Telescope buffers<cr>",     { desc = 'Telescope buffers' } },
  },
  opts = function()
    return {
      defaults = {
        layout_strategy = 'vertical',
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    }
  end,
  config = function(_, opts)
    local actions = require 'telescope.actions'

    -- https://github.com/MagicDuck/grug-far.nvim/pull/305
    local is_windows = vim.fn.has('win64') == 1 or vim.fn.has('win32') == 1
    local vimfnameescape = vim.fn.fnameescape
    local winfnameescape = function(path)
      local escaped_path = vimfnameescape(path)
      if is_windows then
        local need_extra_esc = path:find('[%[%]`%$~]')
        local esc = need_extra_esc and '\\\\' or '\\'
        escaped_path = escaped_path:gsub('\\[%(%)%^&;]', esc .. '%1')
        if need_extra_esc then
          escaped_path = escaped_path:gsub("\\\\['` ]", '\\%1')
        end
      end
      return escaped_path
    end

    local select_default = function(prompt_bufnr)
      vim.fn.fnameescape = winfnameescape
      local result = actions.select_default(prompt_bufnr, "default")
      vim.fn.fnameescape = vimfnameescape
      return result
    end

    opts.defaults = vim.tbl_deep_extend('force', opts.defaults or {}, {
      mappings = {
        i = { ['<cr>'] = select_default },
        n = { ['<cr>'] = select_default },
      },
    })

    require("telescope").setup(opts)
    require("telescope").load_extension("ui-select")
  end,
}
