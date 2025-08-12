return {
    { 'b0o/incline.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'lewis6991/gitsigns.nvim',
        },
        config = function()
            local helpers = require 'incline.helpers'
            local devicons = require 'nvim-web-devicons'
            local colors = require'theme'.colors()
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
                            ['quickfix'] = false,
                            ['help'] = false,
                        }
                        local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
                        local ignore = buftypes_to_ignore[buftype]
                        return ignore == nil or ignore
                    end
                },
                render = function(props)
                    -- Hide incline if the cursor is in the top column and the column is too wide.
                    local wininfo = vim.fn.getwininfo(props.win)[1]
                    local text_width = wininfo.width - wininfo.textoff

                    -- vim.print(('Render %s'):format(vim.inspect(props)))
                    local buftype = vim.api.nvim_get_option_value('buftype', { buf = props.buf })

                    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
                    if buftype == 'quickfix' then
                        filename = 'quickfix'
                    elseif buftype == 'help' then
                        filename = 'HELP: ' .. filename
                    end
                    if filename == '' then
                        filename = '[No Name]'
                    end

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

                    local function get_modified()
                        local modified = vim.bo[props.buf].modified
                        if modified then
                            return ' ✎'
                        end
                        return ''
                    end

                    local function get_ft_icon()
                        local ft_icon, ft_color = devicons.get_icon_color_by_filetype(vim.bo[props.buf].filetype)
                        local icon_name = devicons.get_icon_name_by_filetype(vim.bo[props.buf].filetype)
                        if ft_icon == nil then
                            ft_icon, ft_color = devicons.get_icon_color(filename)
                        end
                        if ft_icon == nil then
                            return {}
                        end
                        if icon_name ~= nil and icon_name ~= '' then
                            local hl_group = ('DevIcon%s'):format(icon_name)
                            if vim.fn.hlexists(hl_group) == 1 then
                                local syn_id = vim.fn.synIDtrans(vim.fn.hlID(hl_group))
                                local bg = vim.fn.synIDattr(syn_id, 'bg')
                                if bg ~= '' then
                                    local fg = vim.fn.synIDattr(syn_id, 'fg')
                                    return {
                                        { ' ', ft_icon, ' ', guifg = fg, guibg = bg },
                                    }
                                end
                            end
                        end
                        return {
                            { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) },
                        }
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
                        get_ft_icon(),
                        { ' ', filename, gui = 'bold,italic' },
                        get_modified(),
                        get_diagnostic_label(),
                        get_git_diff(),
                        ' ',
                        guibg = colors.blue14,
                    }
                end,
            }
        end,
    },
}
