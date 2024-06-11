# naovim

## インストール方法
### vimのインストール
- brew install neovim
- anyenv,nodenv,npm,yarnをインストールする
- ~/.config/nvim にこのリポジトリを保存しておく
- pip3 install neovim

### cocの準備
- :call coc#util#install()
- :CocInstall coc-json

### pythonの準備
- :CocInstall coc-jedi
- pip3 install jedi-language-server(使っているenv環境のpipでinstallする)
- 
### ripgrepのinstall(vim-ripgrep用)
```
brew install ripgrep
```

```
brew install fd
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


### pythonの設定
- 以下をinstallする
```
pip install jedi-language-server
```

- `:CocInstall coc-jedi` をneovimで実行
