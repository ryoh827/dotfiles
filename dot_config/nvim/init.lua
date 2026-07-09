vim.g.mapleader = " "
vim.g.maplocalleader = " "

local options = {
  number = true,
  encoding = "utf-8",
  fileencoding = "utf-8",
  title = true,
  backup = false,
  clipboard = "unnamedplus",
  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,
  ignorecase = true,
  smartcase = true,
  incsearch = true,
  wrapscan = true,
  hlsearch = true,
  foldmethod = "expr",
  foldexpr = "v:lua.vim.treesitter.foldexpr()",
  foldlevel = 10,
  termguicolors = true,
  undofile = true,
  signcolumn = "yes",
  scrolloff = 8,
  updatetime = 250,
  splitright = true,
  splitbelow = true,
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

vim.g.copilot_filetypes = {
  markdown = false,
}
vim.g.markdown_recommended_style = 0

require("config.lazy")
vim.cmd[[colorscheme catppuccin]]

require("config.keymaps")
require("config.lsps")
require("config.autocmds")
