local lspconfig = require('lspconfig')

--require'lspconfig'.ruby_lsp.setup{}
--require'lspconfig'.gopls.setup{}
--require'lspconfig'.denols.setup{}

require("mason").setup()
require("mason-lspconfig").setup()
require('mason-lspconfig').setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {}
  end,
}

