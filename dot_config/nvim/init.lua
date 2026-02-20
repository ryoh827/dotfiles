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
  foldmethod = "indent",
  foldlevel = 10,
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

vim.g.copilot_filetypes = {
  markdown = false,
}
vim.g.markdown_recommended_style = 0

require("config.autocmds")

require("config.lazy")
-- vim.opt.termguicolors = true
vim.cmd[[colorscheme dracula]]


local home_dir = os.getenv("HOME")
package.path = home_dir .. '/.config/nvim/' .. package.path

require("keymaps")
require("lsps")

