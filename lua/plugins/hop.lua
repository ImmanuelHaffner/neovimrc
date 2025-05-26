return {
    { 'smoka7/hop.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        version = "*",
        config = function()
            require'hop'.setup{
                -- For Colemak Mod-DH
                keys = 'tnfuwyaoseri',
            }
            require'which-key'.add{
                { '<C-Space>', '<cmd>HopWord<cr>', desc = 'Hop' },
            }
        end,
    }
}
