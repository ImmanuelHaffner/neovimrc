return {
    { 'rcarriga/nvim-notify',
        config = function()
            vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
            vim.notify = require'notify'
        end,
        keys = {
            { '<leader>n', group = 'Notify' },
            { '<leader>nd', function() require'notify'.dismiss() end, desc = 'Dismiss all notifications' },
        }
    }
}
