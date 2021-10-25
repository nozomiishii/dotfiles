set shell=/bin/zsh
set encoding=utf-8


call plug#begin()
  " https://github.com/phanviet/vim-monokai-pro
  Plug 'phanviet/vim-monokai-pro'
  " https://github.com/preservim/nerdtree
  Plug 'preservim/nerdtree'
  " https://github.com/junegunn/fzf
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
call plug#end()

" Monokai Pro
set termguicolors
colorscheme monokai_pro
let g:lightline = {'colorscheme': 'monokai_pro'}

" NERDTree
nnoremap <C-t> :NERDTreeToggle<CR>


set nu
set tabstop=2 shiftwidth=2 expandtab
set textwidth=100
set autoindent
set hlsearch
set clipboard=unnamed


