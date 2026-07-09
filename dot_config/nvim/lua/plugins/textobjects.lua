return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      local function sel(key, obj, desc)
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(obj, "textobjects")
        end, { desc = desc })
      end

      sel("af", "@function.outer", "Function (outer)")
      sel("if", "@function.inner", "Function (inner)")
      sel("ac", "@class.outer", "Class (outer)")
      sel("ic", "@class.inner", "Class (inner)")
      sel("aa", "@parameter.outer", "Parameter (outer)")
      sel("ia", "@parameter.inner", "Parameter (inner)")

      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous function start" })
      vim.keymap.set({ "n", "x", "o" }, "]]", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class start" })
      vim.keymap.set({ "n", "x", "o" }, "[[", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class start" })
    end,
  },
}
