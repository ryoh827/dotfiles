-- Wire blink.cmp completion capabilities into all LSP servers.
local ok, blink = pcall(require, 'blink.cmp')
if ok then
  vim.lsp.config('*', { capabilities = blink.get_lsp_capabilities() })
end
