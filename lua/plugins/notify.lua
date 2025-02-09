return {
    { 'rcarriga/nvim-notify',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
            local notify = require'notify'
            vim.notify = notify
            notify.setup{
                on_open = function(win)
                    local buf = vim.api.nvim_win_get_buf(win)
                    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
                end,
            }
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
