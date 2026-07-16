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
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  {
    "glidenote/memolist.vim",
    config = function()
      vim.g.memolist_path = home_dir .. "/memo"
      vim.g.memolist_memo_suffix = "md"
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin",
        },
      })
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
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
    opts = {
      win = {
        col = 0.5,
        row = 0.5,
        width = 0.6,
        height = { min = 4, max = 25 },
        border = "rounded",
        title = true,
        title_pos = "center",
      },
      spec = {
        { "<leader>a", group = "AI/Claude" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Diagnostics" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "File/Format" },
        { "<leader>h", group = "Hunk" },
        { "<leader>m", group = "Memo/Toggle" },
        { "<leader>q", group = "Session" },
        { "<leader>r", group = "Rename" },
        { "<leader>s", group = "Search/Replace" },
        { "<leader>x", group = "Trouble" },
        { "<leader>y", group = "Yank" },
      },
    },
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
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'lua',
        'vim',
        'vimdoc',
        'bash',
        'json',
        'yaml',
        'toml',
        'markdown',
        'markdown_inline',
        'html',
        'css',
        'javascript',
        'typescript',
        'tsx',
        'go',
        'python',
        'ruby',
      })

      vim.treesitter.language.register('vimdoc', 'help')
      vim.treesitter.language.register('bash', { 'sh', 'zsh' })
      vim.treesitter.language.register('tsx', 'typescriptreact')

      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'lua',
          'vim',
          'help',
          'sh',
          'bash',
          'zsh',
          'json',
          'yaml',
          'toml',
          'markdown',
          'html',
          'css',
          'javascript',
          'typescript',
          'typescriptreact',
          'go',
          'python',
          'ruby',
        },
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
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
    "linrongbin16/gitlinker.nvim",
    cmd = "GitLink",
    opts = {},
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gs = require('gitsigns')
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.nav_hunk('next') end)
            return '<Ignore>'
          end, { expr = true, desc = 'Next hunk' })
          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.nav_hunk('prev') end)
            return '<Ignore>'
          end, { expr = true, desc = 'Previous hunk' })
          map('n', '<leader>hs', gs.stage_hunk, { desc = 'Stage hunk' })
          map('n', '<leader>hr', gs.reset_hunk, { desc = 'Reset hunk' })
          map('v', '<leader>hs', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, { desc = 'Stage hunk' })
          map('v', '<leader>hr', function() gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, { desc = 'Reset hunk' })
          map('n', '<leader>hS', gs.stage_buffer, { desc = 'Stage buffer' })
          map('n', '<leader>hR', gs.reset_buffer, { desc = 'Reset buffer' })
          map('n', '<leader>hp', gs.preview_hunk, { desc = 'Preview hunk' })
          map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, { desc = 'Blame line' })
          map('n', '<leader>hd', gs.diffthis, { desc = 'Diff this' })
        end,
      })
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
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = { flavour = "latte" } },
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
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure()
    end,
  },
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        split_width_percentage = 0.5,
      },
      diff_opts = {
        layout = "horizontal",
      },
    },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
      },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
}
