return {
    { 'tamton-aquib/duck.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local duck = require'duck'
            local wk = require'which-key'
            duck.hatch()
            wk.register({
                name = 'Duck',
                d = { function() duck.hatch() end, 'Hatch duck' },
                c = { function() duck.cook() end, 'Cook duck' },
            }, { prefix = '<leader>d', silent = true })
        end
    }
}
