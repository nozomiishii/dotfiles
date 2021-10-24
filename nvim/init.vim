set shell=/bin/zsh

call plug#begin()
" https://github.com/phanviet/vim-monokai-pro
Plug 'phanviet/vim-monokai-pro'
call plug#end()


set termguicolors
colorscheme monokai_pro
let g:lightline = {'colorscheme': 'monokai_pro'}

set nu
set tabstop=2 shiftwidth=2 expandtab
set textwidth=0
set autoindent
set hlsearch
set clipboard=unnamed


