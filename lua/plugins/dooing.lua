return {
    {
        'atiladefreitas/dooing',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            require'dooing'.setup{
                keymaps = {
                    toggle_window = false,
                },
            }

            require'which-key'.add{
                { '<leader>tn', ':Dooing<cr>', desc = 'Open Todo notes' },
            }
        end,
    }
}
