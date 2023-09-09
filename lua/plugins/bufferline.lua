return {
    { 'akinsho/bufferline.nvim',
        tag = 'v4.3.0',
        dependencies = { 'folke/which-key.nvim' },
        config = function()
            local Utils = require'utils'

            require'bufferline'.setup{
                options = {
                    mode = 'tabs',
                    right_mouse_command = nil,
                    tab_size = 32,
                    max_name_length = 32,
                    max_prefix_length = 0,
                    name_formatter = function(buf)
                        return Utils.shorten_relative_path(buf.path, 32)
                    end,
                    diagnostics = 'nvim_lsp',
                    diagnostics_indicator = function(count, level, diagnostics_dict, context)
                        local s = ' '
                        for e, n in pairs(diagnostics_dict) do
                            local sym = e == 'error' and ' ' or (e == 'warning' and ' ' or '' )
                            s = s .. n .. sym
                        end
                        return s
                    end,
                    close_icon = '',
                    buffer_close_icon = '',
                    sort_by = 'tabs',
                    offsets = {
                        {
                            filetype = 'NvimTree',
                            text = function()
                                return Utils.shorten_relative_path(vim.fn.getcwd(), 20)
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
