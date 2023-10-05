" Vim filetype plugin file
" Language:     LaTeX / TeX
" Maintainer:   Immanuel Haffner

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal textwidth=0
setlocal colorcolumn=0
setlocal wrap

let b:undo_ftplugin = "setlocal textwidth< wrap<"

" Manually init VimTeX for the current buffer.  This seems to be necessary because of Lazy and/or because we define our
" own ftplugin for tex files.
call vimtex#init()
