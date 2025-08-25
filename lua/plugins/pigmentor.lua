return {
    {
        'ImmanuelHaffner/pigmentor.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local pm = require'pigmentor'
            pm.setup{
                display = {
                    style = 'inline',               -- one of inline, highlight
                    inactive = true,
                    inline = {
                        -- text_pre = { '', },
                        text_post = { '', },
                        -- text_post = { '', '', '', },
                    },
                    highlight = {
                        padding = {
                            left = 1,
                            right = 1,
                        },
                    },
                },
            }
            local wk = require'which-key'
            wk.add({
                { '<leader>p', group = 'Pigmentor…' },
                { '<leader>pt', pm.toggle, desc = 'Toggle globally' },
                { '<leader>pc', pm.cycle_display_style, desc = 'Cycle display style' },
            })
        end,
    },
}
