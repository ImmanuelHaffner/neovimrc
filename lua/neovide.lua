--- Parse Neovide's config.toml to extract font faces and size.
--- @return string[]|nil faces, number|nil size
local function parse_neovide_config()
    local config_path = vim.fn.expand('~/.config/neovide/config.toml')
    local file = io.open(config_path, 'r')
    if not file then
        return nil, nil
    end

    local content = file:read('*a')
    file:close()

    -- Extract font size: `size = 18.0` or `size = 18`
    local size_str = content:match('%[font%].-size%s*=%s*([%d%.]+)')
    local size = size_str and math.floor(tonumber(size_str) or 0) or nil

    -- Extract font faces: `normal = ['Font One', 'Font Two']`
    local fonts_str = content:match('%[font%].-normal%s*=%s*%[([^%]]+)%]')
    local faces = nil
    if fonts_str then
        faces = {}
        -- Match quoted strings (single or double quotes)
        for face in fonts_str:gmatch("['\"]([^'\"]+)['\"]") do
            -- Convert spaces to underscores for guifont format
            table.insert(faces, (face:gsub(' ', '_')))
        end
        if #faces == 0 then
            faces = nil
        end
    end

    return faces, size
end

-- Parse Neovide config.toml for font settings
local config_faces, config_size = parse_neovide_config()

-- Fallbacks if config.toml is missing or incomplete
local default_font_faces = config_faces or { 'Source_Code_Pro' }
local default_font_size = config_size or 12

vim.g.gui_font_faces = default_font_faces
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
    M.refresh_gui_font()
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
