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
