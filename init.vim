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
set tabstop=2
set shiftwidth=2
set expandtab

noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>
inoremap fd <Esc>
"nnoremap <silent><C-e> :NERDTreeToggle<CR>
map <C-n> :NERDTreeToggle<CR>

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
  call dein#add('tomasr/molokai')

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


"///////////////////////nerdtree/////////////////////////
" nerdtree が提示するファイルの順番を OSX と同じにしたい
let NERDTreeSortOrder = [ '*', '^..*' ]
" au VimEnter * NERDTreeToggle /Users/wakita/Dropbox
let NERDTreeBookmarksFile=$DROPBOX . '/lib/vim/miyoshi_naoki/nerdtree-bookmarks'

"https://kamiya555.github.io/2015/10/14/nerdtree-command/

autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif


"https://kamiya555.github.io/2015/10/14/nerdtree-command/

autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

"///////////////////////nerdtree/////////////////////////
