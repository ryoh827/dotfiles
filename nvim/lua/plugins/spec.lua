return {
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
  },
  { "glidenote/memolist.vim" },
  { "vim-airline/vim-airline" },
  { "vim-airline/vim-airline-themes" },
  { 'preservim/nerdtree' },
  { 'easymotion/vim-easymotion' },
  { "Mofiqul/dracula.nvim" },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = {{"echasnovski/mini.icons", opts = {}}},
    config = function()
      require('oil').setup({
        view_options = {
          show_hidden = true,
        }
      })
    end,
  },
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("bufferline").setup{}
    end,
  },
  {
   "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {{
      "<leader>?",
      function() require("which-key").show({global = false}) end,
      desc = "Buffer Local Keymaps (which-key)",
    }},
  },
  {"neovim/nvim-lspconfig"},
  {'github/copilot.vim'},
  {'tpope/vim-endwise'},
  {
    'Wansmer/treesj',
    dependencies = { 'nvim-treesitter/nvim-treesitter' }, 
    config = function()
      require('treesj').setup({
        use_default_keymaps = false
      })
    end,
  },
  {'monaqa/dial.nvim'},
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("hlchunk").setup({
        indent = {
          enable = true
        }
      })
    end
  },
  {
    'numToStr/Comment.nvim',
    opts = {
        -- add any options here
    },
    config = function()
        require('Comment').setup()
    end
  }
}
