-- checkout https://www.lazyvim.org/extras/editor/telescope for inspiration

return {
  'nvim-telescope/telescope.nvim',
  -- tag = 'v0.1.9',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>e", "<cmd>Telescope find_files<cr>", desc = "Telescope find files" },
    { '<leader>g', "<cmd>Telescope live_grep<cr>", { desc = 'Telescope live grep' } },
    { '<leader>/', "<cmd>Telescope grep_string<cr>", { desc = 'Telescope grep string' } },
    { '<leader>b', "<cmd>Telescope buffers<cr>", { desc = 'Telescope buffers' } },
  },
  opts = {
    defaults = {
      layout_strategy = 'vertical',
    }
  }
}
