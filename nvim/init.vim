set shell=/bin/zsh

call plug#begin()
  " https://github.com/phanviet/vim-monokai-pro
  Plug 'phanviet/vim-monokai-pro'
  " https://github.com/preservim/nerdtree
  Plug 'preservim/nerdtree'
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


