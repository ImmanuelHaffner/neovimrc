return {
    {
        'atiladefreitas/dooing',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local wk = require'which-key'
            require'dooing'.setup{
                keymaps = {
                    toggle_window = false,
                },
            }
            wk.add{
                { '<leader>tn', ':Dooing<cr>', desc = 'Open Todo notes' },
            }
        end,
    }
}
