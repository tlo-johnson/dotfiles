require("config.lazy")

-- Keymaps
vim.keymap.set("n", "<leader>x", ":bdelete<cr>", opts)
vim.keymap.set("n", "<leader><leader>", "<c-^>", opts)

vim.keymap.set({"n", "v"}, "<leader>p", '"+p', opts)
vim.keymap.set({"n", "v"}, "<leader>P", '"+P', opts)
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', opts)

vim.keymap.set("n", "-", ":update<cr>", opts)
vim.keymap.set("n", "<c-h>", "<c-w>h", opts)
vim.keymap.set("n", "<c-t>", "<c-w>j", opts)
vim.keymap.set("n", "<c-n>", "<c-w>k", opts)
vim.keymap.set("n", "<c-s>", "<c-w>l", opts)

vim.keymap.set("t", "<c-h>", "<c-\\><c-n><c-w>h", opts)
vim.keymap.set("t", "<c-t>", "<c-\\><c-n><c-w>j", opts)
vim.keymap.set("t", "<c-n>", "<c-\\><c-n><c-w>k", opts)
vim.keymap.set("t", "<c-s>", "<c-\\><c-n><c-w>l", opts)
vim.keymap.set("t", "<c-d>", "<c-\\><c-n>", opts)


-- Transparent background
vim.cmd [[
  colorscheme catppuccin

  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
  highlight LineNr guibg=NONE ctermbg=NONE
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
]]--
