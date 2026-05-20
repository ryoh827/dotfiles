return {
  {
    'nvim-telescope/telescope.nvim', branch = 'master',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          }
        }
      })
    end,
  },
  {
    "smartpde/telescope-recent-files"
  }
}
