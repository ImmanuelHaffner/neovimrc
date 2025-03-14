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
                    vim.wo.spell=false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
                -- function to run on closing the terminal
                on_close = function(term)
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
                    vim.wo.spell=false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
            }

            local float_term = Terminal:new{
                direction = 'float',
                float_opts = {
                    border = 'double',
                },
                on_open = function(term)
                    vim.wo.spell=false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-q>", "<cmd>close<CR>", {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
            }

            local ipython = Terminal:new{
                cmd = 'ipython',
                direction = 'vertical',
                on_open = function(term)
                    local winid = vim.api.nvim_get_current_win()
                    vim.api.nvim_win_set_width(winid, 80)
                    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-q>", "<cmd>close<CR>", {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
            }

            require'which-key'.add{
                { '<leader>gl', function() lazygit:toggle() end, desc = 'Lazygit' },
                { '<leader>ft', '<cmd>TermSelect<cr>', desc = 'Select toggle term' },

                { '<leader>r', group = 'Run command…' },
                { '<leader>rr', function() ranger:toggle() end, desc = 'File Ranger' },
                { '<leader>rt', function() float_term:toggle() end, desc = 'Floating Terminal' },
                { '<leader>rp', function() ipython:toggle() end, desc = 'IPython Interpreter' },
            }
        end,
    },
}
