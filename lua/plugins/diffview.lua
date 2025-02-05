return {
    { 'sindrets/diffview.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            -- vim.opt.fillchars:append{ diff = '␥' }  -- alternatives: ␥╱
            require'which-key'.add{
                { '<leader>gd', group = 'Git Diffview …' },
                { '<leader>gdv', '<cmd>DiffviewOpen -uno<cr>', desc = 'Open Diffview' },
                { '<leader>gdh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history' },
            }
        end,
    }
}
