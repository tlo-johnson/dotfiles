return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },            -- if you use the mini.nvim suite
  opts = {
    latex = {
      enabled = true,
      converter = 'latex2text' -- requires `brew install pipx && pipx install pylatexenc`
    }
  },
}
