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
  end,
}
