-- Key mappings

-- Insert mode escape mappings
vim.keymap.set('i', 'jj', '<ESC>', { silent = true })
vim.keymap.set('i', '<C-j>', 'j', { silent = true })
vim.keymap.set('i', 'kk', '<ESC>', { silent = true })
vim.keymap.set('i', '<C-k>', 'k', { silent = true })
vim.keymap.set('i', 'fd', '<ESC>')

-- Disable arrow keys
local arrow_keys = {'<Up>', '<Down>', '<Left>', '<Right>'}
for _, key in ipairs(arrow_keys) do
  vim.keymap.set('n', key, '<Nop>')
  vim.keymap.set('i', key, '<Nop>')
end

-- General mappings
vim.keymap.set('n', '<space>v', ':q<CR>')

-- Git mappings (fugitive)
vim.keymap.set('n', '<leader>gw', ':Gwrite<CR>')
vim.keymap.set('n', '<leader>gc', ':Gcommit<CR>')
vim.keymap.set('n', '<leader>gs', ':Gstatus<CR>')

-- Tagbar toggle
vim.keymap.set('n', 'q', ':TagbarToggle<CR>')

-- File explorer (nvim-tree)
vim.keymap.set('n', '<C-n>', function()
  vim.cmd('NvimTreeToggle')
  -- Equalize window sizes after toggle
  vim.defer_fn(function()
    vim.cmd('wincmd =')
  end, 50)
end, { desc = 'Toggle nvim-tree and equalize windows' })
vim.keymap.set('n', '<leader>nf', ':NvimTreeFindFile<CR>', { desc = 'Find current file in tree' })
vim.keymap.set('n', '<leader>nr', function()
  local nvim_tree_api_ok, nvim_tree_api = pcall(require, 'nvim-tree.api')
  if nvim_tree_api_ok then
    nvim_tree_api.tree.reload()
    -- Force refresh error marks after reload
    vim.defer_fn(function()
      vim.cmd('doautocmd User NvimTreeRefresh')
    end, 200)
  end
end, { desc = 'Refresh tree with diagnostics' })

-- File search mappings (Telescope handles these via lazy-setup.lua)
-- <C-p> - Find files (Telescope)
-- <leader>ff - Find files (Telescope)
-- <leader>fg - Live grep (Telescope)
-- <leader>fb - Buffers (Telescope)
-- <leader>fh - Help tags (Telescope)
-- <leader>fr - Recent files (Telescope)
-- <leader>fc - Commands (Telescope)
-- <leader>fs - Document symbols (Telescope)
-- <leader>fd - Diagnostics (Telescope)

-- Additional custom search mappings
vim.keymap.set('n', '<C-g>', function()
  require('telescope.builtin').live_grep()
end, { desc = 'Live grep with Telescope' })

vim.keymap.set('n', '<C-b>', function()
  require('telescope.builtin').buffers()
end, { desc = 'Switch buffer with Telescope' })

vim.keymap.set('n', '<C-o>', function()
  require('telescope.builtin').oldfiles({ cwd_only = true })
end, { desc = 'Recent files (cwd) with Telescope' })

-- LSP mappings (defined in lsp.lua on_attach function)
-- gD - Go to declaration
-- gd - Go to definition
-- K - Hover documentation
-- gi - Go to implementation
-- gr - Go to references
-- <space>rn - Rename symbol
-- <space>ca - Code actions
-- <space>f - Format document
-- [d, ]d - Navigate diagnostics

-- Go mappings
vim.keymap.set('n', '<C-E>', ':GoReferrers<CR>')

-- Ripgrep command
vim.api.nvim_create_user_command('Ripgrep', function(opts)
  vim.fn['ripgrep#search'](opts.args)
end, { nargs = '*', complete = 'file' })

-- Color preview toggle mappings
vim.keymap.set('n', '<leader>ct', ':ColorizerToggle<CR>', { desc = 'Toggle color preview' })
vim.keymap.set('n', '<leader>ca', ':ColorizerAttachToBuffer<CR>', { desc = 'Attach color preview to buffer' })
vim.keymap.set('n', '<leader>cd', ':ColorizerDetachFromBuffer<CR>', { desc = 'Detach color preview from buffer' })