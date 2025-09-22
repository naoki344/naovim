-- Basic settings
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.updatetime = 250
vim.opt.clipboard = "unnamed"

-- Enable true color support (required for color previews)
if vim.fn.has('termguicolors') == 1 then
  vim.opt.termguicolors = true
end

-- Tab settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable filetype detection and indentation
vim.cmd('filetype indent on')

-- Enhanced TypeScript file type detection
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.ts", "*.tsx"},
  callback = function()
    vim.bo.filetype = "typescript"
  end,
})

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.jsx"},
  callback = function()
    vim.bo.filetype = "javascriptreact"
  end,
})

-- List characters
vim.opt.listchars = {
  tab = '»-',
  trail = '-',
  eol = '↲',
  extends = '»',
  precedes = '«',
  nbsp = '%'
}

-- Go-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

-- Encoding
vim.opt.encoding = 'UTF-8'

-- Undo settings
if vim.fn.has('persistent_undo') == 1 then
  vim.opt.undodir = vim.fn.expand('~/.vim/undo')
  vim.opt.undofile = true
end

-- Syntax highlighting
vim.cmd('syntax on')

-- Colorscheme will be set after plugins are loaded
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    pcall(function()
      vim.cmd('colorscheme molokai')
      vim.cmd('highlight Normal ctermbg=none')
    end)
  end
})

-- Auto close empty buffer
local function close_empty_buffer()
  if vim.fn.expand('%:t') == '' then
    vim.cmd('silent! bd!')
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = close_empty_buffer
})

-- Invisible character highlighting
local function activate_invisible_indicator()
  vim.cmd([[
    syntax match InvisibleJISX0208Space "　" display containedin=ALL
    highlight InvisibleJISX0208Space term=underline ctermbg=Blue guibg=darkgray gui=underline
  ]])
end

vim.api.nvim_create_augroup("invisible", { clear = true })
vim.api.nvim_create_autocmd({"BufNew", "BufRead"}, {
  group = "invisible",
  callback = activate_invisible_indicator
})

-- Profiling function
_G.profile_cursor_move = function()
  local profile_file = vim.fn.expand('~/log/vim-profile.log')
  if vim.fn.filereadable(profile_file) == 1 then
    vim.fn.delete(profile_file)
  end

  vim.cmd('normal! gg')
  vim.cmd('normal! zR')
  vim.cmd('profile start ' .. profile_file)
  vim.cmd('profile func *')
  vim.cmd('profile file *')

  vim.api.nvim_create_augroup("ProfileCursorMove", { clear = true })
  vim.api.nvim_create_autocmd("CursorHold", {
    group = "ProfileCursorMove",
    buffer = 0,
    callback = function()
      vim.cmd('profile pause | q')
    end
  })

  for i = 1, 100 do
    vim.fn.feedkeys('j')
  end
end

-- COC documentation function
local function show_documentation()
  local filetype = vim.bo.filetype
  if vim.tbl_contains({'vim', 'help'}, filetype) then
    vim.cmd('h ' .. vim.fn.expand('<cword>'))
  else
    vim.fn.CocAction('doHover')
  end
end

_G.show_documentation = show_documentation

-- Load plugin manager
require('plugins')
require('lsp')
require('keymaps')