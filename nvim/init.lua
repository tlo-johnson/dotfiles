vim.g.mapleader = " "

-- Keymaps
vim.keymap.set("n", "<leader>x", ":bdelete<cr>", opts)
vim.keymap.set("n", "<leader><leader>", "<c-^>", opts)

vim.keymap.set({"n", "v"}, "<leader>p", '"+p', opts)
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', opts)

vim.keymap.set("n", "-", ":update<cr>", opts)
vim.keymap.set("n", "<c-h>", "<c-w>h", opts)
vim.keymap.set("n", "<c-t>", "<c-w>j", opts)
vim.keymap.set("n", "<c-n>", "<c-w>k", opts)
vim.keymap.set("n", "<c-s>", "<c-w>l", opts)
vim.keymap.set("n", "n", "nzz", opts)

vim.keymap.set("t", "<c-h>", "<c-\\><c-n><c-w>h", opts)
vim.keymap.set("t", "<c-t>", "<c-\\><c-n><c-w>j", opts)
vim.keymap.set("t", "<c-n>", "<c-\\><c-n><c-w>k", opts)
vim.keymap.set("t", "<c-s>", "<c-\\><c-n><c-w>l", opts)
vim.keymap.set("t", "<c-d>", "<c-\\><c-n>", opts)

-- Settings
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.swapfile = false
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'
vim.opt.undofile = true
vim.opt.list = true
vim.opt.listchars = "trail:·,tab:·┈"
vim.opt.hlsearch = false

-- Transparent background
vim.cmd [[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
  highlight LineNr guibg=NONE ctermbg=NONE
  highlight Folded guibg=NONE ctermbg=NONE
  highlight NonText guibg=NONE ctermbg=NONE
  highlight SignColumn guibg=NONE ctermbg=NONE
  highlight VertSplit guibg=NONE ctermbg=NONE
]]

-- Packages

-- Telescope
vim.pack.add({ 'https://github.com/nvim-lua/plenary.nvim' })
vim.pack.add({ 'https://github.com/nvim-telescope/telescope.nvim' })
require('telescope').setup({
  defaults = {
    layout_strategy = 'vertical',
  },
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>e', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>/', builtin.grep_string, { desc = 'Telescope grep string' })
vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Telescope buffers' })

-- LSP
-- Typescript
vim.lsp.config('tsserver', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_dir = vim.fs.dirname(vim.fs.find({ 'package.json', 'tsconfig.json', '.git' }, { upward = true })[1]) or vim.uv.cwd(),
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })
    vim.keymap.set('n', 'gu', vim.lsp.buf.references, { buffer = bufnr })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
    vim.keymap.set('n', 'ge', vim.lsp.diagnostic.get_line_diagnostics, { buffer = bufnr })
    vim.keymap.set('n', 'g]', function() vim.diagnostic.jump({ count = 1 }) end, { buffer = bufnr })
    vim.keymap.set('n', 'g[', function() vim.diagnostic.jump({ count = -1 }) end, { buffer = bufnr })
  end
})
vim.lsp.enable('tsserver')

-- Java
vim.pack.add({ 'https://github.com/mfussenegger/nvim-jdtls' })
