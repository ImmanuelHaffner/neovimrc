vim.g.gui_font_face = 'Source Code Pro'
vim.g.gui_font_size = 11

local M = {}

function M.refresh_gui_font()
    vim.o.guifont = string.format("%s:h%d", M.gui_font_face, M.gui_font_size)
end

function M.resize_gui_font(delta)
    M.gui_font_size = M.gui_font_size + delta
    M.refresh_gui_font()
end

function M.reset_gui_font()
    M.gui_font_face = vim.g.gui_font_face
    M.gui_font_size = vim.g.gui_font_size
    M.refresh_gui_font()
end


function M.setup()
    M.reset_gui_font()
    vim.g.neovide_hide_mouse_when_typing = true

    -- Neovide keymaps
    local wk = require'which-key'
    wk.register({
        ['<C-+>'] = { function() M.resize_gui_font(1) end, 'increase font size' },
        ['<C-->'] = { function() M.resize_gui_font(-1) end, 'decrease font size' },
        ['<C-=>'] = { function() M.reset_gui_font() end, 'reset font size' },
    }, { mode = { 'n', 'i' }, noremap = true, silent = true })
end

return M
