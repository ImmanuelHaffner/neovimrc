return {
    {
        'ImmanuelHaffner/pigmentor.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local display_styles = {
                {
                    -- '#00AAFF'
                    style = 'inline',
                    inline = {
                        text_pre = '',
                        text_post = '',
                    },
                },
                {
                    -- '♦#00AAFF'
                    style = 'inline',
                    inline = {
                        text_pre = '♦',
                        text_post = '',
                    },
                },
                {
                    -- '#00AAFF' with fg text color
                    style = 'highlight',
                    highlight = {
                        padding = { left = 0, right = 0 },
                        inverted = false,
                    },
                },
                {
                    -- '#00AAFF' with bg color
                    style = 'highlight',
                    highlight = {
                        padding = { left = 1, right = 1 },
                        inverted = true,
                    },
                },
                {
                    -- '#00AAFF' with bg color
                    style = 'hybrid',
                    inline = {
                        text_pre = { '', '' },
                        text_post = { '', '', '' },
                    },
                    highlight = {
                        inverted = true,
                        padding = { left = 1, right = 1 },
                    },
                },
            }
            local current_display_style = 1

            local pm = require'pigmentor'
            pm.setup{
                display = display_styles[current_display_style],
            }

            local wk = require'which-key'
            wk.add({
                { '<leader>p', group = 'Pigmentor…' },
                { '<leader>pt', pm.toggle, desc = 'Toggle globally' },
                { '<leader>pc', function()
                    if current_display_style >= #display_styles then
                        current_display_style = 1
                    else
                        current_display_style = current_display_style + 1
                    end
                    pm.update_config{display = display_styles[current_display_style]}
                    pm.refresh_visible_buffers()
                end, desc = 'Cycle display style' },
            })
        end,
    },
}
