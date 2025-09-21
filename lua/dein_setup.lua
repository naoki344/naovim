-- dein.vim setup for Neovim with auto-installation
local dein_dir = vim.fn.expand('~/.cache/dein')
local dein_repo_dir = dein_dir .. '/repos/github.com/Shougo/dein.vim'

-- Auto-install dein.vim if not exists
if vim.fn.isdirectory(dein_repo_dir) == 0 then
  print('Installing dein.vim...')
  vim.fn.system('git clone https://github.com/Shougo/dein.vim.git ' .. vim.fn.shellescape(dein_repo_dir))
end

-- Add dein to runtimepath
vim.opt.runtimepath:prepend(dein_repo_dir)

-- Start dein configuration
vim.fn['dein#begin'](dein_dir)

-- dein.vim itself
vim.fn['dein#add'](dein_repo_dir)

-- Essential plugins (same as before)
vim.fn['dein#add']('tomasr/molokai')
vim.fn['dein#add']('kyazdani42/nvim-tree.lua')
vim.fn['dein#add']('kyazdani42/nvim-web-devicons')
vim.fn['dein#add']('tpope/vim-fugitive')
vim.fn['dein#add']('airblade/vim-gitgutter')
vim.fn['dein#add']('itchyny/lightline.vim')
vim.fn['dein#add']('majutsushi/tagbar')
vim.fn['dein#add']('windwp/nvim-autopairs')
vim.fn['dein#add']('fatih/vim-go')
vim.fn['dein#add']('github/copilot.vim')

-- LSP and completion plugins
vim.fn['dein#add']('neovim/nvim-lspconfig')
vim.fn['dein#add']('williamboman/mason.nvim')
vim.fn['dein#add']('williamboman/mason-lspconfig.nvim', {
  depends = {'mason.nvim', 'nvim-lspconfig'}
})
vim.fn['dein#add']('hrsh7th/nvim-cmp')
vim.fn['dein#add']('hrsh7th/cmp-nvim-lsp', {depends = 'nvim-cmp'})
vim.fn['dein#add']('hrsh7th/cmp-buffer', {depends = 'nvim-cmp'})
vim.fn['dein#add']('hrsh7th/cmp-path', {depends = 'nvim-cmp'})
vim.fn['dein#add']('hrsh7th/cmp-cmdline', {depends = 'nvim-cmp'})
vim.fn['dein#add']('L3MON4D3/LuaSnip')
vim.fn['dein#add']('saadparwaiz1/cmp_luasnip', {depends = {'nvim-cmp', 'LuaSnip'}})
vim.fn['dein#add']('rafamadriz/friendly-snippets', {depends = 'LuaSnip'})

-- End dein configuration
vim.fn['dein#end']()
vim.fn['dein#save_state']()

-- Auto-install missing plugins
if vim.fn['dein#check_install']() ~= 0 then
  print('Installing missing plugins...')
  vim.fn['dein#install']()
end

-- Auto-update on startup (optional, uncomment if desired)
-- vim.fn['dein#check_update'](v:true)

print('dein.vim setup completed')
return true