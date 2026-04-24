return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = { "java" },
    })

    require("nvim-treesitter-textobjects").setup({
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
    })

    local move = require("nvim-treesitter-textobjects.move")

    local function in_comment()
      local node = vim.treesitter.get_node()
      while node do
        if node:type():match("comment") then return true end
        node = node:parent()
      end
      return false
    end

    local function goto_skip_comments(fn)
      return function()
        for _ = 1, 20 do
          fn()
          if not in_comment() then break end
        end
      end
    end

    vim.keymap.set("n", "]m", goto_skip_comments(function() move.goto_next_start("@function.outer", "textobjects") end), { desc = "Next method start" })
    vim.keymap.set("n", "]M", goto_skip_comments(function() move.goto_next_end("@function.outer", "textobjects") end), { desc = "Next method end" })
    vim.keymap.set("n", "[m", goto_skip_comments(function() move.goto_previous_start("@function.outer", "textobjects") end), { desc = "Prev method start" })
    vim.keymap.set("n", "[M", goto_skip_comments(function() move.goto_previous_end("@function.outer", "textobjects") end), { desc = "Prev method end" })
    vim.keymap.set("n", "]]", goto_skip_comments(function() move.goto_next_start("@class.outer", "textobjects") end), { desc = "Next class start" })
    vim.keymap.set("n", "[[", goto_skip_comments(function() move.goto_previous_start("@class.outer", "textobjects") end), { desc = "Prev class start" })
    local function goto_current_block_edge(to_end)
      return function()
        local bufnr = vim.api.nvim_get_current_buf()
        local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
        if not lang then return end
        local query = vim.treesitter.query.get(lang, "textobjects")
        if not query then return end
        local tree = vim.treesitter.get_parser(bufnr, lang):parse()[1]
        local cursor = vim.api.nvim_win_get_cursor(0)
        local cur_row, cur_col = cursor[1] - 1, cursor[2]
        local best, best_size = nil, math.huge
        for id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
          if query.captures[id] == "block.outer" then
            local sr, sc, er, ec = node:range()
            local contains = (sr < cur_row or (sr == cur_row and sc <= cur_col))
                          and (er > cur_row or (er == cur_row and ec >= cur_col))
            if contains then
              local size = (er - sr) * 10000 + (ec - sc)
              if size < best_size then best_size, best = size, node end
            end
          end
        end
        if best then
          local row, col
          if to_end then
            row, col = best:end_()
            col = math.max(0, col - 1)
          else
            row, col = best:start()
          end
          vim.api.nvim_win_set_cursor(0, { row + 1, col })
        end
      end
    end

    vim.keymap.set("n", "[b", goto_current_block_edge(false), { desc = "Current block start" })
    vim.keymap.set("n", "]b", goto_current_block_edge(true), { desc = "Current block end" })
  end,
}
