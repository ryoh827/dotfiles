set nocompatible
set number
syntax on
set backspace=indent,eol,start
set noswapfile
set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set clipboard=unnamed,autoselect
inoremap <silent> jj <ESC>
inoremap <silent> っj <ESC>

set runtimepath+=~/.vim/bundle/neobundle.vim/
call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Townk/vim-autoclose'
NeoBundle 'aereal/vim-colors-japanesque'
NeoBundle 'easymotion/vim-easymotion'

call neobundle#end()
filetype plugin indent on
NeoBundleCheck


function! HardMode ()
  noremap <Up> <Nop>
  noremap <Down> <Nop>
  noremap <Left> <Nop>
  noremap <Right> <Nop>
endfunction

function! EasyMode ()
  noremap <Up> <Up>
  noremap <Down> <Down>
  noremap <Left> <Left>
  noremap <Right> <Right>
endfunction

command! HardMode call HardMode()
command! EasyMode call EasyMode()

"easymotion
nmap s <Plug>(easymotion-overwin-f2)
let g:EasyMotion_smartcase = 1

"Color Schema
syntax enable
"set background=dark
"colorscheme solarized
