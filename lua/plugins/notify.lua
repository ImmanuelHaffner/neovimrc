return {
    { 'rcarriga/nvim-notify',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
            vim.notify = require'notify'

            local wk = require'which-key'
            wk.register({
                name = 'Notify',
                d = { function() require'notify'.dismiss() end, 'Dismiss all notifications' },
            }, { prefix = '<leader>n', silent = true })
        end,
    }
}
