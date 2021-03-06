" vim: set foldmethod=marker:
"
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
Plug 'artur-shaik/vim-javacomplete2', { 'for': ['java'] }
Plug 'ctrlpvim/ctrlp.vim'
Plug 'derekwyatt/vim-fswitch'
Plug 'euclio/vim-markdown-composer', { 'do': function('BuildMarkdownComposer'), 'for': 'markdown' }
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'gpanders/vim-medieval', { 'for': 'markdown' }
Plug 'jalvesaq/Nvim-R', { 'for': 'r' }
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'lifepillar/pgsql.vim', { 'for': ['sql', 'pgsql'] }
Plug 'ludovicchabant/vim-gutentags'
Plug 'mh21/errormarker.vim', { 'for': ['c', 'cpp'] }
Plug 'mhinz/vim-grepper'
Plug 'neovimhaskell/haskell-vim', { 'for': 'haskell' }
Plug 'powerman/vim-plugin-viewdoc'
Plug 'rhysd/vim-grammarous'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'Shougo/echodoc.vim'
Plug 'skywind3000/asyncrun.vim'
Plug 'sudar/vim-arduino-syntax', { 'for': 'ino' }
Plug 'sukima/xmledit', { 'for': ['xml', 'html', 'xhtml'] }
Plug 'szymonmaszke/vimpyter'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-pandoc/vim-pandoc-syntax', { 'for': 'markdown' }
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'vim-scripts/taglist.vim'
Plug 'Yggdroot/indentLine'
Plug 'zchee/deoplete-clang', { 'for': ['c', 'cpp'] }
Plug 'zchee/deoplete-jedi', { 'for': ['python', 'ipynb'] }
call plug#end()
"Plug 'rdnetto/YCM-Generator', { 'branch': 'stable'}
"Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --system-libclang', 'for': ['c', 'cpp', 'python', 'tex'] }

" vim-airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#show_buffers = 0

" vim-grepper
let g:grepper = { 'quickfix': 0 }

" Deoplete
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option({
            \ 'ignore_case': 1,
            \ 'min_pattern_length': 1,
            \ })
let g:deoplete#complete_method = 'completefunc'

" deoplete-clang
let g:deoplete#sources#clang#libclang_path = '/usr/lib/libclang.so'
let g:deoplete#sources#clang#clang_header = '/usr/lib/clang/'
let g:deoplete#sources#clang#sort_algo = 'priority'
let g:deoplete#sources#clang#flags = [
            \ '-triple', 'x86_64-pc-linux-gnu',
            \
            \ '-W',
            \ '-Wall',
            \ '-pedantic'
            \ ]
let g:deoplete#sources#clang#include_default_arguments = 1
let g:deoplete#sources#clang#filter_availability_kinds = ['NotAvailable', 'NotAccessible']

" echodoc
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'virtual'

" ctrlp
if executable('ag')
    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
elseif executable('ack')
    let g:ctrlp_user_command = 'ack %s -l --nocolor -g ""'
endif
let g:ctrlp_custom_ignore = {
            \ 'dir':  '\v[\/]\.(git|hg|svn)$|build',
            \ 'file': '\v\.(exe|so|dll|a)$',
            \ }
let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'


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

" AsyncRun
let g:airline_section_error = airline#section#create_right(['%{g:asyncrun_status}'])

" taglist
nmap <silent> <F7> :TlistToggle<CR>
let g:Tlist_Close_On_Select = 2
let g:Tlist_Display_Prototype = 2
let g:Tlist_Enable_Fold_Column = 1
let g:Tlist_File_Fold_Auto_Close = 2
let g:Tlist_GainFocus_On_ToggleOpen = 2
let g:Tlist_WinWidth = 81
let g:Tlist_Highlight_Tag_On_BufEnter = 2

" vim-grammarous
let g:grammarous#default_comments_only_filetypes = {
            \ '*' : 1, 'help' : 0, 'markdown' : 0,
            \ }
