set shell=/bin/zsh
set encoding=utf-8


call plug#begin()
  " https://github.com/phanviet/vim-monokai-pro
  Plug 'phanviet/vim-monokai-pro'
  " https://github.com/preservim/nerdtree
  Plug 'preservim/nerdtree'
  " https://github.com/junegunn/fzf
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  " https://github.com/neoclide/coc.nvim
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  " list
  " https://github.com/neoclide/coc.nvim/wiki/Language-servers#supported-features
  " https://github.com/neoclide/coc-tabnine

  " Install with the vim command line
  " :CocInstall coc-tabnine coc-tsserver coc-json coc-sh 

  " You should create coc-settings.json like below if you have time
  " https://qiita.com/coil_msp123/items/29de76b035dd28af77a9
call plug#end()

" Monokai Pro
set termguicolors
colorscheme monokai_pro
let g:lightline = {'colorscheme': 'monokai_pro'}

" NERDTree
nnoremap <C-t> :NERDTreeToggle<CR>


set number
set tabstop=2 shiftwidth=2 expandtab
set textwidth=100
set autoindent
set incsearch
set hlsearch
set clipboard=unnamed


