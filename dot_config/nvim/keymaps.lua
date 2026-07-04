vim.keymap.set("n", "<Space>go", function()
  require("oil").open_float()
end, { desc = "Oil current buffer's directory" })

vim.keymap.set("n", "<Space>gO", function()
  require("oil").open_float(".")
end, { desc = "Oil ." })

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fr', [[<cmd>lua require('telescope').extensions.recent_files.pick()<CR>]], {noremap = true, silent = true, desc = 'Telescope Recent Files'})
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope diagnostics' })
vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Telescope document symbols' })
vim.keymap.set('n', 'gr', builtin.lsp_references, { desc = 'Telescope LSP references' })
vim.keymap.set('n', '<leader>ft', '<cmd>TodoTelescope<CR>', { desc = 'Telescope todo comments' })

-- vim-illuminate
vim.keymap.set('n', ']r', function() require('illuminate').goto_next_reference() end, { desc = 'Next reference' })
vim.keymap.set('n', '[r', function() require('illuminate').goto_prev_reference() end, { desc = 'Previous reference' })

-- memolist
vim.keymap.set('n', '<leader>mn', ":MemoNew<CR>", { desc = 'Memo new' })
vim.keymap.set('n', '<leader>ml', ":MemoList<CR>", { desc = 'Memo list' })
vim.keymap.set('n', '<leader>mg', ":MemoGrep<CR>", { desc = 'Memo Grep' })

-- For default preset
vim.keymap.set('n', '<leader>mt', require('treesj').toggle, { desc = 'Toggle tree' })
-- For extending default preset with `recursive = true`
vim.keymap.set('n', '<leader>mT', function()
    require('treesj').toggle({ split = { recursive = true } })
end, { desc = 'Toggle tree (recursive)' })

-- buffer (bufferline の表示順で移動する)
vim.api.nvim_set_keymap('n', '<leader>bd', ':bd<CR>', { noremap = true, silent = true, desc='Delete buffer' })
vim.api.nvim_set_keymap('n', '<leader>bn', '<cmd>BufferLineCycleNext<CR>', { noremap = true, silent = true, desc='Next buffer' })
vim.api.nvim_set_keymap('n', '<leader>bp', '<cmd>BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc='Previous buffer' })
vim.api.nvim_set_keymap('n', '<leader>bc', ':bnext<CR>:bd#<CR>', { noremap = true, silent = true, desc='Close buffer' })
vim.api.nvim_set_keymap('n', '<S-l>', '<cmd>BufferLineCycleNext<CR>', { noremap = true, silent = true, desc='Next buffer' })
vim.api.nvim_set_keymap('n', '<S-h>', '<cmd>BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc='Previous buffer' })

-- dial.nvim (increment / decrement)
local dial = require("dial.map")
vim.keymap.set("n", "<C-a>", dial.inc_normal(), { noremap = true, desc = "Increment" })
vim.keymap.set("n", "<C-x>", dial.dec_normal(), { noremap = true, desc = "Decrement" })
vim.keymap.set("v", "<C-a>", dial.inc_visual(), { noremap = true, desc = "Increment" })
vim.keymap.set("v", "<C-x>", dial.dec_visual(), { noremap = true, desc = "Decrement" })
vim.keymap.set("v", "g<C-a>", dial.inc_gvisual(), { noremap = true, desc = "Increment (gradual)" })
vim.keymap.set("v", "g<C-x>", dial.dec_gvisual(), { noremap = true, desc = "Decrement (gradual)" })

vim.keymap.set('i', '<S-Tab>', '<C-d>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>gf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { noremap = true, silent = true, desc = "Format (conform/LSP)" })
vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true, desc = "Definition" })
vim.api.nvim_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true, desc = "Hover" })
vim.api.nvim_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', { noremap = true, silent = true, desc = "Implementation" })
vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { noremap = true, silent = true, desc = "Signature Help" })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { noremap = true, silent = true, desc = "Rename symbol" })
vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { noremap = true, silent = true, desc = "Code action" })

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

vim.keymap.set('n', '<leader>yp', function()
  local abs = vim.fn.expand('%:p')
  if abs == '' then
    vim.notify('No file in buffer', vim.log.levels.WARN)
    return
  end
  local root = vim.fn.systemlist({ 'git', '-C', vim.fn.expand('%:p:h'), 'rev-parse', '--show-toplevel' })[1]
  local path
  if vim.v.shell_error == 0 and root and root ~= '' then
    path = abs:sub(#root + 2)
  else
    path = vim.fn.fnamemodify(abs, ':.')
  end
  vim.fn.setreg('+', path)
  vim.notify('Yanked: ' .. path)
end, { desc = 'Yank relative path (repo root)' })

vim.keymap.set({ 'n', 'x' }, '<leader>yg', '<cmd>GitLink<cr>', { desc = 'Yank GitHub link (HEAD commit)' })
vim.keymap.set({ 'n', 'x' }, '<leader>yG', '<cmd>GitLink default_branch<cr>', { desc = 'Yank GitHub link (default branch)' })
vim.keymap.set({ 'n', 'x' }, '<leader>yo', '<cmd>GitLink!<cr>', { desc = 'Open GitHub link in browser' })

vim.keymap.set('n', 'gl', function() vim.diagnostic.open_float(nil, { focus = false }) end, { noremap = true, silent = true, desc = "Show line diagnostics" })
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, { noremap = true, silent = true, desc = "Previous diagnostic" })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, { noremap = true, silent = true, desc = "Next diagnostic" })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { noremap = true, silent = true, desc = "Diagnostics to loclist" })
