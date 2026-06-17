local lspconfig = require('lspconfig')

--require'lspconfig'.ruby_lsp.setup{}
--require'lspconfig'.gopls.setup{}
--require'lspconfig'.denols.setup{}

require("mason").setup()
require("mason-lspconfig").setup()

-- Wire blink.cmp completion capabilities into all LSP servers.
local ok, blink = pcall(require, 'blink.cmp')
if ok then
  vim.lsp.config('*', { capabilities = blink.get_lsp_capabilities() })
end
