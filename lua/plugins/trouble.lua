return {
    { 'folke/trouble.nvim',
        dependencies = {
            'kyazdani42/nvim-web-devicons',
            'nvim-telescope/telescope.nvim',
            'folke/which-key.nvim',
        },
        config = function()
            require'trouble'.setup()
            local wk = require'which-key'
            wk.register({
                ['<F9>'] = { '<cmd>Trouble<cr>', 'Open Trouble' },
            }, { silent = true })
        end
    },
}
