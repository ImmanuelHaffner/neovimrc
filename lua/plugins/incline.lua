local Utils = require'utils'

local renderer = { }

function renderer.init()
    renderer.helpers = require'incline.helpers'
    renderer.devicons = require'nvim-web-devicons'
    renderer.colors = require'theme'.colors()
end

--- Returns a table with the icon's glyph, highlight group, foreground color, and background color.
--- @param filename string|nil
--- @param filetype string|nil
--- @return table
function renderer.get_icon(filename, filetype)
    local devicons = renderer.devicons
    local helpers = renderer.helpers

    -- Try getting by *filetype*.
    -- local ft_icon, ft_color = devicons.get_icon_color_by_filetype(filetype)
    -- -- If getting by *filetype* failed, try getting by *filename*.
    -- if ft_icon == nil then
    --     ft_icon, ft_color = devicons.get_icon_color(filename)
    -- end

    local glyph, color = devicons.get_icon_color(filename, filetype)
    if glyph == nil then
        return {}
    end
    local icon_name = devicons.get_icon_name_by_filetype(filetype)

    -- Try to find a DevIcon highlight group for the filetype
    if icon_name ~= nil and icon_name ~= '' then
        local hl_group = 'DevIcon' .. icon_name
        if vim.fn.hlexists(hl_group) == 1 then
            local syn_id = vim.fn.synIDtrans(vim.fn.hlID(hl_group))
            local bg = vim.fn.synIDattr(syn_id, 'bg')
            if bg ~= '' then
                local fg = vim.fn.synIDattr(syn_id, 'fg')
                return {
                    glyph = glyph,
                    hl = hl_group,
                    fg = fg,
                    bg = bg,
                }
            end
        end
    end

    return {
        glyph = glyph,
        bg = color,
        fg = helpers.contrast_color(color),
    }
end

function renderer.make_ft_icon(filename, filetype)
    local devicons = renderer.devicons

    local icon = renderer.get_icon(filename, filetype)
    if icon.glyph == nil then
        return {}
    end

    local icon_name = devicons.get_icon_name_by_filetype(filetype)
    if icon_name ~= nil and icon_name ~= '' then
        local hl_group = Utils.get_highlight_group('DevIcon' .. icon_name)
        if hl_group and hl_group.bg ~= '' then
            return { ' ', icon.glyph, ' ', guifg = hl_group.fg, guibg = hl_group.bg }
        end
    end
    return { ' ', icon.glyph, ' ', guibg = icon.bg, guifg = icon.fg }
end