let g:grammarous#use_vim_spelllang = 1
let g:grammarous#languagetool_cmd = '/usr/bin/languagetool'
let g:grammarous#use_location_list = 1
let g:grammarous#disabled_rules = {
            \ '*' : ['DASH_RULE'],
            \ }

" vimtex
let g:vimtex_compiler_progname = 'nvr'
let g:vimtex_compiler_method = 'latexmk'
let g:latex_view_general_viewer = 'zathura'
let g:vimtex_view_method = 'zathura'

" errormarker
" Distinguish between warnings and errors
let &errorformat="%f:%l:%c: %t%*[^:]:%m,%f:%l: %t%*[^:]:%m," . &errorformat

" NERDCommenter
let g:NERDCreateDefaultMappings = 0
let g:NERDAllowAnyVisualDelims = 1
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDTrimTrailingWhitespace = 1
let g:NERDDefaultAlign = 'left'

" vim-gutentags
let g:gutentags_cache_dir = expand("~/.cache/vim/tags")
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_generate_on_empty_buffer = 0
let g:gutentags_ctags_extra_args = [
      \ '--tag-relative=yes',
      \ '--fields=+ailmnS',
      \ ]
let g:gutentags_file_list_command = {
    \ 'markers': {
        \ '.git': 'git ls-files',
        \ '.hg': 'hg files',
        \ },
    \ }

" vim-medieval
let g:medieval_langs = [ 'python=python3', 'sh=zsh', 'console=zsh' ]

"==}}}==================================================================================================================

"== Global configuration {{{============================================================================================
colorscheme solarized
set background=dark

if empty(v:servername) && exists('*remote_startserver')
    call remote_startserver('VIM')
endif


let mapleader=","
set confirm
set wildignorecase
set wildmode=longest:full,full

set completeopt=menu,menuone,longest,noselect,preview

set tags=./.tags

if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor\ --column
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

" Set the font and size for the hardcopy command
set printfont=Courier:h8

set updatetime=1500
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
command! Untab2 :%s/\t/  /g
command! Untab4 :%s/\t/    /g

"au! CursorHold *.c,*.h,*.cpp,*.hpp ++nested call PreviewWord()
func PreviewWord()
    if &previewwindow " don't do this in the preview window
        return
    endif
    let w = expand("<cword>") " get the word under cursor
    if w =~ '\a' " if the word contains a letter

        " Delete any existing highlight before showing another tag
        silent! wincmd P " jump to preview window
        if &previewwindow " if we really get there...
            match none " delete existing highlight
            wincmd p " back to old window
        endif

        " Try displaying a matching tag for the word under the cursor
        try
            exe "ptag " . w
        catch
            return
        endtry

        silent! wincmd P " jump to preview window
        if &previewwindow " if we really get there...
            if has("folding")
                silent! .foldopen " don't want a closed fold
            endif
            call search("$", "b") " to end of previous line
            let w = substitute(w, '\\', '\\\\', "")
            call search('\<\V' . w . '\>') " position cursor on match
            " Add a match highlight to the word at this position
            hi previewWord term=bold ctermbg=green guibg=green
            exe 'match previewWord "\%' . line(".") . 'l\%' . col(".") . 'c\k*"'
            wincmd p " back to old window
        endif
    endif
endfun

func FormatParagraph()
    let old_pos = getpos('.')
    normal! {V}gw
    call setpos('.', old_pos)
endfunc

func! MoveFile(new_file, override, copy)
    let old_file = expand('%')
    let old_buf = bufnr('%')
    let old_buf_info = getbufinfo(old_buf)[0]

    if (old_buf_info.changed)
        echoerr 'Buffer is changed.  Save or restore before moving the file.'
        return
    endif

    if (a:new_file == '')
        echoerr 'Invalid file name.'
        return
    endif

    if (a:new_file == old_file) " nothing to be done
        return
    endif

    if (bufloaded('^' . a:new_file . '$'))
        echoerr 'File "' . a:new_file . '" is already loaded in a buffer.'
        return
    endif

    if (a:override)
        if (filereadable(a:new_file) && !filewritable(a:new_file))
            echoerr 'Cannot override file "' . a:new_file . '".'
        endif
        exe ':saveas! ' . fnameescape(a:new_file)
    else
        if (filereadable(a:new_file))
            echoerr 'File "' . a:new_file . '" already exists.'
            return
        endif
        exe ':saveas ' . fnameescape(a:new_file)
    endif

    exe ':e ' . fnameescape(a:new_file)
    if (!a:copy)
        exe ':silent !rm ' . fnameescape(old_file)
        exe ':silent bdelete ' . fnameescape(old_file)
    endif
