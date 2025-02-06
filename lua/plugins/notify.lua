return {
    { 'rcarriga/nvim-notify',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
            vim.notify = require'notify'
            require'which-key'.add{
                { '<leader>n', group = 'Notify' },
                { '<leader>nd', function()
                    require'notify'.dismiss{ pending=true, silent=true }
                end,
                desc = 'Dismiss all notifications' },
            }
        end,
    }
}
