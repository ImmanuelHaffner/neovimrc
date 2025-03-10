return {
    { 'akinsho/toggleterm.nvim',
        version = "*",
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local term = require'toggleterm'
            term.setup{
                open_mapping = [[<c-\>]],
                shade_terminals = false,
                autochdir = true,
                auto_scroll = false,
            }

            local Terminal = require'toggleterm.terminal'.Terminal

            local lazygit = Terminal:new{
                cmd = 'env GPG_TTY=$(tty) SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" lazygit',
                dir = 'git_dir',
                direction = 'tab',
                -- function to run on opening the terminal
                on_open = function(term)
                    vim.cmd[[startinsert!]]
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                -- function to run on closing the terminal
                on_close = function(term)
                    vim.cmd[[startinsert!]]
                    vim.cmd[[tabprevious]]  -- return to previous tab
                end,
            }

            local ranger = Terminal:new{
                cmd = 'ranger',
                direction = 'float',
                float_opts = {
                    border = 'double',
                },
                -- function to run on opening the terminal
                on_open = function(term)
                    vim.cmd[[startinsert!]]
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                -- function to run on closing the terminal
                on_close = function(term)
                    vim.cmd[[startinsert!]]
                end,
            }

            local float_term = Terminal:new{
                direction = 'float',
                float_opts = {
                    border = 'double',
                },
            }

            require'which-key'.add{
                { '<leader>gl', function() lazygit:toggle() end, desc = 'Lazygit' },
                { '<leader>ft', '<cmd>TermSelect<cr>', desc = 'Select toggle term' },

                { '<leader>r', group = 'Run command…' },
                { '<leader>rr', function() ranger:toggle() end, desc = 'File Ranger' },
                { '<leader>rt', function() float_term:toggle() end, desc = 'Floating Terminal' },
            }
        end,
    },
}
