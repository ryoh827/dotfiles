local home_dir = os.getenv("HOME")

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
  {
    "glidenote/memolist.vim",
    config = function()
      vim.g.memolist_path = home_dir .. "/memo"
      vim.g.memolist_memo_suffix = "md"
    end
  },
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
        },
        delete_to_trash = false,
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
  },
  {
    'goolord/alpha-nvim',
    config = function ()
        require'alpha'.setup(require'config.dashboard'.config)
    end
  },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "williamboman/mason.nvim",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "eslint",
          "jsonls",
          "html",
          "cssls",
          "gopls",
          "basedpyright",
          "ruby_lsp",
        },
        automatic_enable = true,
      })
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
  },
  {
    "navarasu/onedark.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('onedark').setup {
        style = 'darker'
      }
      -- Enable theme
      require('onedark').load()
    end
  }
}
