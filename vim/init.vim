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
set signcolumn=yes
set nowrap

set splitbelow
set splitright

set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent
set ignorecase
set smartcase

set showmatch
set matchtime=1
set matchpairs& matchpairs+=<:>

set noswapfile


if !exists('g:vscode')
  call plug#begin(expand('~/.config/nvim/plugged'))

  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-treesitter/playground'
  Plug 'github/copilot.vim'
  Plug 'easymotion/vim-easymotion'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'EdenEast/nightfox.nvim'
  "Plug 'dracula/vim', { 'as': 'dracula' }
  "Plug 'mxw/vim-jsx'
  "Plug 'pangloss/vim-javascript'
  "Plug 'leafgarland/typescript-vim'
  "Plug 'peitalin/vim-jsx-typescript'
  Plug 'maxmellon/vim-jsx-pretty'
  Plug 'kylechui/nvim-surround'
  Plug 'crispgm/nvim-tabline'
  Plug 'ConradIrwin/vim-bracketed-paste'
  Plug 'Ryoh827/rufo-vim'
  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
  Plug 'jiangmiao/auto-pairs'
  Plug 'tpope/vim-commentary'
  Plug 'preservim/tagbar'

  call plug#end()

:lua <<EOF
  require('lualine').setup()
  require('nvim-web-devicons').setup {}
  require'nvim-treesitter.configs'.setup {
    ensure_installed =  'all',
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false, -- catpuucin用
      disable = {}
    },
    indent = {
      enable = true,--言語に応じた自動インデントを有効化
      disable = {"html"},-- htmlのインデントだけ無効化
  　},
    autotag = {
      enable = true,
    },
  }
  require("nvim-surround").setup {}
  require('tabline').setup {
    show_icon = true,
  }
EOF

  " Color Scheme
  syntax enable
  colorscheme duskfox
  set cursorline
  " Enable rufo (RUby Format)
  let g:rufo_auto_formatting = 1

	"Coc Plugins
	let g:coc_global_extensions = [	
        \'coc-diagnostic',
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
        \'coc-tailwindcss',
        \'coc-fzf-preview'
  \]
  " Coc Settings
  inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
  " GoTo code navigation
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)
 
  " Use K to show documentation in preview window
  nnoremap <silent> K :call ShowDocumentation()<CR>

  function! ShowDocumentation()
    if CocAction('hasProvider', 'hover')
      call CocActionAsync('doHover')
    else
      call feedkeys('K', 'in')
    endif
  endfunction

  nnoremap <C-p> :CocList files<CR>
  nnoremap <C-m> :CocList mru<CR>

  set cmdheight=2
  set updatetime=300

  augroup php
    autocmd!
    autocmd BufEnter,BufReadPre *.php setlocal syntax=php.javascript.jsx
  augroup END

  
  " Move between windows
  nnoremap <Return><Return> <c-w><c-w>
  inoremap <silent> jj <ESC>

  let mapleader="\<Space>"
  map <Leader> <Plug>(easymotion-prefix)
  map <Leader>j <Plug>(easymotion-j)
  map <Leader>k <Plug>(easymotion-k)

  nmap <space>e <Cmd>CocCommand explorer<CR>

  nmap <Leader>f [fzf-p]
  xmap <Leader>f [fzf-p]

  " Symbol renaming
  nmap <leader>rn <Plug>(coc-rename)

  nnoremap <silent> [fzf-p]p     :<C-u>CocCommand fzf-preview.FromResources project_mru git<CR>
  nnoremap <silent> [fzf-p]gs    :<C-u>CocCommand fzf-preview.GitStatus<CR>
  nnoremap <silent> [fzf-p]ga    :<C-u>CocCommand fzf-preview.GitActions<CR>
  nnoremap <silent> [fzf-p]b     :<C-u>CocCommand fzf-preview.Buffers<CR>
  nnoremap <silent> [fzf-p]B     :<C-u>CocCommand fzf-preview.AllBuffers<CR>
  nnoremap <silent> [fzf-p]o     :<C-u>CocCommand fzf-preview.FromResources buffer project_mru<CR>
  nnoremap <silent> [fzf-p]<C-o> :<C-u>CocCommand fzf-preview.Jumps<CR>
  nnoremap <silent> [fzf-p]g;    :<C-u>CocCommand fzf-preview.Changes<CR>
  nnoremap <silent> [fzf-p]/     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'"<CR>
  nnoremap <silent> [fzf-p]*     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'<C-r>=expand('<cword>')<CR>"<CR>
  nnoremap          [fzf-p]gr    :<C-u>CocCommand fzf-preview.ProjectGrep<Space>
  xnoremap          [fzf-p]gr    "sy:CocCommand   fzf-preview.ProjectGrep<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"
  nnoremap <silent> [fzf-p]t     :<C-u>CocCommand fzf-preview.BufferTags<CR>
  nnoremap <silent> [fzf-p]q     :<C-u>CocCommand fzf-preview.QuickFix<CR>
  nnoremap <silent> [fzf-p]l     :<C-u>CocCommand fzf-preview.LocationList<CR>
  
  au FileType * setlocal formatoptions-=ro
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
