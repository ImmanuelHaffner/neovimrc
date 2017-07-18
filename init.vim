" vim: set foldmethod=marker:

"== Plugin Management & Configuration {{{===============================================================================
function! BuildMarkdownComposer(info)
    if a:info.status != 'unchanged' || a:info.force
        !cargo build --release
        UpdateRemotePlugins
    endif
endfunction

call plug#begin()
Plug 'airblade/vim-gitgutter'
Plug 'altercation/vim-colors-solarized'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'derekwyatt/vim-fswitch'
Plug 'euclio/vim-markdown-composer', { 'do': function('BuildMarkdownComposer'), 'for': 'markdown' }
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'jalvesaq/Nvim-R', { 'for': 'r' }
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'mhinz/vim-grepper'
Plug 'neovimhaskell/haskell-vim', { 'for': 'haskell' }
Plug 'powerman/vim-plugin-viewdoc'
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable'}
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'sudar/vim-arduino-syntax', { 'for': 'ino' }
Plug 'sukima/xmledit', { 'for': ['xml', 'html', 'xhtml'] }
Plug 'tpope/vim-fugitive'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --system-libclang', 'for': ['c', 'cpp', 'python'] }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-pandoc/vim-pandoc-syntax', { 'for': 'markdown' }
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'Yggdroot/indentLine'
call plug#end()

" vim-airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" vim-grepper
let g:grepper = {
            \ 'quickfix': 0
            \ }

" ctrlp
if executable('ag')
    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
elseif executable('ack')
    let g:ctrlp_user_command = 'ack %s -l --nocolor -g ""'
endif

" Markdown Composer
let g:markdown_composer_open_browser = 1
let g:markdown_composer_autostart = 1

" indentLine
let g:indentLine_enabled = 0
augroup filetype
    au FileType c,cpp,python,java IndentLinesEnable
augroup END

" XMLEdit
let g:xmledit_enable_html = 1

" YouCompleteMe
let g:ycm_min_num_of_chars_for_completion = 3
let g:ycm_error_symbol = '<{'
let g:ycm_warning_symbol = '>>'
let g:ycm_echo_current_diagnostic = 1
let g:ycm_max_diagnostics_to_display = 10
let g:ycm_key_list_select_completion = []
let g:ycm_key_list_previous_completion = []
let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
let g:ycm_confirm_extra_conf = 0

" ViewDoc
let g:viewdoc_openempty=0
let g:viewdoc_copy_to_search_reg=1

" Gitgutter
let g:gitgutter_max_signs = 50
let g:gitgutter_realtime = 0
let g:gitgutter_eager = 0
"==}}}==================================================================================================================

"== Global configuration {{{============================================================================================
colorscheme solarized
set background=dark

let mapleader=","
set confirm
set wildignorecase
set wildmode=list:longest

if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor
elseif executable('ack')
    set grepprg=ack\ --nogroup\ --nocolor
endif

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

set listchars=tab:┣━,extends:@,trail:·
set list
set colorcolumn=121
set cursorline
set number
set relativenumber
set lazyredraw

set nowrap
set linebreak

set scrolloff=7
set sidescroll=1
set sidescrolloff=15
set textwidth=120

set undodir=$HOME/.config/nvim/undo/
set undofile
set undolevels=500
set undoreload=10000

set nowrapscan
set hlsearch
set incsearch

set ignorecase
set smartcase

set conceallevel=2
set concealcursor="nc"

set formatoptions=tcrqnlj

set splitbelow
set splitright

set sessionoptions=buffers,folds,sesdir,tabpages,winpos,winsize,help

set nofoldenable
set foldmethod=manual

set autoread

let g:tex_flavor = "latex"

hi! ColorColumn term=reverse cterm=reverse
hi! CursorLineNr term=bold,reverse cterm=bold,reverse ctermfg=6

let g:python_host_skip_check = 1
let g:python_host_prog = '/usr/bin/python2'
let g:python3_host_skip_check = 1
let g:python3_host_prog = '/usr/bin/python3'
"==}}}==================================================================================================================

"== Functions & Commands {{{============================================================================================
function! CrosshairToggle()
    if (&cursorcolumn == 1)
        setlocal nocursorcolumn
        echo "Crosshair: Off"
    else
        setlocal cursorcolumn
        echo "Crosshair: On"
    endif
endfunction

function! ToggleParagraph()
    if &formatoptions =~ "a"
        setlocal formatoptions-=a
        echo "Paragraphs: Off"
    else
        setlocal formatoptions+=a
        echo "Paragraphs: On"
    endif
endfunction

function! SpellToggle()
    if (&spell == 1)
        setlocal nospell
        echo "Spell: Off"
    else
        setlocal spell
        echo "Spell: On"
    endif
endfunction

function! SaveAndQuit()
    exe "mksession! .session.vim"
    exe "wqa"
endfunction

function! VSearch(direction) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", '\\/.*$^~[]')
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
    elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
    elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.')
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

command! -nargs=1 V :vertical resize <args>
command! Q call SaveAndQuit()
command! DeleteTrailingWs :%s/\s\+$//
command! Untab2 :%s\t/  /g
command! Untab4 :%s\t/    /g
"==}}}==================================================================================================================

"== Key mapping {{{=====================================================================================================
tmap <A-h> <C-\><C-n><C-w>h
tmap <A-j> <C-\><C-n><C-w>j
tmap <A-k> <C-\><C-n><C-w>k
tmap <A-l> <C-\><C-n><C-w>l
nmap <A-h> <C-w>h
nmap <A-j> <C-w>j
nmap <A-k> <C-w>k
nmap <A-l> <C-w>l

nmap <silent> <F2> :NERDTree<CR>
nmap <silent> <F3> :call SpellToggle()<CR>
nmap <silent> <F4> :call CrosshairToggle()<CR>
nmap <silent> <F5> :make!<CR>:cl<CR>
nmap <silent> <F6> :cl<CR>

nmap <silent> <A-w> gwgw
imap <silent> <A-w> <C-o>gwgw
xmap <silent> <A-w> gw

vmap <silent> <C-s> :sort i<CR>

nmap <silent> <C-c> :call NERDComment(0, "toggle")<CR>
vmap <silent> <C-c> :call NERDComment(1, "toggle")<CR>

nmap <silent> <Tab>   :tabnext<CR>
nmap <silent> <S-Tab> :tabprevious<CR>

nmap <S-t> :tabnew <C-d>

nmap <silent> <leader>ff :FSHere<CR>
nmap <silent> <leader>fh <C-W>v<C-W>h:FSHere<CR>
nmap <silent> <leader>fk <C-W>s<C-W>k:FSHere<CR>
nmap <silent> <leader>fj <C-W>s:FSHere<CR>
nmap <silent> <leader>fl <C-W>v:FSHere<CR>
nmap <silent> <leader>ft :tabnew %<CR>:FSHere<CR>

nmap <silent> <leader>l :exe "source .session.vim"<CR>

nmap <silent> <leader>p :call ToggleParagraph()<CR>

nmap <silent> <BS> :DeleteTrailingWs<CR>

vmap <silent> * :call VSearch('f')<CR>
vmap <silent> # :call VSearch('b')<CR>
"==}}}==================================================================================================================

" Project-specific configuration
if filereadable(".project.vim")
    source .project.vim
endif
