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
    "cocopon/iceberg.vim"
  },
  {
    "vim-airline/vim-airline"
  },
  {
    "vim-airline/vim-airline-themes"
  },
  {
    'preservim/nerdtree',
  },
  {
    'easymotion/vim-easymotion',
  },
}
