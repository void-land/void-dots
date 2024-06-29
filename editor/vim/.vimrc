syntax on

call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'elkowar/yuck.vim'
Plug 'dracula/vim', { 'as': 'dracula' }

call plug#end()

set encoding=UTF-8
set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set smartindent
set smarttab
set expandtab
set nowrap
set list
set listchars=eol:.,tab:>-,trail:~,extends:>,precedes:<

set cursorline
set number
set relativenumber
set scrolloff=8
set signcolumn=yes
set showcmd
set noshowmode
set conceallevel=1
set shortmess+=c
set formatoptions-=cro

set noerrorbells visualbell t_vb=
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set clipboard=unnamed

set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap confr :source ~/.vimrc<CR>

" Commands
command! Reload source $MYVIMRC

" Mapping
nnoremap <S-F> ggVG=
nnoremap <C-s> :w<CR>ggVG=<CR>

" Theme
set termguicolors
let g:gruvbox_italic=1
colorscheme dracula