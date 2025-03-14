return {
    { 'b0o/incline.nvim',
        dependencies = {
            'kyazdani42/nvim-web-devicons',
            'lewis6991/gitsigns.nvim',
        },
        config = function()
            local helpers = require 'incline.helpers'
            local devicons = require 'nvim-web-devicons'
            local colors = require'theme'.colors()
            require('incline').setup{
                window = {
                    padding = 0,
                    margin = { horizontal = 0 },
                    zindex = 50,
                },
                render = function(props)
                    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
                    if filename == '' then
                        filename = '[No Name]'
                    end

                    local function get_modified()
                        local modified = vim.bo[props.buf].modified
                        if modified then
                            return ' ✎'
                        end
                        return ''
                    end

                    local function get_ft_icon()
                        local ft_icon, ft_color = devicons.get_icon_color(filename)
                        if ft_icon == nil then
                            return {}
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
