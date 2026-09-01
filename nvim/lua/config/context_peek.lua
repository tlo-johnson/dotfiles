-- Transient version of nvim-treesitter-context: shows the enclosing
-- scope headers (function/class/if/for/.../) in a floating window on
-- demand instead of pinning them to the top of the buffer permanently.
local M = {}

local context_types = {
  function_declaration = true,
  function_definition = true,
  method_declaration = true,
  arrow_function = true,
  class_declaration = true,
  class_specifier = true,
  class_definition = true,
  interface_declaration = true,
  namespace_declaration = true,
  if_statement = true,
  for_statement = true,
  for_each_statement = true,
  for_in_statement = true,
  while_statement = true,
  do_statement = true,
  switch_statement = true,
  try_statement = true,
}

local peek_win = nil

local function close_peek()
  if peek_win and vim.api.nvim_win_is_valid(peek_win) then
    vim.api.nvim_win_close(peek_win, true)
  end
  peek_win = nil
end

local function header_line(bufnr, node)
  local row = node:start()
  local text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  return row, (text:gsub("^%s+", ""))
end

function M.toggle()
  if peek_win and vim.api.nvim_win_is_valid(peek_win) then
    close_peek()
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    vim.notify("context-peek: no treesitter parser for this buffer", vim.log.levels.WARN)
    return
  end
  -- get_node() returns nil on a buffer that's never been parsed yet
  -- (nothing else in this config calls treesitter.start()), so force it.
  parser:parse()

  local node = vim.treesitter.get_node({ bufnr = bufnr })
  if not node then
    vim.notify("context-peek: no node at cursor", vim.log.levels.INFO)
    return
  end

  local seen, lines = {}, {}
  node = node:parent()
  while node do
    if context_types[node:type()] then
      local row, text = header_line(bufnr, node)
      if row < cur_row and not seen[row] and text ~= "" then
        seen[row] = true
        table.insert(lines, 1, text)
      end
    end
    node = node:parent()
  end

  if #lines == 0 then
    vim.notify("context-peek: no enclosing context", vim.log.levels.INFO)
    return
  end

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width, vim.api.nvim_win_get_width(0) - 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = vim.bo[bufnr].filetype
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  peek_win = vim.api.nvim_open_win(buf, false, {
    relative = "win",
    row = 0,
    col = 0,
    width = width,
    height = #lines,
    style = "minimal",
    focusable = false,
    zindex = 45,
  })

  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinLeave" },
    { once = true, callback = close_peek }
  )
end

function M.setup()
  vim.keymap.set("n", "grc", M.toggle, { desc = "Peek enclosing context" })
  vim.keymap.set("n", "<Esc>", function()
    if peek_win and vim.api.nvim_win_is_valid(peek_win) then
      close_peek()
    end
  end, { desc = "Close context peek" })
end

return M
