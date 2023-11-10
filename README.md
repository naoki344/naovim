# naovim

## インストール方法
### vimのインストール
- brew install neovim
- anyenv,nodenv,npm,yarnをインストールする
- ~/.config/nvim にこのリポジトリを保存しておく
- pip3 install neovim

### cocの準備
- :call coc#util#install()
- :CocInstall coc-python
- :CocInstall coc-json


### ripgrepのinstall(vim-ripgrep用)
```
brew install ripgrep
```



## Vimium chromeをvimらいくにする
### https://qiita.com/satoshi03/items/9fdfcd0e46e095ec68c1
- Insert your preferred key mappings here.
- map h goBack
- map l goForward
- map H previousTab
- map L nextTab
- map i LinkHints.activateMode
- map I LinkHints.activateModeToOpenInNewTab




### GOの設定

#### 以下をinstallする
```
go get -u golang.org/x/tools/cmd/gopls
```
