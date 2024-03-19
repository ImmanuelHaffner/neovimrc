local M = {}

function M.setup()
    vim.o.guifont = 'Source Code Pro:h11' -- text below applies for VimScript
    vim.g.neovide_hide_mouse_when_typing = true
end

return M
