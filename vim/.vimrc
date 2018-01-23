set nocompatible
set number
syntax on
set backspace=indent,eol,start
set noswapfile
set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4

set runtimepath+=~/.vim/bundle/neobundle.vim/
call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle "kana/vim-smartinput"
NeoBundle "cohama/vim-smartinput-endwise"


call neobundle#end()

call smartinput_endwise#define_default_rules()

filetype plugin indent on
NeoBundleCheck