function renderer.render(props)
    -- Make modules easily accessible
    local colors = renderer.colors

    -- Hide incline if the cursor is in the top column and the column is too wide.
    local wininfo = vim.fn.getwininfo(props.win)[1]
    local text_width = wininfo.width - wininfo.textoff

    local buftype = vim.api.nvim_get_option_value('buftype', { buf = props.buf })
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = props.buf })
    local file_path = vim.api.nvim_buf_get_name(props.buf)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')

    local function get_incline_width()
        local INCLINE_FIXED_WIDTH = 22
        return filename:len() + INCLINE_FIXED_WIDTH
    end

    local lines = vim.api.nvim_buf_get_lines(props.buf, wininfo.topline - 1, wininfo.topline, false)
    if lines and next(lines) then  -- has content
        if lines[1]:len() + get_incline_width() > text_width then  -- line too wide
            local _, linenum, colnum, _, _ = table.unpack(vim.fn.getcurpos(props.win))
            local num_lines_displayed = wininfo.botline - wininfo.topline + 1
            if linenum - wininfo.topline < num_lines_displayed / 3 then  -- cursor in upper third of win
                if colnum > wininfo.width / 2 then  -- cursor not in the front half
                    return ''
                end
            end
        end
    end

    -- Special handling of specific file and buffer types.
    if buftype == 'quickfix' then
        return {
            { '', guifg = colors.cyan2, guibg = colors.bg },
            { ' Quickfix list ', guibg = colors.cyan2, guifg = colors.dark, gui = 'bold' },
            guibg = colors.blue14,
        }
    elseif buftype == 'help' then
        local icon = renderer.get_icon('vim')
        return {
            { '', guifg = icon.bg, guibg = colors.bg },
            { ' ' .. icon.glyph .. ' HELP ', guibg = icon.bg, guifg = colors.dark, gui = 'bold' },
            { ' ', guifg = icon.bg, guibg = colors.blue14 },
            { filename, gui = 'bold,italic' },
            ' ',
            guibg = colors.blue14,
        }
    elseif buftype == 'terminal' then
        local toggle_term = string.match(file_path, [[;#toggleterm#(%d+)$]])

        if toggle_term then
            if string.find(file_path, 'lazygit;#toggleterm#') then
                local icon = renderer.get_icon('git')
                return {
                    { '', guifg = icon.bg, guibg = colors.bg },
                    { ' ' .. icon.glyph .. ' Lazygit ', guibg = icon.bg, guifg = colors.dark, gui = 'bold' },
                    -- { 'Lazygit', guibg = icon.guibg, guifg = colors.dark, gui = 'bold' },
                    { '', guifg = icon.bg, guibg = colors.bg },
                    { '─╮', guibg = colors.bg, guifg = colors.dark_white },
                    guibg = colors.blue14,
                }
            end

            local icon = renderer.get_icon('bash')
            return {
                { '', guifg = icon.bg, guibg = colors.bg },
                { ' ' .. icon.glyph .. ' ', guibg = icon.bg, guifg = icon.fg },
                { ('TERMINAL [%s] '):format(toggle_term), guibg = icon.bg, guifg = colors.dark, gui = 'bold' },
                guibg = colors.blue14,
            }
        end

        local icon = renderer.get_icon('bash')
        return {
            { '', guifg = icon.bg, guibg = colors.bg },
            { ' ' .. icon.glyph .. ' TERMINAL ', guibg = icon.bg, guifg = colors.dark, gui = 'bold' },
            guibg = colors.blue14,
        }
    elseif buftype == 'nofile' and filetype == 'noice' then
        return {
            { '', guifg = colors.light_red, guibg = colors.bg },
            { ' Noice ', guifg = colors.dark, guibg = colors.light_red, gui = 'bold' },
            guibg = colors.blue14,
        }
    end
    if filename == '' then
        return {
            { ' [No Name] ', guifg = colors.dark_white },
            guibg = colors.blue14,
        }
    end

    local function get_modified()
        local modified = vim.bo[props.buf].modified
        if modified then
            return ' ✎'
        end
        return ''
    end

    local function get_diagnostic_label()
        local icons = { error = '', warn = '', info = '', hint = '' }
        local labels = {}

        for severity, icon in pairs(icons) do
            local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[string.upper(severity)] })
            if n > 0 then
                table.insert(labels, { ' ' .. icon .. n, group = 'DiagnosticSign' .. severity })
            end
        end
        return labels
    end

    local function get_git_diff()
        local icons = {
            { name = 'added',   symbol = '+', fg = colors.sign_add, },  -- Green plus for added lines
            { name = 'changed', symbol = '~', fg = colors.sign_change, },  -- Yellow tilde for modified lines
            { name = 'removed', symbol = '-', fg = colors.sign_delete },  -- Red minus for deleted lines
        }

        local signs = vim.b[props.buf] and vim.b[props.buf].gitsigns_status_dict or nil
        local labels = {}

        if not signs then
            return labels
        end

        for _, config in ipairs(icons) do
            if tonumber(signs[config.name]) and signs[config.name] > 0 then
                table.insert(labels, {
                    ' ' .. config.symbol .. signs[config.name],
                    guifg = config.fg,
                })
            end
        end

        return labels
    end

    return {
        renderer.make_ft_icon(filename, filetype),
        { ' ', filename, gui = 'bold,italic' },
        get_modified(),
        get_diagnostic_label(),
        get_git_diff(),
        ' ',
        guibg = colors.blue14,
    }
end

return {
    { 'b0o/incline.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'lewis6991/gitsigns.nvim',
        },
        config = function()
            renderer.init()
            require('incline').setup{
                window = {
                    padding = 0,
                    margin = {
                        horizontal = 0,
                        vertical = 0,
                    },
                    zindex = 40,
                    overlap = {
                        borders = true,  -- overlap window borders
                    },
                },
                ignore = {
                    unlisted_buffers = false,  -- this includes `help`
                    wintypes = {},
                    filetypes = {},
                    buftypes = function(bufnr, buftype)
                        local buftypes_to_ignore = {
                            [''] = false,
                            ['help'] = false,
                            ['quickfix'] = false,
                            ['terminal'] = false,
                        }
                        if buftype == 'nofile' then
                            local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
                            if filetype == 'noice' then return false end
                        end
                        local ignore = buftypes_to_ignore[buftype]
                        return ignore == nil or ignore
                    end
                },
                render = renderer.render,
            }
        end,
    },
}
