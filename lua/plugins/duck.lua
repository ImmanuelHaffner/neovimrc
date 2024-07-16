return {
    { 'tamton-aquib/duck.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local duck = require'duck'
            local wk = require'which-key'
            duck.hatch()
            wk.add{
                { '<leader>d', group = 'Duck' },
                { '<leader>dd', function() duck.hatch() end, desc = 'Hatch duck' },
                { '<leader>dc', function() duck.cook() end, desc = 'Cook duck' },
            }
        end
    }
}
