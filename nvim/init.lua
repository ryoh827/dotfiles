vim.g.mapleader = " "
vim.g.maplocalleader = " "

local options = {
  number = true,
  encoding = "utf-8",
  fileencoding = "utf-8",
  title = true,
  backup = false,
  clipboard = "unnamedplus",
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

require("config.lazy")
vim.opt.termguicolors = true
vim.cmd 'colorscheme iceberg'
