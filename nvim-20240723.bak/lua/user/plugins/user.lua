return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  {
    "itchyny/vim-qfedit",
    event = "VeryLazy"
  },
  {
    "ruanyl/vim-gh-line",
    event = "VeryLazy",
  },
  {
    "kamykn/spelunker.vim",
    event = "VeryLazy",
  },
  {
    "wakatime/vim-wakatime",
    event = "VeryLazy",
  },
  {
    "skanehira/preview-markdown.vim",
    event = "VeryLazy",
  },
  {
    "chrisbra/csv.vim",
    event = "VeryLazy",
  }
}
