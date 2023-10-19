return {
    { 'SmiteshP/nvim-navbuddy',
        dependencies = {
            'neovim/nvim-lspconfig',
            'SmiteshP/nvim-navic',
            'MunifTanjim/nui.nvim',
            'numToStr/Comment.nvim',        -- Optional
            'nvim-telescope/telescope.nvim', -- Optional
            'folke/which-key.nvim',
        },
        opts = { lsp = { auto_attach = true } },
        config = function(lazy, opts)
            vim.print('Setting up navbuddy...')
            require'nvim-navbuddy'.setup(opts)

            local wk = require'which-key'
            wk.register({
                name = 'LSP',
                n = { '<cmd>Navbuddy<cr>', 'Open Navbuddy' },
            }, { prefix = '<leader>l', silent = true })
        end
    }
}
