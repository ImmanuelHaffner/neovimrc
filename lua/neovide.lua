local function get_dpi()
  local handle = io.popen[[xrdb -query | grep Xft.dpi | awk '{print $2}']]
  if handle then
    local result = handle:read'*a'
    handle:close()
    return tonumber(result) or 96
  end
  return 96  -- Default DPI if not found
end


local function compute_font_size(dpi)
    -- 169 dpi ⇒ 8 pt
    -- 69 dpi ⇒ 13 pt
    return math.floor(-.05 * dpi + 16.45 + .5)  -- +.5 to round
end

local dpi = get_dpi()
local default_font_size = compute_font_size(dpi)

vim.g.gui_font_faces = {
    'Source_Code_Pro',
    'Noto_Color_Emoji',
}
vim.g.gui_font_size = default_font_size

local M = {}

function M.refresh_gui_font()
    vim.o.guifont = table.concat(vim.g.gui_font_faces , ',') .. (':h%d'):format(vim.g.gui_font_size)
end

function M.resize_gui_font(delta)
    vim.g.gui_font_size = vim.g.gui_font_size + delta
    M.refresh_gui_font()
end

function M.reset_gui_font()
    vim.g.gui_font_size = default_font_size
    M.refresh_gui_font()
end

function M.setup()
    M.reset_gui_font()
    vim.g.neovide_hide_mouse_when_typing = true

    -- Neovide keymaps
    local wk = require'which-key'
    wk.add{
        mode = { 'n', 'i' },
        { '<C-+>', function() M.resize_gui_font(1) end, desc = 'increase font size' },
        { '<C-->', function() M.resize_gui_font(-1) end, desc = 'decrease font size' },
        { '<C-=>', function() M.reset_gui_font() end, desc = 'reset font size' },
    }
end

return M
