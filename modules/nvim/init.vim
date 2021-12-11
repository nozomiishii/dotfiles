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

" coc config
let g:coc_global_extensions = [
  \ 'coc-sh',
  \ 'coc-tabnine',
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-tsserver',
  \ 'coc-eslint', 
  \ 'coc-prettier', 
  \ 'coc-json', 
  \ ]

" Prettier
command! -nargs=0 Prettier :CocCommand prettier.formatFile


" Auto Completion
" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
