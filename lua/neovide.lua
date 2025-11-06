local function get_dpi()
  local is_macos = vim.fn.has('mac') == 1
  
  if is_macos then
    -- macOS: Use system_profiler to get display info
    local handle = io.popen[[system_profiler SPDisplaysDataType | grep -B 3 "Main Display: Yes" | grep "Resolution" | head -1]]
    if handle then
      local display_info = handle:read('*a')
      handle:close()
      -- For Retina displays, macOS reports logical resolution, so we need to calculate actual DPI
      -- Most modern Macs have ~220 DPI for Retina displays, ~110 for non-Retina
      if display_info:find("Retina") then
        return 90
      else
        return 110  -- Standard DPI for non-Retina displays
      end
    end
    return 110  -- Default DPI for macOS if detection fails
  else
    -- Linux: Use xrdb to get DPI
    local handle = io.popen[[xrdb -query | grep Xft.dpi | awk '{print $2}']]
    if handle then
      local result = handle:read('*a')
      handle:close()
      return tonumber(result) or 96
    end
    return 96  -- Default DPI for Linux if not found
  end
end


local function compute_font_size(dpi)
    -- 169 dpi ⇒ 8 pt
    -- 69 dpi ⇒ 13 pt
    return math.floor(-.05 * dpi + 16.45 + .5)  -- +.5 to round
end

local function get_emoji_font()
    local is_macos = vim.fn.has('mac') == 1
    if is_macos then
        return 'Apple_Color_Emoji'
    else
        return 'Noto_Color_Emoji'
    end
end

local dpi = get_dpi()
local default_font_size = compute_font_size(dpi)

vim.g.gui_font_faces = {
    'Source_Code_Pro',
    get_emoji_font(),
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
