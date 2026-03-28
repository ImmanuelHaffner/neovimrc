return {
    { 'folke/trouble.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'nvim-telescope/telescope.nvim',
            'folke/which-key.nvim',
        },
        -- Lazy-load: only needed when explicitly opened; avoids BufEnter overhead.
        cmd = { 'Trouble', 'TroubleToggle' },
        keys = {
            { '<F9>', '<cmd>Trouble<cr>', desc = 'Open Trouble' },
        },
        config = function()
            require'trouble'.setup()
        end
    },
}
