require("config.lazy")

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
vim.opt.winborder = 'rounded'

local opts = { silent = true }

-- Keymaps
vim.keymap.set("n", "<leader>x", ":bdelete<cr>", opts)
vim.keymap.set("n", "<leader><leader>", "<c-^>", opts)

vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', opts)
vim.keymap.set({ "n", "v" }, "<leader>P", '"+P', opts)
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', opts)

vim.keymap.set("n", "-", ":update<cr>", opts)
-- vim.keymap.set("n", "<c-h>", "<c-w>h", opts)
-- vim.keymap.set("n", "<c-t>", "<c-w>j", opts)
-- vim.keymap.set("n", "<c-n>", "<c-w>k", opts)
-- vim.keymap.set("n", "<c-s>", "<c-w>l", opts)
vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>", opts)
vim.keymap.set("n", "<C-t>", ":TmuxNavigateDown<CR>", opts)
vim.keymap.set("n", "<C-n>", ":TmuxNavigateUp<CR>", opts)
vim.keymap.set("n", "<C-s>", ":TmuxNavigateRight<CR>", opts)

vim.keymap.set("t", "<c-h>", "<c-\\><c-n>:TmuxNavigateLeft<cr>", opts)
vim.keymap.set("t", "<c-t>", "<c-\\><c-n>:TmuxNavigateDown<cr>", opts)
vim.keymap.set("t", "<c-n>", "<c-\\><c-n>:TmuxNavigateUp<cr>", opts)
vim.keymap.set("t", "<c-s>", "<c-\\><c-n>:TmuxNavigateRight<cr>", opts)
vim.keymap.set("t", "<c-x>", "<c-\\><c-n>", opts)

-- Lsp Key Bindings
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    map('ga', vim.lsp.buf.code_action, "Code action")
    map('gd', vim.lsp.buf.definition, "Goto definition")
    map('gu', vim.lsp.buf.references, "Find references")
    map('g]', function()
      vim.diagnostic.jump({ count = 1 })
      vim.schedule(function()
        vim.diagnostic.open_float(nil, { focusable = false })
      end)
    end, "Next diagnostic")
    map('g[', function()
      vim.diagnostic.jump({ count = -1 })
      vim.schedule(function()
        vim.diagnostic.open_float(nil, { focusable = false })
      end)
    end, "Previous diagnostic")
  end,
})



-- Transparent background
vim.cmd [[
  colorscheme catppuccin

  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
  highlight LineNr guifg=#6c6c6c guibg=NONE ctermbg=NONE
  highlight Folded guibg=NONE ctermbg=NONE
  highlight NonText guibg=NONE ctermbg=NONE
  highlight SignColumn guibg=NONE ctermbg=NONE
  highlight VertSplit guibg=NONE ctermbg=NONE
]]

--[[
-- Packages

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
    vim.keymap.set('n', 'ga', function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })
    vim.keymap.set('n', 'gu', vim.lsp.buf.references, { buffer = bufnr })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
    vim.keymap.set('n', 'ge', vim.lsp.diagnostic.get_line_diagnostics, { buffer = bufnr })
    vim.keymap.set('n', 'g]', function()
      vim.diagnostic.jump({ count = 1 })
      vim.schedule(function()
        vim.diagnostic.open_float(nil, { focusable = false })
      end)
    end, { buffer = bufnr })
    vim.keymap.set('n', 'g[', function()
      vim.diagnostic.jump({ count = -1 })
      vim.schedule(function()
        vim.diagnostic.open_float(nil, { focusable = false })
      end)
    end, { buffer = bufnr })
  end
})
vim.lsp.enable('tsserver')
]] --
