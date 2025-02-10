return {
    { 'akinsho/bufferline.nvim',
        tag = 'v4.7.0',
        config = function()
            local Utils = require'utils'

            require'bufferline'.setup{
                options = {
                    mode = 'tabs',
                    right_mouse_command = nil,
                    tab_size = 60,
                    max_name_length = 58,
                    max_prefix_length = 0,
                    name_formatter = function(buf)
                        return Utils.shorten_relative_path(buf.path, 58)
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
                    sort_by = 'tabs',
                    offsets = {
                        {
                            filetype = 'neo-tree',
                            text = function()
                                return Utils.shorten_relative_path(vim.fn.getcwd(), 30)
                            end,
                            highlight = 'Directory',
                            text_align = 'left',
                        }
                    }
                }
            }
        end
    },
}
