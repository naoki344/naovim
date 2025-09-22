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
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>')
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

-- File search mappings (using Vim built-in commands)
vim.keymap.set('n', '<C-p>', function()
  vim.cmd('edit .')
end, { desc = 'Open file browser' })

vim.keymap.set('n', '<C-g>', function()
  local pattern = vim.fn.input('Search for: ')
  if pattern ~= '' then
    vim.cmd('vimgrep /' .. vim.fn.escape(pattern, '/') .. '/j **/*')
    vim.cmd('copen')
  end
end, { desc = 'Search in files' })

vim.keymap.set('n', '<C-b>', function()
  vim.cmd('buffers')
  local buf_num = vim.fn.input('Buffer number (or name): ')
  if buf_num ~= '' then
    if tonumber(buf_num) then
      vim.cmd('buffer ' .. buf_num)
    else
      vim.cmd('buffer ' .. buf_num)
    end
  end
end, { desc = 'Switch buffer' })

-- Additional file navigation
vim.keymap.set('n', '<leader>ff', function()
  vim.cmd('edit .')
end, { desc = 'File browser' })

vim.keymap.set('n', '<leader>fg', function()
  local pattern = vim.fn.input('Search for: ')
  if pattern ~= '' then
    vim.cmd('vimgrep /' .. vim.fn.escape(pattern, '/') .. '/j **/*')
    vim.cmd('copen')
  end
end, { desc = 'Grep in files' })

vim.keymap.set('n', '<leader>fb', ':buffers<CR>', { desc = 'List buffers' })
vim.keymap.set('n', '<leader>fh', ':help<CR>', { desc = 'Help' })

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