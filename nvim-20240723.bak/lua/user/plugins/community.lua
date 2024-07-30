return {
  -- Add the community repository of plugin specifications
  "AstroNvim/astrocommunity",
  -- example of importing a plugin, comment out to use it or add your own
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity

  -- { import = "astrocommunity.colorscheme.catppuccin" },
  -- { import = "astrocommunity.completion.copilot-lua-cmp" },
  { import = "astrocommunity.colorscheme.nightfox-nvim" },
  { import = "astrocommunity.completion.copilot-lua" },
  { import = 'astrocommunity.editing-support.nvim-treesitter-endwise' },
  { import = 'astrocommunity.motion.mini-surround' },
  { import = 'astrocommunity.git.git-blame-nvim' },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        keymap = {
          accept = "<C-l>",
          next = "<C-.>",
          prev = "<C-,>",
        }
      }
    }
  },
  { import = 'astrocommunity.motion.hop-nvim' }
}
