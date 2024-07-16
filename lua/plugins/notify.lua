return {
    { 'rcarriga/nvim-notify',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
            vim.notify = require'notify'

            local wk = require'which-key'
            wk.add{
                { '<leader>n', group = 'Notify' },
                { '<leader>nd', function() require'notify'.dismiss() end, desc = 'Dismiss all notifications' },
            }
        end,
    }
}
