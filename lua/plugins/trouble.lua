return {
    { 'folke/trouble.nvim',
        dependencies = {
            'kyazdani42/nvim-web-devicons',
            'nvim-telescope/telescope.nvim',
            'folke/which-key.nvim',
        },
        setup = function()
            require'trouble'.setup()
            require'which-key'.register({
                name = 'Telescope',
                t = { '<cmd>TodoTelescope<cr>', 'Find todo notes' },
            }, { prefix = '<leader>f', silent = true })
        end,
    },
}
