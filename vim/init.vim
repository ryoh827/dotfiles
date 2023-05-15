"*****************************************************************************
"" Vim-PLug core
"*****************************************************************************
if has('vim_starting')
  set nocompatible               " Be iMproved
endif

let vimplug_exists=expand('~/.config/nvim/autoload/plug.vim')

if !filereadable(vimplug_exists)
  if !executable("curl")
    echoerr "You have to install curl or first install vim-plug yourself!"
    execute "q!"
  endif
  echo "Installing Vim-Plug..."
  echo ""
  silent !\curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  let g:not_finish_vimplug = "yes"

  autocmd VimEnter * PlugInstall
endif

" Common Config
set clipboard+=unnamed
set number

if !exists('g:vscode')

else
  " Required:
  call plug#begin(expand('~/.config/nvim/plugged'))

  Plug 'asvetliakov/vim-easymotion'
  Plug 'github/copilot.vim'

  call plug#end()
  
  "" Map leader to ,
  let mapleader="\<Space>"

  nnoremap :call VSCodeNotify('workbench.action.closeOtherEditors')
  nnoremap :call VSCodeNotify('workbench.action.toggleSidebarVisibility')

  map <Leader> <Plug>(easymotion-prefix)
  " Disable default mappings

  let g:EasyMotion_smartcase = 1

  map <Leader>j <Plug>(easymotion-j)
  map <Leader>k <Plug>(easymotion-k)
endif
