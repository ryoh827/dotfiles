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

-- buffer
vim.api.nvim_set_keymap('n', '<leader>bd', ':bd<CR>', { noremap = true, silent = true, desc='Delete buffer' })
vim.api.nvim_set_keymap('n', '<leader>bn', ':bnext<CR>', { noremap = true, silent = true, desc='Next buffer' })
vim.api.nvim_set_keymap('n', '<leader>bp', ':bprevious<CR>', { noremap = true, silent = true, desc='Previous buffer' })
vim.api.nvim_set_keymap('n', '<leader>bc', ':bnext<CR>:bd#<CR>', { noremap = true, silent = true, desc='Close buffer' })
vim.api.nvim_set_keymap('n', '<S-l>', ':bnext<CR>', { noremap = true, silent = true, desc='Next buffer' })
vim.api.nvim_set_keymap('n', '<S-h>', ':bprevious<CR>', { noremap = true, silent = true, desc='Previous buffer' })

vim.keymap.set('i', '<S-Tab>', '<C-d>', { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>gf", ":lua vim.lsp.buf.format()<CR>", { noremap = true, silent = true, desc = "Format" })
vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true, desc = "Definition" })
vim.api.nvim_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true, desc = "Hover" })
vim.api.nvim_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', { noremap = true, silent = true, desc = "Implementation" })
vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { noremap = true, silent = true, desc = "Signature Help" })