endfunc

command! -nargs=1 -complete=file -bang Mv :call MoveFile(<f-args>, len(<q-bang>), 0)
command! -nargs=1 -complete=file -bang Rename :call MoveFile(expand('%:h') . '/' . <q-args> . '.' . expand('%:e'), len(<q-bang>), 0)
command! -nargs=1 -complete=file -bang Cp :call MoveFile(<f-args>, len(<q-bang>), 1)
command! -nargs=1 -complete=file -bang Clone :call MoveFile(expand('%:h') . '/' . <q-args> . '.' . expand('%:e'), len(<q-bang>), 1)
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

" Open file under cursor in vertically split window
nnoremap <C-W><C-F> <C-W>vgf

nmap <silent> <F2> :NERDTree<CR>
nmap <silent> <F3> :call SpellToggle()<CR>
nmap <silent> <F4> :call CrosshairToggle()<CR>
nmap <silent> <F5> :AsyncRun -program=make<CR>
nmap <silent> <F6> :cl<CR>

nmap <silent> <A-w> :call FormatParagraph()<CR>
imap <silent> <A-w> <C-o>gwgw
xmap <silent> <A-w> gw

vmap <silent> <C-s> :sort i<CR>
vmap <silent> <C-r> :!tac<CR>

nmap <silent> <C-c> :call NERDComment(0, "toggle")<CR>
vmap <silent> <C-c> :call NERDComment(1, "toggle")<CR>

nmap <silent> <leader>ff :FSHere<CR>
nmap <silent> <leader>fh <C-W>v<C-W>h:FSHere<CR>
nmap <silent> <leader>fk <C-W>s<C-W>k:FSHere<CR>
nmap <silent> <leader>fj <C-W>s:FSHere<CR>
nmap <silent> <leader>fl <C-W>v:FSHere<CR>
nmap <silent> <leader>ft :tabnew %<CR>:FSHere<CR>

nmap <silent> <leader>l :exe "source .session.vim"<CR>

" Enable toggleing between tabs with <leader>t
au TabLeave * let g:lasttab = tabpagenr()
nmap <silent> <leader>t :exe "tabn ".g:lasttab<cr>

nmap <silent> <leader>p :call ToggleParagraph()<CR>

nmap <silent> <BS> :DeleteTrailingWs<CR>

vmap <silent> * :call VSearch('f')<CR>
vmap <silent> # :call VSearch('b')<CR>

nmap <silent> <leader>gn :call grammarous#move_to_next_error(getpos('.')[1 : 2], b:grammarous_result)<CR>:call grammarous#create_and_jump_to_info_window_of(b:grammarous_result)<CR>
nmap <silent> <leader>gN :call grammarous#move_to_previous_error(getpos('.')[1 : 2], b:grammarous_result)<CR>:call grammarous#create_and_jump_to_info_window_of(b:grammarous_result)<CR>

autocmd Filetype ipynb nmap <silent><buffer> <leader>b :VimpyterInsertPythonBlock<CR>
autocmd Filetype ipynb nmap <silent><buffer> <leader>j :VimpyterStartJupyter<CR>
autocmd Filetype ipynb nmap <silent><buffer> <leader>n :VimpyterStartNteract<CR>

" vim-medieval: Evaluate block and put output in default register.
autocmd Filetype markdown nmap <silent><buffer> <F5> :EvalBlock @"<CR>:cexpr getreg('"')<CR>:copen<CR>:wincmd p<CR>
"==}}}==================================================================================================================

" Project-specific configuration
if filereadable(".project.vim")
    source .project.vim
endif
