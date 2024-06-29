syntax on

call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'elkowar/yuck.vim'
Plug 'dracula/vim', { 'as': 'dracula' }

call plug#end()

let g:yuck_align_multiline_strings = 1
let g:yuck_align_subforms = 0
let g:yuck_align_keywords = 0
let g:yuck_lisp_indentation = 0

set encoding=UTF-8
set nowrap
set list
set listchars=eol:.,tab:>-,trail:~,extends:>,precedes:<

set cursorline
set number
set relativenumber
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
