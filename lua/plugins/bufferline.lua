local function get_desired_name_length()
    local num_tabs  = #vim.api.nvim_list_tabpages()
    local avg_length = math.floor(vim.o.columns / num_tabs)
    return avg_length
end

return {
    { 'akinsho/bufferline.nvim',
        tag = 'v4.9.1',
        config = function()
            local Utils = require'utils'

            require'bufferline'.setup{
                options = {
                    mode = 'tabs',
                    right_mouse_command = nil,
                    -- tab_size = 60,
                    max_name_length = 999,
                    truncate_names = false,
                    max_prefix_length = 0,
                    name_formatter = function(buf)
                        local min_length = math.max(get_desired_name_length(), 60)
                        return Utils.shorten_relative_path(buf.path, min_length)
                    end,
                    -- diagnostics = 'nvim_lsp',
                    -- diagnostics_indicator = function(count, level, diagnostics_dict, context)
                    --     local s = ' '
                    --     for e, n in pairs(diagnostics_dict) do
                    --         local sym = e == 'error' and ' ' or (e == 'warning' and ' ' or '' )
                    --         s = s .. n .. sym
                    --     end
                    --     return s
                    -- end,
                    close_icon = '',
                    buffer_close_icon = '',
                    separator_style = 'slant',
                    -- indicator = {
                    --     style = 'underline',
                    -- },
                    sort_by = 'tabs',
                    offsets = {
                        {
                            filetype = 'neo-tree',
                            text = function()
                                local min_length = math.max(get_desired_name_length(), 30)
                                return Utils.shorten_relative_path(vim.fn.getcwd(), min_length)
                            end,
                            highlight = 'Directory',
                            text_align = 'left',
                        }
                    }
                }
            }

            local function hl(name, val)
                val.force = true
                vim.api.nvim_set_hl(0, 'BufferLine' .. name, val)
            end

            hl('TabSeparator', { bg = '#000000' })
            hl('Fill', { bg = '#000000' })
        end
    },
}
