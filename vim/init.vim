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
set encoding=utf-8
set clipboard+=unnamed
set number
set numberwidth=3
set showcmd
set hlsearch

set splitbelow
set splitright

set expandtab
set tabstop=2
set shiftwidth=2

set showmatch
set matchtime=1
set matchpairs& matchpairs+=<:>

set noswapfile

if !exists('g:vscode')
  call plug#begin(expand('~/.config/nvim/plugged'))

  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'github/copilot.vim'
  Plug 'easymotion/vim-easymotion'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'EdenEast/nightfox.nvim'
  "Plug 'dracula/vim', { 'as': 'dracula' }
  "Plug 'mxw/vim-jsx'
  "Plug 'pangloss/vim-javascript'
  "Plug 'leafgarland/typescript-vim'
  "Plug 'peitalin/vim-jsx-typescript'

  call plug#end()

:lua <<EOF
  require('lualine').setup()
  require('nvim-web-devicons').setup {}
  require'nvim-treesitter.configs'.setup {
    ensure_installed =  'all',
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false, -- catpuucin用
      disable = {},
    },
    indent = {
      enable = true,--言語に応じた自動インデントを有効化
      disable = {"html"},-- htmlのインデントだけ無効化
  　},
    autotag = {
      enable = true,
    },
  }

EOF

  " Color Scheme
  syntax enable
  colorscheme nightfox

	"Coc Plugins
	let g:coc_global_extensions = [	
        \'coc-lists', 
        \'coc-json',	
        \'coc-git',	
        \'@yaegassy/coc-intelephense',	
        \'coc-tsserver',	
        \'coc-explorer',	
        \'coc-solargraph',	
        \'coc-prettier',	
        \'coc-docker',
        \'coc-css',
        \'coc-html',
        \'coc-yaml',
        \'coc-vimlsp',
        \'coc-lua',
        \'coc-highlight',
        \'coc-nav',
        \'coc-tailwindcss'
  \]
  " Coc Settings
  inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
  
  set cmdheight=2
  set updatetime=300
  
  " Move between windows
  nnoremap <Return><Return> <c-w><c-w>

  let mapleader="\<Space>"
  map <Leader> <Plug>(easymotion-prefix)
  map <Leader>j <Plug>(easymotion-j)
  map <Leader>k <Plug>(easymotion-k)

  nmap <space>e <Cmd>CocCommand explorer<CR>
  
else
  " Required:
  call plug#begin(expand('~/.config/nvim/plugged'))

  "Plug 'asvetliakov/vim-easymotion'
  Plug 'github/copilot.vim'

  call plug#end()
  
  "" Map leader to ,
  "let mapleader="\<Space>"

  "nnoremap :call VSCodeNotify('workbench.action.closeOtherEditors')
  "nnoremap :call VSCodeNotify('workbench.action.toggleSidebarVisibility')

  "map <Leader> <Plug>(easymotion-prefix)
  " Disable default mappings

  "let g:EasyMotion_smartcase = 1

  "map <Leader>j <Plug>(easymotion-j)
  "map <Leader>k <Plug>(easymotion-k)
endif
