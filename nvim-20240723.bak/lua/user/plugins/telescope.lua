return {
  'nvim-telescope/telescope.nvim',
  opts = function(_, opts)
    opts.pickers = {
      find_files = {
        find_command = {
          'rg',
          '--hidden',
          '--files',
          '--ignore',
          '-u'
        }
      },
    }
    opts.defaults.file_ignore_patterns = { "node_modules" }
  end
 }
