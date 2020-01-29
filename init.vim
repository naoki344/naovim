" 行数
set number

"let g:gitgutter_highlight_lines = 1
set noswapfile

set updatetime=250
set clipboard+=unnamed

" insertモードから抜ける
inoremap <silent> jj <ESC>
inoremap <silent> <C-j> j
inoremap <silent> kk <ESC>
inoremap <silent> <C-k> k

filetype indent on
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
" タブを表示するときの幅
set tabstop=4
" タブを挿入するときの幅
set shiftwidth=4
" タブをタブとして扱う(スペースに展開しない)
set noexpandtab

noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>
inoremap fd <Esc>
noremap <space>v :q<CR>
noremap <leader>gw :Gwrite<CR>
noremap <leader>gc :Gcommit<CR> 
noremap <leader>gs :Gstatus<CR>
nmap q :TagbarToggle<CR>



" プラグインがインストールされるディレクトリ
let s:dein_dir = expand('~/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

" 設定開始
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  " プラグインリストを収めた TOML ファイル
  " 予め TOML ファイルを用意しておく
  let g:rc_dir    = expand("~/.config/nvim/")
  let s:toml      = g:rc_dir . '/dein.toml'
  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

  " TOML を読み込み、キャッシュしておく
  call dein#load_toml(s:toml,      {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})
  " color scheme
  "call dein#add('tomasr/molokai')

  " 設定終了
  call dein#end()
  call dein#save_state()
endif

" もし、未インストールものものがあったらインストール
if dein#check_install()
  call dein#install()
endif

" ------------------------------------
" colorscheme
" ------------------------------------
colorscheme molokai
syntax on

" iTerm2で半透明にしているが、vimのcolorschemeを設定すると背景も変更されるため
highlight Normal ctermbg=none


" 全角スペース・行末のスペース・タブの可視化
if has("syntax")
    syntax on
 
    " PODバグ対策
    syn sync fromstart
 
    function! ActivateInvisibleIndicator()
        " 下の行の"　"は全角スペース
        syntax match InvisibleJISX0208Space "　" display containedin=ALL
        highlight InvisibleJISX0208Space term=underline ctermbg=Blue guibg=darkgray gui=underline
        "syntax match InvisibleTrailedSpace "[ \t]\+$" display containedin=ALL
        "highlight InvisibleTrailedSpace term=underline ctermbg=Red guibg=NONE gui=undercurl guisp=darkorange
        "syntax match InvisibleTab "\t" display containedin=ALL
        "highlight InvisibleTab term=underline ctermbg=white gui=undercurl guisp=darkslategray
    endfunction
 
    augroup invisible
        autocmd! invisible
        autocmd BufNew,BufRead * call ActivateInvisibleIndicator()
    augroup END
endif


function! ProfileCursorMove() abort
  let profile_file = expand('~/log/vim-profile.log')
  if filereadable(profile_file)
    call delete(profile_file)
  endif

  normal! gg
  normal! zR

  execute 'profile start ' . profile_file
  profile func *
  profile file *

  augroup ProfileCursorMove
    autocmd!
    autocmd CursorHold <buffer> profile pause | q
  augroup END

  for i in range(100)
    call feedkeys('j')
  endfor
endfunction


"augroup vimrc-filetype
"  autocmd!
"  " PHPだったらインデント幅が４で
"  autocmd BufNewFile,BufRead *.php set filetype=php
"  autocmd FileType php setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4
"
"  " Rubyだったらインデント幅は2にしたい
"  autocmd BufNewFile,BufRead *.rb set filetype=ruby
"  autocmd BufNewFile,BufRead *.ruby set filetype=ruby
"  autocmd FileType ruby setlocal expandtab tabstop=2 softtabstop=2 shiftwidth=2
"augroup END
if has('persistent_undo')
  set undodir=~/.vim/undo
  set undofile
endif


" coc 設定
nmap <silent> <C-]> <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" :nmap <C-n> :Defx -auto-recursive-level=1 -ignored-files=node_modules,.*<CR>
:nmap <C-n> :Defx -resume -toggle -winwidth=30 -split=vertical -direction=topleft -listed -ignored-files=__pycache__<CR>
" autocmd bufenter * if (winnr("$") == 1 && defx#is_opened_tree() == 'true') | defx#do_action('quit') | endif
