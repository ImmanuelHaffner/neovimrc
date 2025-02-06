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
        config = function(_, opts)
            require'nvim-navbuddy'.setup(opts)

            local wk = require'which-key'
            wk.add{
                { '<leader>l', group = 'LSP' },
                { '<leader>ln', '<cmd>Navbuddy<cr>', desc = 'Open Navbuddy' },
            }
        end
    }
}
